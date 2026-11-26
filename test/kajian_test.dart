import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawahku/core/preferences/app_preferences.dart';
import 'package:tilawahku/features/kajian/data/kajian_audio_playback.dart';
import 'package:tilawahku/features/kajian/data/kajian_cache_store.dart';
import 'package:tilawahku/features/kajian/data/kajian_feed_client.dart';
import 'package:tilawahku/features/kajian/data/kajian_repository.dart';
import 'package:tilawahku/features/kajian/domain/kajian_models.dart';
import 'package:tilawahku/features/kajian/domain/kajian_rss_parser.dart';
import 'package:tilawahku/features/kajian/presentation/kajian_list_screen.dart';
import 'package:tilawahku/features/memorization/data/memorization_repository.dart';
import 'package:tilawahku/features/memorization/domain/memorization_models.dart';
import 'package:tilawahku/features/navigation/presentation/main_navigation_screen.dart';
import 'package:tilawahku/features/reading/data/reading_repository.dart';
import 'package:tilawahku/features/tajwid/data/tajwid_repository.dart';

const _sampleRssXml = '''
<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0" xmlns:itunes="http://www.itunes.com/dtds/podcast-1.0.dtd">
  <channel>
    <title>Kajian Ilmu Nusantara</title>
    <link>https://contoh-kajian.id</link>
    <itunes:author>Tim Kajian Nusantara</itunes:author>
    <copyright>Hak cipta penerbit resmi, distribusi RSS publik.</copyright>
    <item>
      <guid>ep-001</guid>
      <title><![CDATA[Tadabbur Surah Al-Fatihah &amp; Makna Hidayah]]></title>
      <itunes:author>Ustadz Ahmad Fauzi</itunes:author>
      <itunes:duration>42:15</itunes:duration>
      <pubDate>Wed, 25 Nov 2026 07:00:00 +0700</pubDate>
      <category>Tafsir Al-Qur'an</category>
      <description><![CDATA[<p>Penjelasan ringkas <b>Surah Al-Fatihah</b> dan pelajaran iman.</p>]]></description>
      <link>https://contoh-kajian.id/ep-001</link>
      <enclosure url="https://contoh-kajian.id/audio/ep-001.mp3" type="audio/mpeg" length="123456" />
    </item>
    <item>
      <guid>ep-002</guid>
      <title>Adab Menuntut Ilmu dalam Kehidupan Sehari-hari</title>
      <itunes:author>Ustadzah Siti Rahmah</itunes:author>
      <itunes:duration>01:05:30</itunes:duration>
      <category>Akhlak</category>
      <itunes:summary>Membahas keikhlasan, sabar, dan adab terhadap guru.</itunes:summary>
      <enclosure url="https://contoh-kajian.id/audio/ep-002.m4a" type="audio/mp4" length="234567" />
    </item>
    <item>
      <guid>ep-no-audio</guid>
      <title>Pengumuman Jadwal Tanpa Audio</title>
      <description>Item tanpa enclosure audio harus dilewati.</description>
    </item>
  </channel>
</rss>
''';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Kajian RSS parser & domain models', () {
    test('parses valid RSS 2.0 podcast feed, cleans CDATA/HTML, and skips non-audio items', () {
      final parsed = parseKajianRssFeed(
        xml: _sampleRssXml,
        feedUrl: 'https://contoh-kajian.id/feed.xml',
        addedAt: DateTime.utc(2026, 11, 25),
      );

      expect(parsed.source.title, 'Kajian Ilmu Nusantara');
      expect(parsed.source.author, 'Tim Kajian Nusantara');
      expect(parsed.source.websiteUrl, 'https://contoh-kajian.id');
      expect(parsed.source.licenseNote, contains('Hak cipta penerbit resmi'));
      expect(parsed.items, hasLength(2));

      final first = parsed.items[0];
      expect(first.title, 'Tadabbur Surah Al-Fatihah & Makna Hidayah');
      expect(first.speaker, 'Ustadz Ahmad Fauzi');
      expect(first.category, KajianCategory.alquran);
      expect(first.durationSeconds, 42 * 60 + 15);
      expect(first.formattedDuration, '42:15');
      expect(first.description, 'Penjelasan ringkas Surah Al-Fatihah dan pelajaran iman.');
      expect(first.audioUrl, 'https://contoh-kajian.id/audio/ep-001.mp3');

      final second = parsed.items[1];
      expect(second.category, KajianCategory.akhlak);
      expect(second.durationSeconds, 3600 + 5 * 60 + 30);
      expect(second.formattedDuration, '01:05:30');
    });

    test('rejects invalid URLs and XML without audio enclosures', () {
      expect(
        () => parseKajianRssFeed(xml: _sampleRssXml, feedUrl: 'ftp://invalid.example/feed'),
        throwsFormatException,
      );
      expect(
        () => parseKajianRssFeed(
          xml: '<rss><channel><title>Kosong</title></channel></rss>',
          feedUrl: 'https://contoh-kajian.id/empty.xml',
        ),
        throwsFormatException,
      );
    });

    test('filters items by query, category, speaker, and favorites', () {
      final parsed = parseKajianRssFeed(
        xml: _sampleRssXml,
        feedUrl: 'https://contoh-kajian.id/feed.xml',
      );
      expect(
        filterKajianItems(items: parsed.items, query: 'fatihah'),
        hasLength(1),
      );
      expect(
        filterKajianItems(items: parsed.items, category: KajianCategory.akhlak),
        hasLength(1),
      );
      expect(
        filterKajianItems(
          items: parsed.items,
          speaker: 'Ustadzah Siti Rahmah',
        ),
        hasLength(1),
      );
      expect(
        filterKajianItems(
          items: parsed.items,
          favoritesOnly: true,
          favoriteIds: {parsed.items.first.id},
        ),
        hasLength(1),
      );
    });
  });

  group('KajianRepository cache, offline fallback, favorites, and history', () {
    test('adds source, serves fresh cache, falls back to stale cache offline, and removes source', () async {
      SharedPreferences.setMockInitialValues({});
      var now = DateTime.utc(2026, 11, 25, 8);
      final cacheStore = _InMemoryKajianCacheStore();
      final client = _FakeKajianFeedClient({
        'https://contoh-kajian.id/feed.xml': _sampleRssXml,
      });
      final repo = KajianRepository(
        preferences: const AppPreferences(),
        cacheStore: cacheStore,
        feedClient: client,
        clock: () => now,
        defaultSources: const [],
      );

      final parsed = await repo.addSource('https://contoh-kajian.id/feed.xml');
      expect(parsed.items, hasLength(2));
      expect(client.requestCount, 1);

      // Fresh cache hit does not hit network
      final cachedSnapshot = await repo.loadCatalog();
      expect(cachedSnapshot.fromCache, isTrue);
      expect(cachedSnapshot.items, hasLength(2));
      expect(cachedSnapshot.warnings, isEmpty);
      expect(client.requestCount, 1);

      // Advance past TTL and simulate offline failure -> falls back honestly to cache
      now = now.add(const Duration(hours: 8));
      client.shouldFail = true;
      final offlineSnapshot = await repo.loadCatalog();
      expect(offlineSnapshot.fromCache, isTrue);
      expect(offlineSnapshot.items, hasLength(2));
      expect(offlineSnapshot.warnings, hasLength(1));
      expect(offlineSnapshot.warnings.first, contains('gagal memperbarui'));

      // Favorites & playback history
      final favs = await repo.toggleFavorite(parsed.items.first.id);
      expect(favs, contains(parsed.items.first.id));

      final history = await repo.recordPlayback(
        KajianPlaybackRecord(
          itemId: parsed.items.first.id,
          positionMs: 120000,
          durationMs: 600000,
          playedAt: now.toIso8601String(),
        ),
      );
      expect(history, hasLength(1));
      expect(history.first.progressFraction, closeTo(0.2, 0.001));

      // Disable source hides episodes cleanly (takedown/disable support)
      await repo.setSourceEnabled('https://contoh-kajian.id/feed.xml', false);
      final disabledSnapshot = await repo.loadCatalog();
      expect(disabledSnapshot.items, isEmpty);
      expect(disabledSnapshot.warnings.first, contains('dinonaktifkan'));

      // Remove source clears cache
      await repo.removeSource('https://contoh-kajian.id/feed.xml');
      expect(await repo.loadSources(), isEmpty);
      expect(await cacheStore.getFeed('https://contoh-kajian.id/feed.xml'), isNull);
    });
  });

  group('Kajian UI & navigation from Lainnya tab', () {
    testWidgets('loads built-in default kajian catalog immediately without manual RSS setup', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final cacheStore = _InMemoryKajianCacheStore();
      final defaultFeedUrl = defaultKajianSources.first.feedUrl;
      final client = _FakeKajianFeedClient({
        defaultFeedUrl: _sampleRssXml,
      });
      final repo = KajianRepository(
        preferences: const AppPreferences(),
        cacheStore: cacheStore,
        feedClient: client,
        defaultSources: [defaultKajianSources.first],
      );
      var murottalPaused = false;
      final playback = _FakeKajianAudioPlayback(
        onBeforePlay: () async => murottalPaused = true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: KajianListScreen(repository: repo, playback: playback),
        ),
      );
      await tester.pumpAndSettle();

      // Episodes appear right away without any RSS onboarding or source menu
      expect(find.byTooltip('Kelola sumber kajian'), findsNothing);
      expect(find.text('Sumber kajian'), findsNothing);
      expect(find.text('Tadabbur Surah Al-Fatihah & Makna Hidayah'), findsOneWidget);
      expect(find.text('Adab Menuntut Ilmu dalam Kehidupan Sehari-hari'), findsOneWidget);

      // Open detail screen & control playback
      await tester.tap(find.text('Tadabbur Surah Al-Fatihah & Makna Hidayah'));
      await tester.pumpAndSettle();

      expect(find.text('Pemutar audio kajian'), findsOneWidget);
      await tester.tap(find.text('Putar'));
      await tester.pumpAndSettle();

      expect(murottalPaused, isTrue);
      expect(find.text('Jeda'), findsOneWidget);

      // Forward +15s & speed change
      await tester.tap(find.byTooltip('Maju 15 detik'));
      await tester.pumpAndSettle();
      expect(playback.currentState.position, const Duration(seconds: 15));

      await tester.tap(find.text('1.5x'));
      await tester.pumpAndSettle();
      expect(playback.currentState.speed, 1.5);

      // Verify attribution & license section
      await tester.scrollUntilVisible(find.text('Sumber dan lisensi'), 200);
      expect(find.text('Sumber dan lisensi'), findsOneWidget);
      expect(find.text('Kajian Ilmu Nusantara'), findsWidgets);

      await playback.dispose();
    });

    testWidgets('opens Kajian dan ceramah from Lainnya tab and handles offline first open cleanly', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final readingRepo = _FakeReadingRepository();
      final offlineClient = _FakeKajianFeedClient(const {})..shouldFail = true;
      final kajianRepo = KajianRepository(
        preferences: const AppPreferences(),
        cacheStore: _InMemoryKajianCacheStore(),
        feedClient: offlineClient,
      );
      final playback = _FakeKajianAudioPlayback();

      await tester.pumpWidget(
        MaterialApp(
          home: MainNavigationScreen(
            preferences: const AppPreferences(),
            onSetDarkMode: (_) {},
            readingRepository: readingRepo,
            memorizationRepository: MemorizationRepository(
              store: _EmptyMemorizationStore(),
              readingRepository: readingRepo,
            ),
            tajwidRepository: TajwidRepository(),
            kajianRepository: kajianRepo,
            kajianPlayback: playback,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Lainnya').last);
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Kajian dan ceramah'),
        200,
        scrollable: find.descendant(
          of: find.byKey(const ValueKey('more-options-list')),
          matching: find.byType(Scrollable),
        ),
      );
      expect(find.text('Belum tersedia'), findsNothing);

      await tester.tap(find.text('Kajian dan ceramah'));
      await tester.pumpAndSettle();

      expect(
        find.text('Katalog kajian memerlukan koneksi internet'),
        findsOneWidget,
      );
      expect(find.text('Muat ulang'), findsOneWidget);
      await playback.dispose();
    });
  });
}

class _InMemoryKajianCacheStore implements KajianCacheStore {
  final Map<String, CachedKajianFeed> _store = {};

  @override
  Future<void> deleteFeed(String feedUrl) async {
    _store.remove(feedUrl);
  }

  @override
  Future<CachedKajianFeed?> getFeed(String feedUrl) async => _store[feedUrl];

  @override
  Future<void> saveFeed(CachedKajianFeed feed) async {
    _store[feed.feedUrl] = feed;
  }
}

class _FakeKajianFeedClient implements KajianFeedClient {
  _FakeKajianFeedClient(this._responses);

  final Map<String, String> _responses;
  bool shouldFail = false;
  int requestCount = 0;

  @override
  Future<String> fetchXml(String feedUrl) async {
    requestCount += 1;
    if (shouldFail) {
      throw const KajianNetworkException('Offline');
    }
    final xml = _responses[feedUrl];
    if (xml == null) {
      throw const KajianNetworkException('Feed tidak ditemukan');
    }
    return xml;
  }
}

class _FakeKajianAudioPlayback implements KajianAudioPlayback {
  _FakeKajianAudioPlayback({this.onBeforePlay});

  final Future<void> Function()? onBeforePlay;
  final StreamController<KajianPlaybackState> _controller =
      StreamController<KajianPlaybackState>.broadcast();
  KajianPlaybackState _state = const KajianPlaybackState();

  @override
  KajianPlaybackState get currentState => _state;

  @override
  Stream<KajianPlaybackState> get stateStream => _controller.stream;

  void _emit(KajianPlaybackState next) {
    _state = next;
    if (!_controller.isClosed) _controller.add(next);
  }

  @override
  Future<void> playItem(
    KajianItem item, {
    Duration initialPosition = Duration.zero,
  }) async {
    await onBeforePlay?.call();
    _emit(
      _state.copyWith(
        item: item,
        isPlaying: true,
        isBuffering: false,
        position: initialPosition,
        duration: Duration(seconds: item.durationSeconds ?? 600),
        clearError: true,
      ),
    );
  }

  @override
  Future<void> pause() async {
    _emit(_state.copyWith(isPlaying: false));
  }

  @override
  Future<void> resume() async {
    await onBeforePlay?.call();
    _emit(_state.copyWith(isPlaying: true));
  }

  @override
  Future<void> stop() async {
    _emit(const KajianPlaybackState());
  }

  @override
  Future<void> seek(Duration position) async {
    final maxDuration = _state.duration;
    var clamped = position < Duration.zero ? Duration.zero : position;
    if (maxDuration > Duration.zero && clamped > maxDuration) {
      clamped = maxDuration;
    }
    _emit(_state.copyWith(position: clamped));
  }

  @override
  Future<void> seekRelative(Duration offset) => seek(_state.position + offset);

  @override
  Future<void> setSpeed(double speed) async {
    _emit(_state.copyWith(speed: speed));
  }

  @override
  Future<void> dispose() => _controller.close();
}

class _FakeReadingRepository extends ReadingRepository {
  @override
  Future<List<Surah>> getSurahs() async => const [];

  @override
  Future<AyahEntry?> getProgress(String voiceId) async => null;
}

class _EmptyMemorizationStore implements MemorizationStore {
  @override
  Future<List<MemorizationProgram>> getPrograms() async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
