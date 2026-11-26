import 'dart:convert';

import 'package:flutter/services.dart';

import '../../../core/preferences/app_preferences.dart';
import '../domain/quotes_stories_models.dart';

class QuotesStoriesRepository {
  QuotesStoriesRepository({
    AppPreferences? preferences,
    AssetBundle? bundle,
  }) : _preferences = preferences ?? const AppPreferences(),
       _bundle = bundle ?? rootBundle;

  static const quotesAssetPath = 'assets/islamic/quotes.json';
  static const storiesAssetPath = 'assets/islamic/stories.json';
  static const _quoteFavoritesKey = 'islamic_quotes_favorites';
  static const _storyFavoritesKey = 'islamic_stories_favorites';

  final AppPreferences _preferences;
  final AssetBundle _bundle;

  List<IslamicQuote>? _cachedQuotes;
  List<IslamicStory>? _cachedStories;

  Future<List<IslamicQuote>> loadQuotes() async {
    final cached = _cachedQuotes;
    if (cached != null) return cached;

    final raw = await _bundle.loadString(quotesAssetPath);
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final items = (decoded['items'] as List<dynamic>)
        .map((item) => IslamicQuote.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
    _cachedQuotes = items;
    return items;
  }

  Future<List<IslamicStory>> loadStories() async {
    final cached = _cachedStories;
    if (cached != null) return cached;

    final raw = await _bundle.loadString(storiesAssetPath);
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final items = (decoded['items'] as List<dynamic>)
        .map((item) => IslamicStory.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
    _cachedStories = items;
    return items;
  }

  Future<Set<String>> loadFavoriteQuotes() =>
      _loadStringSet(_quoteFavoritesKey);

  Future<void> saveFavoriteQuotes(Set<String> ids) =>
      _saveStringSet(_quoteFavoritesKey, ids);

  Future<Set<String>> loadFavoriteStories() =>
      _loadStringSet(_storyFavoritesKey);

  Future<void> saveFavoriteStories(Set<String> ids) =>
      _saveStringSet(_storyFavoritesKey, ids);

  Future<Set<String>> _loadStringSet(String key) async {
    final raw = await _preferences.getString(key);
    if (raw == null || raw.isEmpty) return <String>{};
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.whereType<String>().toSet();
    } on Object {
      return <String>{};
    }
  }

  Future<void> _saveStringSet(String key, Set<String> values) async {
    final sorted = values.toList()..sort();
    await _preferences.setString(key, jsonEncode(sorted));
  }
}
