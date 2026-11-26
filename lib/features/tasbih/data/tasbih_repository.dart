import 'dart:convert';

import '../../../core/preferences/app_preferences.dart';
import '../domain/tasbih_models.dart';

class TasbihRepository {
  TasbihRepository({AppPreferences? preferences})
    : _preferences = preferences ?? const AppPreferences();

  static const _stateKey = 'tasbih_state_v1';

  final AppPreferences _preferences;

  Future<TasbihState> loadState() async {
    final raw = await _preferences.getString(_stateKey);
    if (raw == null || raw.isEmpty) return const TasbihState();
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return TasbihState.fromJson(decoded);
    } on Object {
      return const TasbihState();
    }
  }

  Future<void> saveState(TasbihState state) =>
      _preferences.setString(_stateKey, jsonEncode(state.toJson()));
}
