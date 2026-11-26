import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawahku/core/preferences/app_preferences.dart';
import 'package:tilawahku/features/memorization/data/memorization_repository.dart';
import 'package:tilawahku/features/memorization/domain/memorization_models.dart';
import 'package:tilawahku/features/navigation/presentation/main_navigation_screen.dart';
import 'package:tilawahku/features/quotes_stories/data/quotes_stories_repository.dart';
import 'package:tilawahku/features/quotes_stories/domain/quotes_stories_models.dart';
import 'package:tilawahku/features/quotes_stories/presentation/quotes_stories_controller.dart';
import 'package:tilawahku/features/quotes_stories/presentation/quotes_stories_screen.dart';
import 'package:tilawahku/features/reading/data/reading_repository.dart';
import 'package:tilawahku/features/tajwid/data/tajwid_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Bundled quotes.json & stories.json validation', () {
    test('quotes.json has _meta, unique ids, and explicit source_ref', () {
      final file = File(QuotesStoriesRepository.quotesAssetPath);
      expect(file.existsSync(), isTrue);
      final raw = file.readAsStringSync();
      expect(raw, isNot(contains('—')));

      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      expect((decoded['_meta'] as Map<String, dynamic>)['source'], isNotEmpty);

      final items = (decoded['items'] as List<dynamic>)
          .map((e) => IslamicQuote.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
      expect(items.length, greaterThanOrEqualTo(12));
      expect(items.map((e) => e.id).toSet().length, items.length);

      for (final quote in items) {
        expect(quote.textId.trim(), isNotEmpty);
        expect(quote.author.trim(), isNotEmpty);
        expect(quote.sourceRef.trim(), isNotEmpty);
        expect(quote.category.trim(), isNotEmpty);
      }
    });

    test('stories.json has _meta, unique ids, paragraphs, lessons, and refs', () {
      final file = File(QuotesStoriesRepository.storiesAssetPath);
      expect(file.existsSync(), isTrue);
      final raw = file.readAsStringSync();
      expect(raw, isNot(contains('—')));

      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      expect((decoded['_meta'] as Map<String, dynamic>)['source'], isNotEmpty);

      final items = (decoded['items'] as List<dynamic>)
          .map((e) => IslamicStory.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
      expect(items.length, greaterThanOrEqualTo(6));
      expect(items.map((e) => e.id).toSet().length, items.length);

      for (final story in items) {
        expect(story.title.trim(), isNotEmpty);
        expect(story.readMinutes, greaterThan(0));
        expect(story.summary.trim(), isNotEmpty);
        expect(story.paragraphs, isNotEmpty);
        expect(story.lessons, isNotEmpty);
        expect(story.sourceRef.trim(), isNotEmpty);
      }
    });
  });

  group('Domain filtering and deterministic daily quote', () {
    const quotes = [
      IslamicQuote(
        id: 'q1',
        category: "Al-Qur'an",
        textAr: 'خَيْرُكُمْ مَنْ تَعَلَّمَ الْقُرْآنَ وَعَلَّمَهُ',
        textId: 'Sebaik-baik kalian belajar dan mengajarkan Al-Qur\'an.',
        author: 'Nabi Muhammad SAW',
        sourceRef: 'HR. Bukhari no. 5027',
      ),
      IslamicQuote(
        id: 'q2',
        category: 'Sabar',
        textId: 'Tidak ada pemberian lebih luas daripada kesabaran.',
        author: 'Nabi Muhammad SAW',
        sourceRef: 'HR. Bukhari no. 1469',
      ),
    ];

    test('quoteOfTheDay is deterministic for the same calendar date', () {
      final morning = quoteOfTheDay(quotes, DateTime(2026, 11, 25, 6, 0));
      final night = quoteOfTheDay(quotes, DateTime(2026, 11, 25, 23, 30));
      expect(morning?.id, night?.id);
    });

    test('filterQuotes filters by category, query, and favorites', () {
      expect(
        filterQuotes(
          quotes,
          query: '',
          category: 'Sabar',
          favoritesOnly: false,
          favorites: const {},
        ).map((e) => e.id),
        ['q2'],
      );
      expect(
        filterQuotes(
          quotes,
          query: '5027',
          category: null,
          favoritesOnly: false,
          favorites: const {},
        ).map((e) => e.id),
        ['q1'],
      );
      expect(
        filterQuotes(
          quotes,
          query: '',
          category: null,
          favoritesOnly: true,
          favorites: const {'q2'},
        ).map((e) => e.id),
        ['q2'],
      );
    });
  });

  group('QuotesStoriesScreen widget & navigation', () {
    testWidgets('switches tabs, toggles favorites, and opens StoryDetailScreen', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final controller = QuotesStoriesController(
        repository: _InMemoryQuotesStoriesRepository(),
        clock: () => DateTime(2026, 11, 25),
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: QuotesStoriesScreen(
            preferences: const AppPreferences(),
            controller: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Quotes tab shows daily card and quote list
      expect(find.textContaining('Kutipan hari ini'), findsOneWidget);
      expect(find.text('HR. Bukhari no. 5027'), findsOneWidget);

      // Switch to Kisah tab
      await tester.tap(find.text('Kisah'));
      await tester.pumpAndSettle();
      expect(find.text('Pemuda Ashabul Kahfi'), findsOneWidget);

      // Open story detail screen
      await tester.tap(find.text('Pemuda Ashabul Kahfi'));
      await tester.pumpAndSettle();
      expect(find.byType(StoryDetailScreen), findsOneWidget);
      expect(find.text('Pelajaran (Ibrah)'), findsOneWidget);
      expect(find.text('QS. Al-Kahfi (18): 9-26'), findsOneWidget);

      // Toggle favorite inside story detail
      await tester.tap(find.byTooltip('Simpan favorit'));
      await tester.pumpAndSettle();
      expect(controller.isStoryFavorite('s1'), isTrue);
    });

    testWidgets('Lainnya tab opens QuotesStoriesScreen', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final readingRepository = _FakeReadingRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: MainNavigationScreen(
            preferences: const AppPreferences(),
            onSetDarkMode: (_) {},
            readingRepository: readingRepository,
            memorizationRepository: MemorizationRepository(
              store: _EmptyMemorizationStore(),
              readingRepository: readingRepository,
            ),
            tajwidRepository: TajwidRepository(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Lainnya').last);
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Quotes dan kisah Islam'),
        200,
        scrollable: find.descendant(
          of: find.byKey(const ValueKey('more-options-list')),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.ensureVisible(find.text('Quotes dan kisah Islam'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Quotes dan kisah Islam'));
      await tester.pumpAndSettle();
      expect(find.byType(QuotesStoriesScreen), findsOneWidget);
    });
  });
}

class _InMemoryQuotesStoriesRepository extends QuotesStoriesRepository {
  Set<String> _quoteFavs = <String>{};
  Set<String> _storyFavs = <String>{};

  @override
  Future<List<IslamicQuote>> loadQuotes() async => const [
    IslamicQuote(
      id: 'q1',
      category: "Al-Qur'an",
      textAr: 'خَيْرُكُمْ مَنْ تَعَلَّمَ الْقُرْآنَ وَعَلَّمَهُ',
      textId: 'Sebaik-baik kalian belajar dan mengajarkan Al-Qur\'an.',
      author: 'Nabi Muhammad SAW',
      sourceRef: 'HR. Bukhari no. 5027',
    ),
  ];

  @override
  Future<List<IslamicStory>> loadStories() async => const [
    IslamicStory(
      id: 's1',
      title: 'Pemuda Ashabul Kahfi',
      category: "Kisah Qur'ani",
      readMinutes: 3,
      summary: 'Sekelompok pemuda menjaga tauhid di dalam gua.',
      paragraphs: ['Paragraf pertama kisah Ashabul Kahfi.'],
      lessons: ['Teguh menjaga iman sejak muda.'],
      sourceRef: 'QS. Al-Kahfi (18): 9-26',
    ),
  ];

  @override
  Future<Set<String>> loadFavoriteQuotes() async => {..._quoteFavs};

  @override
  Future<void> saveFavoriteQuotes(Set<String> ids) async {
    _quoteFavs = {...ids};
  }

  @override
  Future<Set<String>> loadFavoriteStories() async => {..._storyFavs};

  @override
  Future<void> saveFavoriteStories(Set<String> ids) async {
    _storyFavs = {...ids};
  }
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
