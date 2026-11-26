import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/kajian_audio_playback.dart';
import '../data/kajian_repository.dart';
import '../domain/kajian_models.dart';
import '../domain/kajian_rss_parser.dart';

class KajianController extends ChangeNotifier {
  KajianController({
    required KajianRepository repository,
    KajianAudioPlayback? playback,
    DateTime Function()? clock,
  }) : _repository = repository,
       _playback = playback ?? JustAudioKajianPlayback(),
       _ownsPlayback = playback == null,
       _clock = clock ?? DateTime.now {
    _playbackState = _playback.currentState;
    _playbackSubscription = _playback.stateStream.listen((nextState) {
      _playbackState = nextState;
      notifyListeners();
    });
  }

  final KajianRepository _repository;
  final KajianAudioPlayback _playback;
  final bool _ownsPlayback;
  final DateTime Function() _clock;
  late final StreamSubscription<KajianPlaybackState> _playbackSubscription;

  KajianCatalogSnapshot _catalog = const KajianCatalogSnapshot.empty();
  Set<String> _favoriteIds = const {};
  List<KajianPlaybackRecord> _history = const [];
  KajianPlaybackState _playbackState = const KajianPlaybackState();

  String _query = '';
  KajianCategory? _selectedCategory;
  String? _selectedSpeaker;
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isAddingSource = false;
  String? _errorMessage;
  bool _disposed = false;

  KajianCatalogSnapshot get catalog => _catalog;
  Set<String> get favoriteIds => _favoriteIds;
  List<KajianPlaybackRecord> get history => _history;
  KajianPlaybackState get playbackState => _playbackState;

  String get query => _query;
  KajianCategory? get selectedCategory => _selectedCategory;
  String? get selectedSpeaker => _selectedSpeaker;
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  bool get isAddingSource => _isAddingSource;
  String? get errorMessage => _errorMessage;

  List<String> get speakers => extractKajianSpeakers(_catalog.items);

  List<KajianItem> get filteredItems => filterKajianItems(
    items: _catalog.items,
    query: _query,
    category: _selectedCategory,
    speaker: _selectedSpeaker,
  );

  List<KajianItem> get savedItems => filterKajianItems(
    items: _catalog.items,
    query: _query,
    category: _selectedCategory,
    speaker: _selectedSpeaker,
    favoritesOnly: true,
    favoriteIds: _favoriteIds,
  );

  List<({KajianItem item, KajianPlaybackRecord record})> get historyEntries {
    final itemById = {for (final item in _catalog.items) item.id: item};
    final result = <({KajianItem item, KajianPlaybackRecord record})>[];
    for (final record in _history) {
      final item = itemById[record.itemId];
      if (item != null) {
        result.add((item: item, record: record));
      }
    }
    return List.unmodifiable(result);
  }

  bool isFavorite(String itemId) => _favoriteIds.contains(itemId);

  KajianPlaybackRecord? historyFor(String itemId) {
    for (final record in _history) {
      if (record.itemId == itemId) return record;
    }
    return null;
  }

  Future<void> load({bool forceRefresh = false}) async {
    if (forceRefresh) {
      _isRefreshing = true;
    } else if (_catalog.items.isEmpty && _catalog.sources.isEmpty) {
      _isLoading = true;
    }
    _errorMessage = null;
    _safeNotify();

    try {
      final results = await Future.wait<Object?>([
        _repository.loadCatalog(forceRefresh: forceRefresh),
        _repository.loadFavorites(),
        _repository.loadHistory(),
      ]);
      _catalog = results[0]! as KajianCatalogSnapshot;
      _favoriteIds = results[1]! as Set<String>;
      _history = results[2]! as List<KajianPlaybackRecord>;

      if (_selectedSpeaker != null && !speakers.contains(_selectedSpeaker)) {
        _selectedSpeaker = null;
      }
    } on Object catch (error) {
      _errorMessage = '$error';
    } finally {
      _isLoading = false;
      _isRefreshing = false;
      _safeNotify();
    }
  }

  void setQuery(String value) {
    if (_query == value) return;
    _query = value;
    _safeNotify();
  }

  void setCategory(KajianCategory? category) {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    _safeNotify();
  }

  void setSpeaker(String? speaker) {
    if (_selectedSpeaker == speaker) return;
    _selectedSpeaker = speaker;
    _safeNotify();
  }

  Future<ParsedKajianFeed> addSource(
    String feedUrl, {
    String? customLicenseNote,
  }) async {
    _isAddingSource = true;
    _safeNotify();
    try {
      final parsed = await _repository.addSource(
        feedUrl,
        customLicenseNote: customLicenseNote,
      );
      await load();
      return parsed;
    } finally {
      _isAddingSource = false;
      _safeNotify();
    }
  }

  Future<void> removeSource(String feedUrl) async {
    if (_playbackState.item?.feedUrl == feedUrl) {
      await _playback.stop();
    }
    await _repository.removeSource(feedUrl);
    await load();
  }

  Future<void> setSourceEnabled(String feedUrl, bool enabled) async {
    if (!enabled && _playbackState.item?.feedUrl == feedUrl) {
      await _playback.stop();
    }
    await _repository.setSourceEnabled(feedUrl, enabled);
    await load();
  }

  Future<void> restoreDefaultSources() async {
    await _repository.restoreDefaultSources();
    await load(forceRefresh: true);
  }

  Future<void> toggleFavorite(String itemId) async {
    _favoriteIds = await _repository.toggleFavorite(itemId);
    _safeNotify();
  }

  Future<void> playOrToggle(KajianItem item) async {
    final active = _playbackState.item;
    if (active?.id == item.id) {
      if (_playbackState.isPlaying) {
        await _playback.pause();
        await _persistCurrentPosition();
      } else {
        await _playback.resume();
      }
      return;
    }

    if (active != null) {
      await _persistCurrentPosition();
    }

    final saved = historyFor(item.id);
    final resumePos =
        saved != null && saved.progressFraction > 0 && saved.progressFraction < 0.95
        ? saved.position
        : Duration.zero;

    await _playback.playItem(item, initialPosition: resumePos);
    await _persistPosition(
      item: item,
      position: resumePos,
      duration: _playback.currentState.duration.inMilliseconds > 0
          ? _playback.currentState.duration
          : Duration(seconds: item.durationSeconds ?? 0),
    );
  }

  Future<void> seek(Duration position) async {
    await _playback.seek(position);
    await _persistCurrentPosition();
  }

  Future<void> seekRelative(Duration offset) async {
    await _playback.seekRelative(offset);
    await _persistCurrentPosition();
  }

  Future<void> setSpeed(double speed) => _playback.setSpeed(speed);

  Future<void> _persistCurrentPosition() async {
    final item = _playbackState.item;
    if (item == null) return;
    await _persistPosition(
      item: item,
      position: _playbackState.position,
      duration: _playbackState.duration.inMilliseconds > 0
          ? _playbackState.duration
          : Duration(seconds: item.durationSeconds ?? 0),
    );
  }

  Future<void> _persistPosition({
    required KajianItem item,
    required Duration position,
    required Duration duration,
  }) async {
    final record = KajianPlaybackRecord(
      itemId: item.id,
      positionMs: position.inMilliseconds,
      durationMs: duration.inMilliseconds,
      playedAt: _clock().toUtc().toIso8601String(),
    );
    _history = await _repository.recordPlayback(record);
    _safeNotify();
  }

  void _safeNotify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_playbackSubscription.cancel());
    if (_ownsPlayback) {
      unawaited(_playback.dispose());
    }
    super.dispose();
  }
}
