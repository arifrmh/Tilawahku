import 'dart:async';

import 'package:just_audio/just_audio.dart';

import '../../player/data/quran_audio_handler.dart';
import '../domain/kajian_models.dart';

abstract interface class KajianAudioPlayback {
  Stream<KajianPlaybackState> get stateStream;
  KajianPlaybackState get currentState;

  Future<void> playItem(
    KajianItem item, {
    Duration initialPosition = Duration.zero,
  });
  Future<void> pause();
  Future<void> resume();
  Future<void> stop();
  Future<void> seek(Duration position);
  Future<void> seekRelative(Duration offset);
  Future<void> setSpeed(double speed);
  Future<void> dispose();
}

class JustAudioKajianPlayback implements KajianAudioPlayback {
  JustAudioKajianPlayback({
    AudioPlayer? player,
    Future<void> Function()? onBeforePlay,
  }) : _player = player ?? AudioPlayer(),
       _onBeforePlay = onBeforePlay ?? _pauseMurottalIfPlaying {
    _subscriptions.add(
      _player.playerStateStream.listen((playerState) {
        final buffering =
            playerState.processingState == ProcessingState.loading ||
            playerState.processingState == ProcessingState.buffering;
        final completed =
            playerState.processingState == ProcessingState.completed;
        _emit(
          _state.copyWith(
            isPlaying: completed ? false : playerState.playing,
            isBuffering: buffering,
            position: completed ? _state.duration : _state.position,
          ),
        );
      }),
    );
    _subscriptions.add(
      _player.positionStream.listen((position) {
        _emit(_state.copyWith(position: position));
      }),
    );
    _subscriptions.add(
      _player.durationStream.listen((duration) {
        if (duration == null) return;
        _emit(_state.copyWith(duration: duration));
      }),
    );
  }

  final AudioPlayer _player;
  final Future<void> Function() _onBeforePlay;
  final StreamController<KajianPlaybackState> _controller =
      StreamController<KajianPlaybackState>.broadcast();
  final List<StreamSubscription<Object?>> _subscriptions = [];

  KajianPlaybackState _state = const KajianPlaybackState();

  @override
  Stream<KajianPlaybackState> get stateStream => _controller.stream;

  @override
  KajianPlaybackState get currentState => _state;

  @override
  Future<void> playItem(
    KajianItem item, {
    Duration initialPosition = Duration.zero,
  }) async {
    await _onBeforePlay();
    _emit(
      _state.copyWith(
        item: item,
        isBuffering: true,
        isPlaying: false,
        position: initialPosition,
        duration: item.durationSeconds == null
            ? Duration.zero
            : Duration(seconds: item.durationSeconds!),
        clearError: true,
      ),
    );
    try {
      final loadedDuration = await _player.setUrl(item.audioUrl);
      if (initialPosition > Duration.zero) {
        await _player.seek(initialPosition);
      }
      await _player.setSpeed(_state.speed);
      _emit(
        _state.copyWith(
          duration: loadedDuration ?? _state.duration,
          isBuffering: false,
        ),
      );
      await _player.play();
    } on Object {
      _emit(
        _state.copyWith(
          isPlaying: false,
          isBuffering: false,
          errorMessage:
              'Audio kajian tidak dapat diputar. Pastikan koneksi internet aktif dan URL audio valid.',
        ),
      );
    }
  }

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> resume() async {
    await _onBeforePlay();
    await _player.play();
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    _emit(const KajianPlaybackState());
  }

  @override
  Future<void> seek(Duration position) async {
    final maxDuration = _state.duration;
    var clamped = position;
    if (clamped < Duration.zero) clamped = Duration.zero;
    if (maxDuration > Duration.zero && clamped > maxDuration) {
      clamped = maxDuration;
    }
    await _player.seek(clamped);
    _emit(_state.copyWith(position: clamped));
  }

  @override
  Future<void> seekRelative(Duration offset) =>
      seek(_state.position + offset);

  @override
  Future<void> setSpeed(double speed) async {
    final clamped = speed.clamp(0.5, 2.0);
    await _player.setSpeed(clamped);
    _emit(_state.copyWith(speed: clamped));
  }

  @override
  Future<void> dispose() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    await _player.dispose();
    await _controller.close();
  }

  void _emit(KajianPlaybackState next) {
    _state = next;
    if (!_controller.isClosed) {
      _controller.add(next);
    }
  }

  static Future<void> _pauseMurottalIfPlaying() async {
    final handler = QuranAudioHandler.instance;
    if (handler != null && handler.playbackState.value.playing) {
      await handler.pause();
    }
  }
}
