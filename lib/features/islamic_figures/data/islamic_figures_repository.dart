import 'dart:convert';

import 'package:flutter/services.dart';

import '../../../core/preferences/app_preferences.dart';
import '../domain/islamic_figures_models.dart';

class IslamicFiguresRepository {
  IslamicFiguresRepository({
    AppPreferences? preferences,
    AssetBundle? bundle,
  }) : _preferences = preferences ?? const AppPreferences(),
       _bundle = bundle ?? rootBundle;

  static const assetPath = 'assets/islamic/islamic_figures.json';
  static const _favoritesKey = 'islamic_figures_favorites';

  final AppPreferences _preferences;
  final AssetBundle _bundle;

  List<IslamicFigure>? _cached;

  Future<List<IslamicFigure>> loadFigures() async {
    final cached = _cached;
    if (cached != null) return cached;

    final raw = await _bundle.loadString(assetPath);
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final items = (decoded['items'] as List<dynamic>)
        .map((item) => IslamicFigure.fromJson(item as Map<String, dynamic>))
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
