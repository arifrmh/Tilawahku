import 'package:flutter/foundation.dart';

import '../data/quotes_stories_repository.dart';
import '../domain/quotes_stories_models.dart';

enum QuotesStoriesLoadState { loading, ready, failed }

class QuotesStoriesController extends ChangeNotifier {
  QuotesStoriesController({
    QuotesStoriesRepository? repository,
    DateTime Function()? clock,
  }) : _repository = repository ?? QuotesStoriesRepository(),
       _clock = clock ?? DateTime.now;

  final QuotesStoriesRepository _repository;
  final DateTime Function() _clock;

  QuotesStoriesLoadState state = QuotesStoriesLoadState.loading;
  List<IslamicQuote> allQuotes = const [];
  List<IslamicStory> allStories = const [];
  Set<String> favoriteQuoteIds = const {};
  Set<String> favoriteStoryIds = const {};
  String quoteQuery = '';
  String storyQuery = '';
  String? selectedQuoteCategory;
  String? selectedStoryCategory;
  bool favoritesOnly = false;
  String? errorMessage;
  bool _disposed = false;

  IslamicQuote? get todayQuote => quoteOfTheDay(allQuotes, _clock());

  List<String> get quoteCategories =>
      allQuotes.map((item) => item.category).toSet().toList(growable: false);

  List<String> get storyCategories =>
      allStories.map((item) => item.category).toSet().toList(growable: false);

  List<IslamicQuote> get visibleQuotes => filterQuotes(
    allQuotes,
    query: quoteQuery,
    category: selectedQuoteCategory,
    favoritesOnly: favoritesOnly,
    favorites: favoriteQuoteIds,
  );

  List<IslamicStory> get visibleStories => filterStories(
    allStories,
    query: storyQuery,
    category: selectedStoryCategory,
    favoritesOnly: favoritesOnly,
    favorites: favoriteStoryIds,
  );

  bool isQuoteFavorite(String id) => favoriteQuoteIds.contains(id);

  bool isStoryFavorite(String id) => favoriteStoryIds.contains(id);

  Future<void> load() async {
    state = QuotesStoriesLoadState.loading;
    errorMessage = null;
    _notify();
    try {
      final results = await Future.wait([
        _repository.loadQuotes(),
        _repository.loadStories(),
        _repository.loadFavoriteQuotes(),
        _repository.loadFavoriteStories(),
      ]);
      allQuotes = results[0] as List<IslamicQuote>;
      allStories = results[1] as List<IslamicStory>;
      favoriteQuoteIds = Set<String>.unmodifiable(results[2] as Set<String>);
      favoriteStoryIds = Set<String>.unmodifiable(results[3] as Set<String>);
      state = QuotesStoriesLoadState.ready;
    } on Object catch (error) {
      errorMessage = 'Data quotes dan kisah tidak dapat dimuat: $error';
      state = QuotesStoriesLoadState.failed;
    }
    _notify();
  }

  void setQuoteQuery(String value) {
    if (quoteQuery == value) return;
    quoteQuery = value;
    _notify();
  }

  void setStoryQuery(String value) {
    if (storyQuery == value) return;
    storyQuery = value;
    _notify();
  }

  void selectQuoteCategory(String? category) {
    if (selectedQuoteCategory == category) return;
    selectedQuoteCategory = category;
    _notify();
  }

  void selectStoryCategory(String? category) {
    if (selectedStoryCategory == category) return;
    selectedStoryCategory = category;
    _notify();
  }

  void toggleFavoritesOnly() {
    favoritesOnly = !favoritesOnly;
    _notify();
  }

  void clearQuoteFilters() {
    quoteQuery = '';
    selectedQuoteCategory = null;
    favoritesOnly = false;
    _notify();
  }

  void clearStoryFilters() {
    storyQuery = '';
    selectedStoryCategory = null;
    favoritesOnly = false;
    _notify();
  }

  Future<bool> toggleQuoteFavorite(String id) async {
    final updated = {...favoriteQuoteIds};
    final added = updated.add(id);
    if (!added) updated.remove(id);
    favoriteQuoteIds = Set<String>.unmodifiable(updated);
    _notify();
    try {
      await _repository.saveFavoriteQuotes(updated);
    } on Object {
      // Pertahankan state di memori bila penyimpanan lokal gagal sementara.
    }
    return added;
  }

  Future<bool> toggleStoryFavorite(String id) async {
    final updated = {...favoriteStoryIds};
    final added = updated.add(id);
    if (!added) updated.remove(id);
    favoriteStoryIds = Set<String>.unmodifiable(updated);
    _notify();
    try {
      await _repository.saveFavoriteStories(updated);
    } on Object {
      // Pertahankan state di memori bila penyimpanan lokal gagal sementara.
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
