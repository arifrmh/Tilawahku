import 'dart:convert';

import 'package:flutter/services.dart';

import '../../../core/preferences/app_preferences.dart';
import '../domain/asmaul_husna_models.dart';

class AsmaulHusnaRepository {
  AsmaulHusnaRepository({
    AppPreferences? preferences,
    AssetBundle? bundle,
  }) : _preferences = preferences ?? const AppPreferences(),
       _bundle = bundle ?? rootBundle;

  static const assetPath = 'assets/islamic/asmaul_husna.json';
  static const _favoritesKey = 'asmaul_husna_favorites';

  final AppPreferences _preferences;
  final AssetBundle _bundle;
  List<AsmaulHusnaEntry>? _cachedEntries;

  Future<List<AsmaulHusnaEntry>> loadEntries() async {
    final cached = _cachedEntries;
    if (cached != null) return cached;

    final raw = await _bundle.loadString(assetPath);
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final items = (decoded['items'] as List<dynamic>)
        .map((item) => AsmaulHusnaEntry.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
    _cachedEntries = items;
    return items;
  }

  Future<Set<int>> loadFavorites() async {
    final raw = await _preferences.getString(_favoritesKey);
    if (raw == null || raw.isEmpty) return <int>{};
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.whereType<int>().where((n) => n >= 1 && n <= 99).toSet();
    } on Object {
      return <int>{};
    }
  }

  Future<void> saveFavorites(Set<int> favorites) async {
    final sorted = favorites.toList()..sort();
    await _preferences.setString(_favoritesKey, jsonEncode(sorted));
  }
}
