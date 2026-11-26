import 'dart:async';
import 'dart:io'
    if (dart.library.js_interop) '../../../core/platform/unsupported_io.dart';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

import '../domain/recitation_audio.dart';

/// Pemutar rekaman sementara untuk memeriksa bacaan hafalan sendiri.
abstract interface class RecitationPlayback {
  Future<void> play(RecitationAudio audio, {required VoidCallback onCompleted});

  Future<void> stop();

  Future<void> dispose();
}

class JustAudioRecitationPlayback implements RecitationPlayback {
  AudioPlayer? _player;
  StreamSubscription<PlayerState>? _stateSub;
  File? _tempFile;

  @override
  Future<void> play(
    RecitationAudio audio, {
    required VoidCallback onCompleted,
  }) async {
    final player = _player ??= AudioPlayer();
    await _stateSub?.cancel();
    await player.stop();
    final wavBytes = audio.toWavBytes();
    if (kIsWeb) {
      final uri = Uri.dataFromBytes(wavBytes, mimeType: 'audio/wav');
      await player.setUrl(uri.toString());
    } else {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/tilawahku_recitation_preview.wav');
      await file.writeAsBytes(wavBytes, flush: true);
      _tempFile = file;
      await player.setFilePath(file.path);
    }
    _stateSub = player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        onCompleted();
      }
    });
    await player.play();
  }

  @override
  Future<void> stop() async {
    await _stateSub?.cancel();
    _stateSub = null;
    await _player?.stop();
  }

  @override
  Future<void> dispose() async {
    await stop();
    final player = _player;
    _player = null;
    await player?.dispose();
    final file = _tempFile;
    _tempFile = null;
    if (file != null) {
      try {
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }
  }
}
