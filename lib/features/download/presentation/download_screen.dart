import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../core/preferences/app_preferences.dart';
import '../../voices/data/voice_catalog.dart';
import '../../voices/presentation/qari_avatar.dart';
import '../../voices/presentation/voice_selection_screen.dart';
import '../data/audio_download_manager.dart';
import '../data/audio_package_repository.dart';
import '../data/surah_audio_repository.dart';

class DownloadScreen extends StatefulWidget {
  const DownloadScreen({
    super.key,
    required this.preferences,
    this.onSetDarkMode,
    this.catalog,
    this.packageRepository,
    this.surahPackageRepository,
    this.downloadManager,
  });

  final AppPreferences preferences;
  final ValueChanged<bool>? onSetDarkMode;
  final VoiceCatalog? catalog;
  final AudioPackageRepository? packageRepository;
  final SurahAudioRepository? surahPackageRepository;
  final AudioDownloadManager? downloadManager;

  @override
  State<DownloadScreen> createState() => _DownloadScreenState();
}

class _DownloadScreenState extends State<DownloadScreen> {
  late final VoiceCatalog _catalog = widget.catalog ?? const VoiceCatalog();
  late final AudioPackageRepository _packageRepository =
      widget.packageRepository ?? AudioPackageRepository();
  late final SurahAudioRepository _surahPackageRepository =
      widget.surahPackageRepository ?? SurahAudioRepository();
  late final AudioDownloadManager _downloadManager =
      widget.downloadManager ?? AudioDownloadManager.instance;

  Voice? _selectedVoice;
  List<AudioPackage>? _packages;
  List<SurahAudioPackage>? _surahPackages;
  String? _error;
  String? _surahLoadError;
  bool _loading = true;
  bool _loadingSurahPackages = false;
  bool _reloadingPackages = false;
  Timer? _downloadUiRefresh;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) return;
    _downloadManager.addListener(_onDownloadChange);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _surahLoadError = null;
      _surahPackages = null;
      _loadingSurahPackages = false;
    });
    try {
      final voices = await _catalog.load();
      final selectedId = await widget.preferences.selectedVoiceId;
      Voice? voice;
      if (selectedId != null) {
        for (final item in voices) {
          if (item.id == selectedId && item.status == VoiceStatus.active) {
            voice = item;
            break;
          }
        }
      }
      if (voice == null) {
        if (!mounted) return;
        setState(() {
          _selectedVoice = null;
          _packages = null;
          _loading = false;
        });
        return;
      }
      if (voice.audioMode == VoiceAudioMode.surah) {
        if (!mounted) return;
        setState(() {
          _selectedVoice = voice;
          _packages = null;
          _loading = false;
        });
        return;
      }
      await _downloadManager.recoverInterruptedDownloads(voice.id);
      final packages = await _packageRepository.getPackages(voice.id);
      if (packages.length != 30) {
        throw StateError(
          'Manifest audio belum lengkap (${packages.length}/30 juz).',
        );
      }
      if (!mounted) return;
      setState(() {
        _selectedVoice = voice;
        _packages = packages;
        _loading = false;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = _formatError(error);
          _loading = false;
        });
      }
    }
  }

  void _onDownloadChange() {
    if (!mounted || _downloadUiRefresh?.isActive == true) return;
    _downloadUiRefresh = Timer(const Duration(milliseconds: 150), () {
      if (!mounted) return;
      setState(() {});
      final voice = _selectedVoice;
      final surahPackages = _surahPackages;
      final surahCompleted =
          voice != null &&
          surahPackages != null &&
          surahPackages.any(
            (package) =>
                !package.isComplete &&
                _downloadManager
                        .surahProgressFor(voice.id, package.surahNumber)
                        ?.status ==
                    AudioPackageStatus.complete,
          );
      final juzCompleted =
          voice != null &&
          _packages?.any(
                (package) =>
                    package.status != AudioPackageStatus.complete &&
                    _downloadManager.statusFor(voice.id, package.juz) ==
                        AudioPackageStatus.complete,
              ) ==
              true;
      if (surahCompleted || juzCompleted) {
        unawaited(_reloadPackages());
      }
    });
  }

  Future<void> _loadSurahPackages(Voice voice) async {
    try {
      final packages = await _surahPackageRepository.getPackages(voice.id);
      if (!mounted || _selectedVoice?.id != voice.id) return;
      setState(() {
        _surahPackages = packages;
        _loadingSurahPackages = false;
        _surahLoadError = null;
      });
      final surahCompleted = packages.any(
        (package) =>
            !package.isComplete &&
            _downloadManager
                    .surahProgressFor(voice.id, package.surahNumber)
                    ?.status ==
                AudioPackageStatus.complete,
      );
      final juzCompleted =
          _packages?.any(
            (package) =>
                package.status != AudioPackageStatus.complete &&
                _downloadManager.statusFor(voice.id, package.juz) ==
                    AudioPackageStatus.complete,
          ) ==
          true;
      if (surahCompleted || juzCompleted) {
        unawaited(_reloadPackages());
      }
    } catch (error) {
      if (!mounted || _selectedVoice?.id != voice.id) return;
      setState(() {
        _loadingSurahPackages = false;
        _surahLoadError = _formatError(error);
      });
    }
  }

  Future<void> _openVoiceSelection() async {
    await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (_) => VoiceSelectionScreen(
          preferences: widget.preferences,
          onSetDarkMode: widget.onSetDarkMode ?? (_) {},
          allowBack: true,
        ),
      ),
    );
    if (mounted) {
      await _load();
    }
  }

  Future<void> _startDownload(AudioPackage package) async {
    final voice = _selectedVoice;
    if (voice == null) return;
    try {
      final totalBytes = package.totalBytes > 0
          ? package.totalBytes
          : await _downloadManager.estimatePackageSize(
              voice: voice,
              juz: package.juz,
            );
      if (!mounted) return;

      final shouldDownload = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Unduh Juz ${package.juz}?'),
          content: Text(
            '${package.totalAyah} ayat · ${_formatBytes(totalBytes)}\n'
            'Audio akan disimpan di perangkat dan dapat diputar offline.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Nanti'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Unduh'),
            ),
          ],
        ),
      );
      if (shouldDownload != true || !mounted) return;

      unawaited(
        _downloadManager
            .downloadPackage(
              voice: voice,
              juz: package.juz,
              totalBytes: totalBytes,
            )
            .catchError((Object error) {
              if (mounted) {
                _showMessage(
                  'Unduhan Juz ${package.juz} gagal: ${_formatError(error)}',
                );
              }
            }),
      );
    } catch (error) {
      if (mounted) {
        _showMessage('Tidak dapat memulai unduhan: ${_formatError(error)}');
      }
    }
  }

  Future<void> _deletePackage(AudioPackage package) async {
    final voice = _selectedVoice;
    if (voice == null) return;
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus audio Juz ${package.juz}?'),
        content: const Text(
          'File audio yang tersimpan untuk juz ini akan dihapus. Ayat yang '
          'sama pada unduhan surah juga akan terhapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (shouldDelete != true) return;

    try {
      await _downloadManager.deletePackage(voice: voice, juz: package.juz);
      await _reloadPackages();
    } catch (error) {
      if (mounted) {
        _showMessage('Gagal menghapus audio: ${_formatError(error)}');
      }
    }
  }

  Future<void> _startSurahDownload(SurahAudioPackage package) async {
    final voice = _selectedVoice;
    if (voice == null) return;
    try {
      final totalBytes = await _downloadManager.estimateSurahSize(
        voice: voice,
        surahNumber: package.surahNumber,
      );
      if (!mounted) return;
      final shouldDownload = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Unduh Surah ${package.surahName}?'),
          content: Text(
            '${package.totalAyahs} ayat · ${_formatBytes(totalBytes)}\n'
            'Audio akan disimpan di perangkat dan dapat diputar offline.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Nanti'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Unduh'),
            ),
          ],
        ),
      );
      if (shouldDownload != true || !mounted) return;

      unawaited(
        _downloadManager
            .downloadSurah(
              voice: voice,
              surahNumber: package.surahNumber,
              totalBytes: totalBytes,
            )
            .catchError((Object error) {
              if (mounted) {
                _showMessage(
                  'Unduhan Surah ${package.surahName} gagal: '
                  '${_formatError(error)}',
                );
              }
            }),
      );
    } catch (error) {
      if (mounted) {
        _showMessage(
          'Tidak dapat menyiapkan unduhan Surah ${package.surahName}: '
          '${_formatError(error)}',
        );
      }
    }
  }

  Future<void> _deleteSurahPackage(SurahAudioPackage package) async {
    final voice = _selectedVoice;
    if (voice == null) return;
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus audio Surah ${package.surahName}?'),
        content: const Text(
          'File audio surah ini akan dihapus. File ayat yang sama pada '
          'unduhan juz juga akan terhapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (shouldDelete != true) return;

    try {
      await _downloadManager.deleteSurah(
        voice: voice,
        surahNumber: package.surahNumber,
      );
      await _reloadPackages();
    } catch (error) {
      if (mounted) {
        _showMessage('Gagal menghapus audio surah: ${_formatError(error)}');
      }
    }
  }

  Future<void> _reloadPackages() async {
    final voice = _selectedVoice;
    if (voice == null || _reloadingPackages) return;
    _reloadingPackages = true;
    try {
      final packages = await _packageRepository.getPackages(voice.id);
      final surahPackages = _surahPackages == null
          ? null
          : await _surahPackageRepository.getPackages(voice.id);
      if (mounted) {
        setState(() {
          _packages = packages;
          if (surahPackages != null) {
            _surahPackages = surahPackages;
            _surahLoadError = null;
          }
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = 'Gagal memuat paket audio: ${_formatError(error)}');
      }
    } finally {
      _reloadingPackages = false;
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _onTabSelected(int index) {
    if (index != 1 ||
        _surahPackages != null ||
        _loadingSurahPackages ||
        _surahLoadError != null) {
      return;
    }
    final voice = _selectedVoice;
    if (voice == null) return;
    setState(() => _loadingSurahPackages = true);
    unawaited(_loadSurahPackages(voice));
  }

  @override
  void dispose() {
    _downloadUiRefresh?.cancel();
    _downloadManager.removeListener(_onDownloadChange);
    super.dispose();
  }

  bool get _hasDownloadablePackages =>
      !kIsWeb &&
      !_loading &&
      _error == null &&
      _selectedVoice != null &&
      _selectedVoice?.audioMode != VoiceAudioMode.surah;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Unduhan audio'),
          bottom: !_hasDownloadablePackages
              ? null
              : PreferredSize(
                  preferredSize: const Size.fromHeight(52),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: Container(
                      height: 40,
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colors.outlineVariant.withValues(alpha: 0.45),
                        ),
                      ),
                      child: TabBar(
                        onTap: _onTabSelected,
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        indicator: BoxDecoration(
                          color: colors.primary,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        labelColor: colors.onPrimary,
                        unselectedLabelColor: colors.onSurface.withValues(
                          alpha: 0.72,
                        ),
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        tabs: const [
                          Tab(text: 'Juz'),
                          Tab(text: 'Surah'),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
        body: kIsWeb
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Audio belum tersedia secara lokal. Pengunduhan dan '
                    'penyimpanan audio tidak diaktifkan di Web preview.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? _DownloadMessage(
                icon: Icons.error_outline_rounded,
                title: 'Paket audio belum dapat dimuat',
                message: _error!,
                action: FilledButton(
                  onPressed: _load,
                  child: const Text('Coba lagi'),
                ),
              )
            : _selectedVoice == null
            ? _DownloadMessage(
                icon: Icons.record_voice_over_outlined,
                title: 'Belum ada qari dipilih',
                message:
                    'Pilih suara qari terlebih dahulu untuk melihat dan '
                    'mengunduh paket audio juz atau surah agar dapat diputar '
                    'tanpa internet.',
                action: FilledButton(
                  onPressed: _openVoiceSelection,
                  child: const Text('Pilih suara qari'),
                ),
              )
            : _selectedVoice!.audioMode == VoiceAudioMode.surah
            ? _DownloadMessage(
                icon: Icons.stream_rounded,
                title: _selectedVoice!.name,
                message:
                    'Audio ${_selectedVoice!.name} diputar melalui streaming per '
                    'surah. Unduhan offline belum tersedia untuk sumber ini.',
                action: OutlinedButton(
                  onPressed: _openVoiceSelection,
                  child: const Text('Ganti suara qari'),
                ),
              )
            : _buildPackages(context),
      ),
    );
  }

  Widget _buildPackages(BuildContext context) {
    final voice = _selectedVoice!;
    final packages = _packages ?? const <AudioPackage>[];
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    var completeCount = 0;
    var totalDownloadedBytes = 0;
    for (final package in packages) {
      final status =
          _downloadManager.statusFor(voice.id, package.juz) ?? package.status;
      if (status == AudioPackageStatus.complete) {
        completeCount++;
      }
      final liveProgress = _downloadManager.progressFor(voice.id, package.juz);
      totalDownloadedBytes +=
          liveProgress?.completedBytes ?? package.downloadedBytes;
    }

    final completeSurahCount = _surahPackages
        ?.where(
          (package) =>
              package.isComplete ||
              _downloadManager
                      .surahProgressFor(voice.id, package.surahNumber)
                      ?.status ==
                  AudioPackageStatus.complete,
        )
        .length;

    final storageLabel = totalDownloadedBytes > 0
        ? '${_formatBytes(totalDownloadedBytes)} tersimpan untuk mode offline'
        : 'Belum ada audio tersimpan · Streaming tetap aktif saat online';
    final countSummary = completeSurahCount == null
        ? '$completeCount/30 juz\n114 surah tersedia'
        : '$completeCount/30 juz\n$completeSurahCount/114 surah';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          child: Card(
            elevation: 0,
            color: AppColors.navy,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  QariAvatar(voice: voice, size: 48, selected: true),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          voice.name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: AppColors.parchment,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          storageLabel,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.parchment.withValues(alpha: 0.8),
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        countSummary,
                        textAlign: TextAlign.end,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: AppColors.gold,
                          fontWeight: FontWeight.w700,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(height: 4),
                      InkWell(
                        onTap: _openVoiceSelection,
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          child: Text(
                            'Ganti qari',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.parchment.withValues(alpha: 0.9),
                              decoration: TextDecoration.underline,
                              decorationColor: AppColors.parchment.withValues(
                                alpha: 0.65,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: TabBarView(
            children: [
              ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                itemCount: packages.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) => _PackageCard(
                  package: packages[index],
                  manager: _downloadManager,
                  onStart: () => _startDownload(packages[index]),
                  onPause: () => _downloadManager.pausePackage(
                    voiceId: voice.id,
                    juz: packages[index].juz,
                  ),
                  onCancel: () => _downloadManager.cancelPackage(
                    voiceId: voice.id,
                    juz: packages[index].juz,
                  ),
                  onDelete: () => _deletePackage(packages[index]),
                ),
              ),
              _surahPackages == null
                  ? Center(
                      child: _surahLoadError != null
                          ? Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Gagal memuat daftar surah: '
                                    '$_surahLoadError',
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  FilledButton(
                                    onPressed: () {
                                      setState(() {
                                        _loadingSurahPackages = true;
                                        _surahLoadError = null;
                                      });
                                      unawaited(_loadSurahPackages(voice));
                                    },
                                    child: const Text('Coba lagi'),
                                  ),
                                ],
                              ),
                            )
                          : _loadingSurahPackages
                          ? const CircularProgressIndicator()
                          : Text(
                              'Memuat daftar surah...',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colors.onSurface.withValues(alpha: 0.72),
                              ),
                            ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemCount: _surahPackages!.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final package = _surahPackages![index];
                        return _SurahPackageCard(
                          package: package,
                          manager: _downloadManager,
                          onStart: () => _startSurahDownload(package),
                          onPause: () => _downloadManager.pauseSurah(
                            voiceId: voice.id,
                            surahNumber: package.surahNumber,
                          ),
                          onDelete: () => _deleteSurahPackage(package),
                        );
                      },
                    ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SurahPackageCard extends StatelessWidget {
  const _SurahPackageCard({
    required this.package,
    required this.manager,
    required this.onStart,
    required this.onPause,
    required this.onDelete,
  });

  final SurahAudioPackage package;
  final AudioDownloadManager manager;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final liveProgress = manager.surahProgressFor(
      package.voiceId,
      package.surahNumber,
    );
    final downloadedAyahs =
        liveProgress?.completedAyahs ?? package.downloadedAyahs;
    final status =
        liveProgress?.status == AudioPackageStatus.downloading ||
            liveProgress?.status == AudioPackageStatus.paused ||
            liveProgress?.status == AudioPackageStatus.failed
        ? liveProgress!.status
        : downloadedAyahs == package.totalAyahs
        ? AudioPackageStatus.complete
        : AudioPackageStatus.notDownloaded;
    final isActive = status == AudioPackageStatus.downloading;
    final downloadedBytes =
        liveProgress?.downloadedBytes ?? package.downloadedBytes;
    final subtitle = downloadedAyahs == 0 &&
            status == AudioPackageStatus.notDownloaded
        ? '${package.totalAyahs} ayat · Belum diunduh'
        : '$downloadedAyahs/${package.totalAyahs} ayat · '
              '${_formatBytes(downloadedBytes)}';

    return Card(
      elevation: 0,
      color: colors.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: status == AudioPackageStatus.complete
              ? AppColors.gold.withValues(alpha: 0.6)
              : colors.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
        child: Column(
          children: [
            Row(
              children: [
                _NumberBadge(
                  number: package.surahNumber,
                  complete: status == AudioPackageStatus.complete,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        package.surahName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurface.withValues(alpha: 0.72),
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
                if (manager.isEstimatingSurah(
                  package.voiceId,
                  package.surahNumber,
                ))
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else if (isActive)
                  IconButton(
                    tooltip: 'Jeda unduhan surah',
                    onPressed: onPause,
                    icon: const Icon(Icons.pause_rounded),
                  )
                else if (status == AudioPackageStatus.complete)
                  IconButton(
                    tooltip: 'Hapus unduhan surah',
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline_rounded),
                  )
                else
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: downloadedAyahs == 0
                            ? 'Unduh surah'
                            : 'Lanjutkan unduhan surah',
                        onPressed: onStart,
                        icon: Icon(
                          downloadedAyahs == 0
                              ? Icons.download_rounded
                              : Icons.play_arrow_rounded,
                        ),
                      ),
                      if (downloadedAyahs > 0)
                        IconButton(
                          tooltip: 'Hapus audio surah',
                          onPressed: onDelete,
                          icon: const Icon(Icons.delete_outline_rounded),
                        ),
                    ],
                  ),
              ],
            ),
            if (isActive || status == AudioPackageStatus.paused) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  minHeight: 6,
                  value: (liveProgress?.progress ?? 0).clamp(0.0, 1.0),
                ),
              ),
            ],
            if (status == AudioPackageStatus.failed &&
                liveProgress?.error != null)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    _formatError(liveProgress!.error!),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.error,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PackageCard extends StatelessWidget {
  const _PackageCard({
    required this.package,
    required this.manager,
    required this.onStart,
    required this.onPause,
    required this.onCancel,
    required this.onDelete,
  });

  final AudioPackage package;
  final AudioDownloadManager manager;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onCancel;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final status =
        manager.statusFor(package.voiceId, package.juz) ?? package.status;
    final liveProgress = manager.progressFor(package.voiceId, package.juz);
    final progress = liveProgress?.progress ?? package.progress;
    final downloadedBytes =
        liveProgress?.completedBytes ?? package.downloadedBytes;
    final downloadedAyahs =
        liveProgress?.completedAyahs ?? package.downloadedAyah;
    final totalBytes = liveProgress?.totalBytes ?? package.totalBytes;
    final estimating = manager.isEstimating(package.voiceId, package.juz);
    final isActive = status == AudioPackageStatus.downloading;
    final canStart =
        status == AudioPackageStatus.notDownloaded ||
        status == AudioPackageStatus.paused ||
        status == AudioPackageStatus.failed;
    final subtitle = downloadedAyahs == 0 &&
            status == AudioPackageStatus.notDownloaded
        ? '${package.totalAyah} ayat · Belum diunduh'
              '${totalBytes > 0 ? ' · ~${_formatBytes(totalBytes)}' : ''}'
        : '$downloadedAyahs/${package.totalAyah} ayat · '
              '${_formatBytes(downloadedBytes)}'
              '${totalBytes > 0 ? ' dari ${_formatBytes(totalBytes)}' : ''}';

    return Card(
      elevation: 0,
      color: colors.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: status == AudioPackageStatus.complete
              ? AppColors.gold.withValues(alpha: 0.6)
              : colors.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
        child: Column(
          children: [
            Row(
              children: [
                _NumberBadge(
                  number: package.juz,
                  complete: status == AudioPackageStatus.complete,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Juz ${package.juz}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurface.withValues(alpha: 0.72),
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
                if (estimating)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else if (status == AudioPackageStatus.complete)
                  IconButton(
                    tooltip: 'Hapus unduhan',
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline_rounded),
                  )
                else
                  _PackageActionMenu(
                    status: status,
                    canStart: canStart,
                    hasDownloadedFiles: downloadedAyahs > 0,
                    onStart: onStart,
                    onPause: onPause,
                    onCancel: onCancel,
                    onDelete: onDelete,
                  ),
              ],
            ),
            if (status != AudioPackageStatus.complete &&
                (isActive ||
                    status == AudioPackageStatus.paused ||
                    downloadedAyahs > 0)) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  minHeight: 6,
                  value: progress.clamp(0.0, 1.0),
                ),
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${_formatBytes(downloadedBytes)}'
                  '${totalBytes > 0 ? ' / ${_formatBytes(totalBytes)}' : ''}'
                  ' · ${(progress * 100).round()}%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
            if (status == AudioPackageStatus.failed && package.error != null)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    _formatError(package.error!),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.error,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NumberBadge extends StatelessWidget {
  const _NumberBadge({required this.number, this.complete = false});

  final int number;
  final bool complete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: complete
            ? AppColors.gold.withValues(alpha: 0.16)
            : colors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(
        '$number',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: complete ? AppColors.gold : colors.primary,
          fontWeight: FontWeight.w700,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _PackageActionMenu extends StatelessWidget {
  const _PackageActionMenu({
    required this.status,
    required this.canStart,
    required this.hasDownloadedFiles,
    required this.onStart,
    required this.onPause,
    required this.onCancel,
    required this.onDelete,
  });

  final AudioPackageStatus status;
  final bool canStart;
  final bool hasDownloadedFiles;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onCancel;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    if (canStart) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: status == AudioPackageStatus.notDownloaded
                ? 'Unduh'
                : 'Lanjutkan unduhan',
            onPressed: onStart,
            icon: Icon(
              status == AudioPackageStatus.notDownloaded
                  ? Icons.download_rounded
                  : Icons.play_arrow_rounded,
            ),
          ),
          if (hasDownloadedFiles)
            IconButton(
              tooltip: 'Hapus unduhan juz ini',
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
        ],
      );
    }
    return PopupMenuButton<String>(
      tooltip: 'Aksi paket audio',
      onSelected: (action) {
        if (action == 'pause') onPause();
        if (action == 'cancel') onCancel();
        if (action == 'delete') onDelete();
      },
      itemBuilder: (context) => [
        if (status == AudioPackageStatus.downloading)
          const PopupMenuItem(value: 'pause', child: Text('Jeda')),
        if (status == AudioPackageStatus.downloading)
          const PopupMenuItem(value: 'cancel', child: Text('Batalkan unduhan')),
        if (status == AudioPackageStatus.paused ||
            status == AudioPackageStatus.failed)
          const PopupMenuItem(value: 'delete', child: Text('Hapus file')),
      ],
    );
  }
}

class _DownloadMessage extends StatelessWidget {
  const _DownloadMessage({
    required this.icon,
    required this.title,
    required this.message,
    required this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: AppColors.gold),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurface.withValues(alpha: 0.78),
              ),
            ),
            const SizedBox(height: 20),
            action,
          ],
        ),
      ),
    );
  }
}

String _formatBytes(int bytes) {
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

String _formatError(Object error) {
  final text = error.toString().trim();
  if (text.startsWith('Bad state: ')) {
    return text.substring('Bad state: '.length);
  }
  if (text.startsWith('Exception: ')) {
    return text.substring('Exception: '.length);
  }
  return text;
}
