import 'package:flutter/foundation.dart';

import '../data/islamic_figures_repository.dart';
import '../domain/islamic_figures_models.dart';

class IslamicFiguresController extends ChangeNotifier {
  IslamicFiguresController({required IslamicFiguresRepository repository})
    : _repository = repository;

  final IslamicFiguresRepository _repository;

  List<IslamicFigure> _items = const [];
  Set<String> _favoriteIds = <String>{};
  FigureCategory? _selectedCategory;
  bool _favoritesOnly = false;
  String _query = '';
  bool _loading = true;
  Object? _error;
  bool _disposed = false;

  List<IslamicFigure> get items => _items;
  Set<String> get favoriteIds => Set.unmodifiable(_favoriteIds);
  FigureCategory? get selectedCategory => _selectedCategory;
  bool get favoritesOnly => _favoritesOnly;
  String get query => _query;
  bool get loading => _loading;
  Object? get error => _error;

  List<IslamicFigure> get visibleItems => filterIslamicFigures(
    _items,
    category: _selectedCategory,
    query: _query,
    favoriteIds: _favoritesOnly ? _favoriteIds : null,
  );

  bool isFavorite(String id) => _favoriteIds.contains(id);

  Future<void> load() async {
    _loading = true;
    _error = null;
    _notify();
    try {
      final results = await Future.wait<Object>([
        _repository.loadFigures(),
        _repository.loadFavorites(),
      ]);
      _items = results[0] as List<IslamicFigure>;
      _favoriteIds = results[1] as Set<String>;
      _loading = false;
      _notify();
    } catch (error) {
      _error = error;
      _loading = false;
      _notify();
    }
  }

  void setCategory(FigureCategory? category) {
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

  Future<void> toggleFavorite(String id) async {
    final next = Set<String>.from(_favoriteIds);
    if (!next.remove(id)) next.add(id);
    _favoriteIds = next;
    _notify();
    await _repository.saveFavorites(next);
  }

  String formatCopyText(IslamicFigure figure) {
    final buffer = StringBuffer()
      ..writeln('${figure.name} (${figure.arabicName})')
      ..writeln('${figure.epithet} · ${figure.eraLabel}')
      ..writeln()
      ..writeln(figure.summary)
      ..writeln()
      ..writeln('Keteladanan utama:');
    for (final lesson in figure.keyLessons) {
      buffer.writeln('- $lesson');
    }
    buffer
      ..writeln()
      ..writeln('Rujukan:');
    for (final ref in figure.references) {
      buffer.writeln('- $ref');
    }
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
