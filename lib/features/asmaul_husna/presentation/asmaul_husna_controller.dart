import 'package:flutter/foundation.dart';

import '../data/asmaul_husna_repository.dart';
import '../domain/asmaul_husna_models.dart';

enum AsmaulHusnaLoadState { loading, ready, failed }

class AsmaulHusnaController extends ChangeNotifier {
  AsmaulHusnaController({AsmaulHusnaRepository? repository})
    : _repository = repository ?? AsmaulHusnaRepository();

  final AsmaulHusnaRepository _repository;

  AsmaulHusnaLoadState state = AsmaulHusnaLoadState.loading;
  List<AsmaulHusnaEntry> allEntries = const [];
  Set<int> favorites = const {};
  String query = '';
  bool favoritesOnly = false;
  String? errorMessage;
  bool _disposed = false;

  List<AsmaulHusnaEntry> get visibleEntries => filterAsmaulHusna(
    allEntries,
    query: query,
    favoritesOnly: favoritesOnly,
    favorites: favorites,
  );

  bool isFavorite(int number) => favorites.contains(number);

  Future<void> load() async {
    state = AsmaulHusnaLoadState.loading;
    errorMessage = null;
    _notify();
    try {
      final results = await Future.wait([
        _repository.loadEntries(),
        _repository.loadFavorites(),
      ]);
      allEntries = results[0] as List<AsmaulHusnaEntry>;
      favorites = Set<int>.unmodifiable(results[1] as Set<int>);
      state = AsmaulHusnaLoadState.ready;
    } on Object catch (error) {
      errorMessage = 'Data Asmaul Husna tidak dapat dimuat: $error';
      state = AsmaulHusnaLoadState.failed;
    }
    _notify();
  }

  void setQuery(String value) {
    if (query == value) return;
    query = value;
    _notify();
  }

  void toggleFavoritesOnly() {
    favoritesOnly = !favoritesOnly;
    _notify();
  }

  void clearFilters() {
    query = '';
    favoritesOnly = false;
    _notify();
  }

  Future<bool> toggleFavorite(int number) async {
    final updated = {...favorites};
    final added = updated.add(number);
    if (!added) {
      updated.remove(number);
    }
    favorites = Set<int>.unmodifiable(updated);
    _notify();
    try {
      await _repository.saveFavorites(updated);
    } on Object {
      // Pertahankan state di memori jika penyimpanan lokal gagal sementara.
    }
    return added;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
