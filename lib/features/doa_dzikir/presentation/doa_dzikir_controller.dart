import 'package:flutter/foundation.dart';

import '../data/doa_dzikir_repository.dart';
import '../domain/doa_dzikir_models.dart';

class DoaDzikirController extends ChangeNotifier {
  DoaDzikirController({required DoaDzikirRepository repository})
    : _repository = repository;

  final DoaDzikirRepository _repository;

  List<DoaDzikirEntry> _items = const [];
  Set<String> _favoriteIds = <String>{};
  final Map<String, int> _readCounts = {};
  DoaDzikirCategory? _selectedCategory;
  bool _favoritesOnly = false;
  String _query = '';
  bool _loading = true;
  Object? _error;
  bool _disposed = false;

  List<DoaDzikirEntry> get items => _items;
  Set<String> get favoriteIds => Set.unmodifiable(_favoriteIds);
  DoaDzikirCategory? get selectedCategory => _selectedCategory;
  bool get favoritesOnly => _favoritesOnly;
  String get query => _query;
  bool get loading => _loading;
  Object? get error => _error;

  List<DoaDzikirEntry> get visibleItems => filterDoaDzikir(
    _items,
    category: _selectedCategory,
    query: _query,
    favoriteIds: _favoritesOnly ? _favoriteIds : null,
  );

  bool isFavorite(String id) => _favoriteIds.contains(id);

  int readCount(String id) => _readCounts[id] ?? 0;

  Future<void> load() async {
    _loading = true;
    _error = null;
    _notify();
    try {
      final results = await Future.wait<Object>([
        _repository.loadEntries(),
        _repository.loadFavorites(),
      ]);
      _items = results[0] as List<DoaDzikirEntry>;
      _favoriteIds = results[1] as Set<String>;
      _loading = false;
      _notify();
    } catch (error) {
      _error = error;
      _loading = false;
      _notify();
    }
  }

  void setCategory(DoaDzikirCategory? category) {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    _notify();
  }

  void toggleFavoritesOnly() {
    _favoritesOnly = !_favoritesOnly;
    _notify();
  }

  void setQuery(String value) {
    if (_query == value) return;
    _query = value;
    _notify();
  }

  void incrementReadCount(DoaDzikirEntry entry) {
    final current = _readCounts[entry.id] ?? 0;
    _readCounts[entry.id] = current >= entry.repeatCount ? 0 : current + 1;
    _notify();
  }

  Future<void> toggleFavorite(String id) async {
    final next = Set<String>.from(_favoriteIds);
    if (!next.remove(id)) next.add(id);
    _favoriteIds = next;
    _notify();
    await _repository.saveFavorites(next);
  }

  String formatCopyText(DoaDzikirEntry entry) {
    final buffer = StringBuffer()
      ..writeln('${entry.title} (${entry.category.label})')
      ..writeln()
      ..writeln(entry.arabic)
      ..writeln()
      ..writeln(entry.transliteration)
      ..writeln()
      ..writeln('Artinya: "${entry.translationId}"')
      ..writeln()
      ..writeln('Rujukan: ${entry.sourceRef}');
    return buffer.toString().trim();
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
