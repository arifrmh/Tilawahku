import 'dart:convert';

import '../../../core/database/app_database.dart';
import '../../../core/preferences/app_preferences.dart';
import '../domain/kajian_models.dart';
import '../domain/kajian_rss_parser.dart';
import 'kajian_cache_store.dart';
import 'kajian_feed_client.dart';

class KajianRepository {
  KajianRepository({
    AppPreferences? preferences,
    KajianCacheStore? cacheStore,
    KajianFeedClient? feedClient,
    DateTime Function()? clock,
    Duration cacheTtl = const Duration(hours: 6),
    List<KajianSource>? defaultSources,
  }) : _preferences = preferences ?? const AppPreferences(),
       _cacheStore = cacheStore ?? SqliteKajianCacheStore(AppDatabase.instance),
       _feedClient = feedClient ?? DioKajianFeedClient(),
       _clock = clock ?? DateTime.now,
       _cacheTtl = cacheTtl,
       _defaultSources = defaultSources ?? defaultKajianSources;

  static const _sourcesKey = 'kajian_sources_v1';
  static const _favoritesKey = 'kajian_favorites_v1';
  static const _historyKey = 'kajian_history_v1';
  static const _maxHistoryEntries = 50;

  final AppPreferences _preferences;
  final KajianCacheStore _cacheStore;
  final KajianFeedClient _feedClient;
  final DateTime Function() _clock;
  final Duration _cacheTtl;
  final List<KajianSource> _defaultSources;

  Future<List<KajianSource>> loadSources() async {
    final raw = await _preferences.getString(_sourcesKey);
    if (raw == null) {
      if (_defaultSources.isEmpty) return const [];
      await _saveSources(_defaultSources);
      return List.unmodifiable(_defaultSources);
    }
    if (raw.trim().isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map(
            (entry) => KajianSource.fromJson(
              (entry as Map<String, dynamic>).cast<String, Object?>(),
            ),
          )
          .where((source) => source.feedUrl.isNotEmpty)
          .toList(growable: false);
    } on Object {
      return const [];
    }
  }

  Future<void> restoreDefaultSources() async {
    final existing = await loadSources();
    final existingUrls = existing.map((source) => source.feedUrl).toSet();
    final merged = [
      ...existing,
      ..._defaultSources.where(
        (source) => !existingUrls.contains(source.feedUrl),
      ),
    ];
    await _saveSources(merged);
  }

  Future<void> _saveSources(List<KajianSource> sources) => _preferences.setString(
    _sourcesKey,
    jsonEncode(sources.map((source) => source.toJson()).toList(growable: false)),
  );

  Future<ParsedKajianFeed> addSource(
    String rawFeedUrl, {
    String? customLicenseNote,
  }) async {
    final normalized = normalizeKajianUrl(rawFeedUrl);
    if (normalized == null) {
      throw const FormatException(
        'URL tidak valid. Masukkan alamat feed RSS diawali http:// atau https://.',
      );
    }

    final existing = await loadSources();
    if (existing.any((source) => source.feedUrl == normalized)) {
      throw const FormatException('Sumber RSS tersebut sudah terdaftar.');
    }

    final now = _clock();
    final xml = await _feedClient.fetchXml(normalized);
    final parsed = parseKajianRssFeed(
      xml: xml,
      feedUrl: normalized,
      customLicenseNote: customLicenseNote,
      addedAt: now,
    );

    await _cacheStore.saveFeed(
      CachedKajianFeed(
        feedUrl: normalized,
        source: parsed.source,
        items: parsed.items,
        fetchedAt: now,
      ),
    );
    await _saveSources([...existing, parsed.source]);
    return parsed;
  }

  Future<void> removeSource(String feedUrl) async {
    final sources = await loadSources();
    final updated = sources
        .where((source) => source.feedUrl != feedUrl)
        .toList(growable: false);
    await _saveSources(updated);
    await _cacheStore.deleteFeed(feedUrl);
  }

  Future<void> setSourceEnabled(String feedUrl, bool enabled) async {
    final sources = await loadSources();
    final updated = sources
        .map(
          (source) => source.feedUrl == feedUrl
              ? source.copyWith(enabled: enabled)
              : source,
        )
        .toList(growable: false);
    await _saveSources(updated);
  }

  Future<KajianCatalogSnapshot> loadCatalog({bool forceRefresh = false}) async {
    final sources = await loadSources();
    if (sources.isEmpty) {
      return const KajianCatalogSnapshot.empty();
    }

    final now = _clock();
    final enabledSources = sources.where((source) => source.enabled).toList();
    if (enabledSources.isEmpty) {
      return KajianCatalogSnapshot(
        sources: sources,
        items: const [],
        fromCache: false,
        fetchedAt: null,
        warnings: const ['Semua sumber RSS sedang dinonaktifkan.'],
      );
    }

    final updatedSources = List<KajianSource>.from(sources);
    var sourcesChanged = false;

    final results = await Future.wait(
      enabledSources.map((source) async {
        final cached = await _cacheStore.getFeed(source.feedUrl);
        final isFresh =
            cached != null && now.difference(cached.fetchedAt) <= _cacheTtl;
        if (!forceRefresh && isFresh) {
          return (
            source: source,
            items: cached.items,
            fromCache: true,
            fetchedAt: cached.fetchedAt,
            warning: null,
            parsedSource: null,
          );
        }
        try {
          final xml = await _feedClient.fetchXml(source.feedUrl);
          final parsed = parseKajianRssFeed(
            xml: xml,
            feedUrl: source.feedUrl,
            customLicenseNote: source.licenseNote,
            addedAt: DateTime.tryParse(source.addedAt) ?? now,
          );
          await _cacheStore.saveFeed(
            CachedKajianFeed(
              feedUrl: source.feedUrl,
              source: parsed.source,
              items: parsed.items,
              fetchedAt: now,
            ),
          );
          return (
            source: source,
            items: parsed.items,
            fromCache: false,
            fetchedAt: now,
            warning: null,
            parsedSource: parsed.source,
          );
        } on Object catch (error) {
          if (cached != null) {
            return (
              source: source,
              items: cached.items,
              fromCache: true,
              fetchedAt: cached.fetchedAt,
              warning:
                  '${source.title}: gagal memperbarui, menampilkan cache lokal ($error)',
              parsedSource: null,
            );
          }
          return (
            source: source,
            items: const <KajianItem>[],
            fromCache: false,
            fetchedAt: null,
            warning: '${source.title}: $error',
            parsedSource: null,
          );
        }
      }),
    );

    final items = <KajianItem>[];
    final warnings = <String>[];
    var anyFromCache = false;
    DateTime? latestFetch;

    for (final result in results) {
      items.addAll(result.items);
      if (result.fromCache) anyFromCache = true;
      if (result.fetchedAt != null &&
          (latestFetch == null || result.fetchedAt!.isAfter(latestFetch))) {
        latestFetch = result.fetchedAt;
      }
      if (result.warning != null) warnings.add(result.warning!);
      final parsedSource = result.parsedSource;
      if (parsedSource != null) {
        final index = updatedSources.indexWhere(
          (entry) => entry.feedUrl == result.source.feedUrl,
        );
        if (index != -1 &&
            (updatedSources[index].title != parsedSource.title ||
                updatedSources[index].author != parsedSource.author)) {
          updatedSources[index] = updatedSources[index].copyWith(
            title: parsedSource.title,
            author: parsedSource.author,
            websiteUrl: parsedSource.websiteUrl,
          );
          sourcesChanged = true;
        }
      }
    }

    if (sourcesChanged) {
      await _saveSources(updatedSources);
    }

    return KajianCatalogSnapshot(
      sources: List.unmodifiable(updatedSources),
      items: List.unmodifiable(items),
      fromCache: anyFromCache,
      fetchedAt: latestFetch,
      warnings: List.unmodifiable(warnings),
    );
  }

  Future<Set<String>> loadFavorites() async {
    final raw = await _preferences.getString(_favoritesKey);
    if (raw == null || raw.isEmpty) return <String>{};
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.whereType<String>().toSet();
    } on Object {
      return <String>{};
    }
  }

  Future<Set<String>> toggleFavorite(String itemId) async {
    final current = await loadFavorites();
    if (!current.remove(itemId)) {
      current.add(itemId);
    }
    await _preferences.setString(
      _favoritesKey,
      jsonEncode(current.toList(growable: false)),
    );
    return current;
  }

  Future<List<KajianPlaybackRecord>> loadHistory() async {
    final raw = await _preferences.getString(_historyKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map(
            (entry) => KajianPlaybackRecord.fromJson(
              (entry as Map<String, dynamic>).cast<String, Object?>(),
            ),
          )
          .where((record) => record.itemId.isNotEmpty)
          .toList(growable: false);
    } on Object {
      return const [];
    }
  }

  Future<List<KajianPlaybackRecord>> recordPlayback(
    KajianPlaybackRecord record,
  ) async {
    final current = await loadHistory();
    final updated = [
      record,
      ...current.where((entry) => entry.itemId != record.itemId),
    ].take(_maxHistoryEntries).toList(growable: false);
    await _preferences.setString(
      _historyKey,
      jsonEncode(updated.map((entry) => entry.toJson()).toList(growable: false)),
    );
    return updated;
  }
}
