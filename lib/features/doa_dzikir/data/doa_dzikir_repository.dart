import 'dart:convert';

import 'package:flutter/services.dart';

import '../../../core/preferences/app_preferences.dart';
import '../domain/doa_dzikir_models.dart';

class DoaDzikirRepository {
  DoaDzikirRepository({AppPreferences? preferences, AssetBundle? bundle})
    : _preferences = preferences ?? const AppPreferences(),
      _bundle = bundle ?? rootBundle;

  static const assetPath = 'assets/islamic/doa_dzikir.json';
  static const _favoritesKey = 'doa_dzikir_favorites';

  final AppPreferences _preferences;
  final AssetBundle _bundle;

  List<DoaDzikirEntry>? _cached;

  Future<List<DoaDzikirEntry>> loadEntries() async {
    final cached = _cached;
    if (cached != null) return cached;

    final raw = await _bundle.loadString(assetPath);
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final items = (decoded['items'] as List<dynamic>)
        .map((item) => DoaDzikirEntry.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
    _cached = items;
    return items;
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

  Future<void> saveFavorites(Set<String> ids) async {
    final sorted = ids.toList()..sort();
    await _preferences.setString(_favoritesKey, jsonEncode(sorted));
  }
}
