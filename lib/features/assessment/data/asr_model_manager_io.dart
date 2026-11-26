import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'asr_model_manager_base.dart';
import 'asr_model_provisioner.dart';
import 'asr_model_release.dart';
import 'asr_model_transport_file.dart';
import 'sherpa_native_asr_runtime.dart';

export 'asr_model_manager_base.dart';

/// Repositori rilis resmi model Abdou/quran-asr-small (MIT License).
/// Integritas file selalu diverifikasi memakai ukuran dan SHA-256 pada
/// [asrWebModelRelease] sebelum digunakan.
final Uri officialAsrModelDownloadBaseUrl = Uri.parse(
  'https://huggingface.co/Abdou/quran-asr-small/resolve/main/',
);

AsrModelRepository createAsrModelManager() => LocalAsrModelManager();

class LocalAsrModelManager implements AsrModelRepository {
  LocalAsrModelManager({
    AsrModelRelease release = asrWebModelRelease,
    Directory? directory,
    Uri? downloadBaseUrl,
    bool? includeReleaseDirectory,
    bool? platformSupportedOverride,
  }) : _release = release,
       _directoryOverride = directory,
       _downloadBaseUrl = downloadBaseUrl,
       _includeReleaseDirectory = includeReleaseDirectory,
       _platformSupportedOverride = platformSupportedOverride;

  final AsrModelRelease _release;
  final Directory? _directoryOverride;
  final Uri? _downloadBaseUrl;
  final bool? _includeReleaseDirectory;
  final bool? _platformSupportedOverride;

  bool get _isSupportedPlatform {
    if (_platformSupportedOverride != null) return _platformSupportedOverride;
    if (kIsWeb) return false;
    return Platform.isAndroid;
  }

  Future<Directory> _resolveDirectory() async =>
      _directoryOverride ??
      Directory('${(await getApplicationSupportDirectory()).path}/asr');

  ({Uri baseUrl, bool includeReleaseDirectory}) _resolveSource() {
    if (_downloadBaseUrl != null) {
      return (
        baseUrl: _downloadBaseUrl,
        includeReleaseDirectory: _includeReleaseDirectory ?? false,
      );
    }
    if (asrModelBaseUrlConfig.isNotEmpty) {
      final parsed = Uri.tryParse(asrModelBaseUrlConfig);
      if (parsed != null && parsed.hasScheme) {
        final normalized = parsed.path.endsWith('/')
            ? parsed
            : Uri.parse('$parsed/');
        return (baseUrl: normalized, includeReleaseDirectory: true);
      }
    }
    return (
      baseUrl: officialAsrModelDownloadBaseUrl,
      includeReleaseDirectory: false,
    );
  }

  @override
  Future<AsrModelStatus> checkStatus() async {
    if (!_isSupportedPlatform) {
      return AsrModelStatus(
        state: AsrModelInstallState.unsupportedPlatform,
        totalBytes: _release.totalBytes,
      );
    }

    final directory = await _resolveDirectory();
    var allPresentAndExactSize = true;
    var downloadedBytes = 0;

    for (final file in _release.files) {
      final entry = File('${directory.path}/${file.name}');
      if (await entry.exists()) {
        final length = await entry.length();
        downloadedBytes += length;
        if (length != file.byteLength) {
          allPresentAndExactSize = false;
        }
      } else {
        allPresentAndExactSize = false;
      }
    }

    return AsrModelStatus(
      state: allPresentAndExactSize
          ? AsrModelInstallState.ready
          : AsrModelInstallState.notDownloaded,
      totalBytes: _release.totalBytes,
      downloadedBytes: downloadedBytes,
    );
  }

  @override
  Future<void> downloadModel({
    void Function(double fraction, String message)? onProgress,
  }) async {
    if (!_isSupportedPlatform) {
      throw const AsrModelProvisioningException(
        AsrModelFailureKind.notConfigured,
        'Unduhan model ASR lokal hanya tersedia pada perangkat Android.',
      );
    }

    final directory = await _resolveDirectory();
    final source = _resolveSource();
    final transport = AsrModelTransportFile(
      release: _release,
      directory: directory,
      baseUrl: source.baseUrl,
      includeReleaseDirectory: source.includeReleaseDirectory,
    );
    try {
      await AsrModelProvisioner(
        transport: transport,
        release: _release,
      ).ensure(onProgress: onProgress);
    } finally {
      transport.close();
    }
  }

  @override
  Future<void> deleteModel() async {
    if (!_isSupportedPlatform) return;
    final directory = await _resolveDirectory();
    for (final file in _release.files) {
      final entry = File('${directory.path}/${file.name}');
      if (await entry.exists()) {
        await entry.delete();
      }
      final part = File('${entry.path}.part');
      if (await part.exists()) {
        await part.delete();
      }
    }
  }
}
