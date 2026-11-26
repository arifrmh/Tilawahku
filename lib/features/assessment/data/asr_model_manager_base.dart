import 'asr_model_release.dart';

/// Kontrak status & pengunduhan model ASR lokal.
/// Implementasi native berada di [asr_model_manager_io.dart], sedangkan Web
/// memakai stub ini agar build lintas platform tetap aman tanpa `dart:io`.
enum AsrModelInstallState {
  unsupportedPlatform,
  notDownloaded,
  ready,
}

class AsrModelStatus {
  const AsrModelStatus({
    required this.state,
    required this.totalBytes,
    this.downloadedBytes = 0,
  });

  final AsrModelInstallState state;
  final int totalBytes;
  final int downloadedBytes;

  bool get isReady => state == AsrModelInstallState.ready;
  bool get canDownload => state == AsrModelInstallState.notDownloaded;

  String get sizeLabel =>
      '${(totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

abstract interface class AsrModelRepository {
  Future<AsrModelStatus> checkStatus();
  Future<void> downloadModel({
    void Function(double fraction, String message)? onProgress,
  });
  Future<void> deleteModel();
}

class StubAsrModelManager implements AsrModelRepository {
  const StubAsrModelManager({AsrModelRelease release = asrWebModelRelease})
    : _release = release;

  final AsrModelRelease _release;

  @override
  Future<AsrModelStatus> checkStatus() async => AsrModelStatus(
    state: AsrModelInstallState.unsupportedPlatform,
    totalBytes: _release.totalBytes,
  );

  @override
  Future<void> downloadModel({
    void Function(double fraction, String message)? onProgress,
  }) async {
    throw UnsupportedError(
      'Pengunduhan model ASR lokal hanya tersedia pada perangkat Android.',
    );
  }

  @override
  Future<void> deleteModel() async {}
}
