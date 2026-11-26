import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../../app/app_theme.dart';
import '../../../core/preferences/app_preferences.dart';
import '../../player/data/quran_audio_handler.dart';
import '../../reading/data/reading_repository.dart';
import '../../voices/data/voice_audio_source.dart';
import '../../voices/data/voice_catalog.dart';
import '../data/asr_model_manager.dart';
import '../data/asr_runtime.dart';
import '../data/asr_runtime_factory.dart';
import '../data/assessment_lexicon.dart';
import '../data/recitation_playback.dart';
import '../data/recitation_recorder.dart';
import 'assessment_panel.dart';
import 'highlighted_ayah_text.dart';
import 'recitation_assessment_controller.dart';

class RecitationCheckScreen extends StatefulWidget {
  const RecitationCheckScreen({
    super.key,
    required this.readingRepository,
    required this.preferences,
    this.initialSurahNumber = 1,
    this.initialAyahNumber = 1,
    this.runtime,
    this.createCapture,
    this.createPlayback,
    this.modelRepository,
    this.loadSpellingMap,
  });

  final ReadingRepository readingRepository;
  final AppPreferences preferences;
  final int initialSurahNumber;
  final int initialAyahNumber;
  final AsrRuntime? runtime;
  final RecitationCapture Function()? createCapture;
  final RecitationPlayback Function()? createPlayback;
  final AsrModelRepository? modelRepository;
  final Future<Map<String, String>> Function()? loadSpellingMap;

  @override
  State<RecitationCheckScreen> createState() => _RecitationCheckScreenState();
}

class _RecitationCheckScreenState extends State<RecitationCheckScreen> {
  late final RecitationAssessmentController _assessmentController;
  late final AsrModelRepository _modelRepository;
  AudioPlayer? _qariPlayer;

  List<Surah> _surahs = const [];
  List<AyahEntry> _ayahs = const [];
  int _selectedSurahNumber = 1;
  int _currentAyahIndex = 0;
  bool _isLoadingAyahs = true;
  String? _loadError;

  AsrModelStatus? _modelStatus;
  bool _isDownloadingModel = false;
  double? _downloadFraction;
  String? _downloadMessage;
  String? _downloadError;

  bool _isPlayingQari = false;
  String? _qariError;
  StreamSubscription<PlayerState>? _qariPlayerSub;

  @override
  void initState() {
    super.initState();
    _selectedSurahNumber = widget.initialSurahNumber;
    _modelRepository = widget.modelRepository ?? createAsrModelManager();
    _assessmentController = RecitationAssessmentController(
      runtime: widget.runtime ?? createAsrRuntime(),
      createCapture: widget.createCapture ?? MicrophoneCapture.new,
      createPlayback: widget.createPlayback,
      loadSpellingMap: widget.loadSpellingMap ?? loadAssessmentSpellingMap,
    );
    _initialize();
  }

  Future<void> _initialize() async {
    await Future.wait([
      _loadSurahsAndAyahs(
        surahNumber: widget.initialSurahNumber,
        targetAyahNumber: widget.initialAyahNumber,
      ),
      _refreshModelStatus(),
    ]);
  }

  Future<void> _loadSurahsAndAyahs({
    required int surahNumber,
    int targetAyahNumber = 1,
  }) async {
    setState(() {
      _isLoadingAyahs = true;
      _loadError = null;
    });
    try {
      final surahs = _surahs.isNotEmpty
          ? _surahs
          : await widget.readingRepository.getSurahs();
      final ayahs = await widget.readingRepository.getAyahsForSurah(surahNumber);
      if (!mounted) return;
      final targetIndex = ayahs.indexWhere(
        (item) => item.ayahNumber == targetAyahNumber,
      );
      setState(() {
        _surahs = surahs;
        _ayahs = ayahs;
        _selectedSurahNumber = surahNumber;
        _currentAyahIndex = targetIndex >= 0 ? targetIndex : 0;
        _isLoadingAyahs = false;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = '$error';
        _isLoadingAyahs = false;
      });
    }
  }

  Future<void> _refreshModelStatus() async {
    final status = await _modelRepository.checkStatus();
    if (!mounted) return;
    setState(() => _modelStatus = status);
  }

  Future<void> _downloadModel() async {
    if (_isDownloadingModel) return;
    setState(() {
      _isDownloadingModel = true;
      _downloadFraction = 0;
      _downloadMessage = 'Menyiapkan unduhan model resmi...';
      _downloadError = null;
    });
    try {
      await _modelRepository.downloadModel(
        onProgress: (fraction, message) {
          if (!mounted) return;
          setState(() {
            _downloadFraction = fraction;
            _downloadMessage = message;
          });
        },
      );
      await _assessmentController.resetModelAvailability();
      await _refreshModelStatus();
      if (!mounted) return;
      setState(() {
        _isDownloadingModel = false;
        _downloadFraction = null;
        _downloadMessage = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Model koreksi bacaan siap digunakan secara offline.',
          ),
        ),
      );
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _isDownloadingModel = false;
        _downloadFraction = null;
        _downloadMessage = null;
        _downloadError = '$error';
      });
    }
  }

  Future<void> _confirmDeleteModel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus model koreksi offline?'),
        content: const Text(
          'Menghapus model membebaskan ruang penyimpanan sekitar 36 MB. Anda dapat mengunduhnya kembali kapan saja.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _modelRepository.deleteModel();
    await _assessmentController.resetModelAvailability();
    await _refreshModelStatus();
  }

  AyahEntry? get _currentAyah =>
      _ayahs.isEmpty ? null : _ayahs[_currentAyahIndex];

  Surah? get _currentSurah {
    for (final surah in _surahs) {
      if (surah.id == _selectedSurahNumber) return surah;
    }
    return null;
  }

  Future<void> _goToAyahIndex(int index) async {
    if (index < 0 || index >= _ayahs.length || index == _currentAyahIndex) {
      return;
    }
    await _stopQariAudio();
    await _assessmentController.discardRecording();
    if (!mounted) return;
    setState(() {
      _currentAyahIndex = index;
      _qariError = null;
    });
  }

  Future<void> _openSurahPicker() async {
    if (_surahs.isEmpty) return;
    final selected = await showModalBottomSheet<Surah>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                'Pilih Surah',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: _surahs.length,
                itemBuilder: (context, index) {
                  final surah = _surahs[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.navy,
                      foregroundColor: AppColors.gold,
                      child: Text('${surah.id}'),
                    ),
                    title: Text(surah.nameIndonesian),
                    subtitle: Text('${surah.ayahCount} ayat'),
                    trailing: Text(
                      surah.nameArabic,
                      style: const TextStyle(
                        fontFamily: 'AmiriQuran',
                        fontSize: 20,
                      ),
                    ),
                    selected: surah.id == _selectedSurahNumber,
                    onTap: () => Navigator.of(context).pop(surah),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
    if (selected == null || !mounted) return;
    await _stopQariAudio();
    await _assessmentController.discardRecording();
    await _loadSurahsAndAyahs(surahNumber: selected.id);
  }

  Future<void> _toggleQariAudio() async {
    if (_isPlayingQari) {
      await _stopQariAudio();
      return;
    }
    final ayah = _currentAyah;
    if (ayah == null) return;
    setState(() => _qariError = null);
    try {
      final handler = QuranAudioHandler.instance;
      if (handler != null && handler.playbackState.value.playing) {
        await handler.pause();
      }
      final voices = await const VoiceCatalog().load();
      final selectedVoiceId = await widget.preferences.selectedVoiceId;
      final voice = voices.firstWhere(
        (entry) =>
            entry.id == selectedVoiceId &&
            entry.audioMode == VoiceAudioMode.ayah,
        orElse: () => voices.firstWhere(
          (entry) => entry.audioMode == VoiceAudioMode.ayah,
          orElse: () => voices.first,
        ),
      );
      final player = _ensureQariPlayer();
      await player.setUrl(VoiceAudioSource.urlFor(voice, ayah.globalNumber));
      await player.play();
    } on Object {
      if (!mounted) return;
      setState(() {
        _qariError =
            'Audio contoh qari belum dapat diputar. Periksa koneksi internet atau unduh audio ayat terlebih dahulu.';
      });
    }
  }

  AudioPlayer _ensureQariPlayer() {
    final existing = _qariPlayer;
    if (existing != null) return existing;
    final created = AudioPlayer();
    _qariPlayer = created;
    _qariPlayerSub = created.playerStateStream.listen((state) {
      if (!mounted) return;
      final playing =
          state.playing && state.processingState != ProcessingState.completed;
      if (playing != _isPlayingQari) {
        setState(() => _isPlayingQari = playing);
      }
    });
    return created;
  }

  Future<void> _stopQariAudio() async {
    if (_isPlayingQari) {
      await _qariPlayer?.stop();
    }
  }

  @override
  void dispose() {
    unawaited(_qariPlayerSub?.cancel());
    final player = _qariPlayer;
    if (player != null) {
      unawaited(player.dispose());
    }
    _assessmentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ayah = _currentAyah;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Koreksi bacaan'),
        actions: [
          if (_surahs.isNotEmpty)
            TextButton.icon(
              onPressed: _openSurahPicker,
              icon: const Icon(Icons.menu_book_rounded, size: 18),
              label: Text(
                _currentSurah?.nameIndonesian ?? 'Surah $_selectedSurahNumber',
              ),
            ),
        ],
      ),
      body: _buildBody(context, ayah),
    );
  }

  Widget _buildBody(BuildContext context, AyahEntry? ayah) {
    if (_isLoadingAyahs) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadError != null || ayah == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48),
              const SizedBox(height: 12),
              Text(
                _loadError ?? 'Data ayat tidak ditemukan.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () =>
                    _loadSurahsAndAyahs(surahNumber: _selectedSurahNumber),
                child: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
      );
    }

    return ListenableBuilder(
      listenable: _assessmentController,
      builder: (context, _) {
        final hidesText = _assessmentController.hidesTargetText;
        final scoredAlignment =
            _assessmentController.phase == AssessmentPhase.scored
            ? _assessmentController.attempt?.alignment
            : null;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            if (_modelStatus != null)
              _AsrModelStatusCard(
                status: _modelStatus!,
                isDownloading: _isDownloadingModel,
                progressFraction: _downloadFraction,
                progressMessage: _downloadMessage,
                errorMessage: _downloadError,
                onDownload: _downloadModel,
                onDelete: _confirmDeleteModel,
              ),
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.gold,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${ayah.surahNameIndonesian ?? _currentSurah?.nameIndonesian ?? 'Surah ${ayah.surahNumber}'} '
                            '${ayah.surahNumber}:${ayah.ayahNumber}',
                            style: const TextStyle(
                              color: AppColors.navy,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          tooltip: 'Ayat sebelumnya',
                          onPressed: _currentAyahIndex > 0
                              ? () => _goToAyahIndex(_currentAyahIndex - 1)
                              : null,
                          icon: const Icon(Icons.chevron_left_rounded),
                        ),
                        IconButton(
                          tooltip: 'Ayat berikutnya',
                          onPressed: _currentAyahIndex < _ayahs.length - 1
                              ? () => _goToAyahIndex(_currentAyahIndex + 1)
                              : null,
                          icon: const Icon(Icons.chevron_right_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (hidesText)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Mode Setoran aktif: teks ayat disembunyikan sementara Anda membaca dari hafalan.',
                          textAlign: TextAlign.center,
                        ),
                      )
                    else if (scoredAlignment != null &&
                        scoredAlignment.assessable)
                      HighlightedAyahText(
                        alignment: scoredAlignment,
                        fontSize: 26,
                      )
                    else
                      Text(
                        ayah.uthmaniText,
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.right,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontFamily: 'AmiriQuran',
                              height: 1.9,
                              fontSize: 26,
                            ),
                      ),
                    if (!hidesText && ayah.transliteration != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        ayah.transliteration!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                    if (!hidesText && ayah.indonesianTranslation != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        ayah.indonesianTranslation!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _assessmentController.isRecording
                              ? null
                              : _toggleQariAudio,
                          icon: Icon(
                            _isPlayingQari
                                ? Icons.stop_rounded
                                : Icons.volume_up_rounded,
                            size: 18,
                          ),
                          label: Text(
                            _isPlayingQari
                                ? 'Hentikan qari'
                                : 'Dengar contoh qari',
                          ),
                        ),
                      ],
                    ),
                    if (_qariError != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _qariError!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            AssessmentPanel(
              controller: _assessmentController,
              targetText: ayah.uthmaniText,
              showHighlightedAyah: false,
            ),
          ],
        );
      },
    );
  }
}

class _AsrModelStatusCard extends StatelessWidget {
  const _AsrModelStatusCard({
    required this.status,
    required this.isDownloading,
    required this.progressFraction,
    required this.progressMessage,
    required this.errorMessage,
    required this.onDownload,
    required this.onDelete,
  });

  final AsrModelStatus status;
  final bool isDownloading;
  final double? progressFraction;
  final String? progressMessage;
  final String? errorMessage;
  final VoidCallback onDownload;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (status.state == AsrModelInstallState.unsupportedPlatform) {
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Unduhan model koreksi offline khusus perangkat Android. Pada platform ini penilaian mengikuti ketersediaan engine bawaan.',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (status.isReady) {
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          leading: Icon(
            Icons.offline_pin_rounded,
            color: theme.colorScheme.primary,
          ),
          title: const Text('Model koreksi offline siap'),
          subtitle: Text(
            'Abdou/quran-asr-small (${status.sizeLabel}) terverifikasi SHA-256.',
          ),
          trailing: IconButton(
            tooltip: 'Hapus cache model',
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ),
      );
    }

    return Card(
      color: AppColors.navy,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.download_for_offline_rounded,
                  color: AppColors.gold,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Aktifkan koreksi kata otomatis (offline)',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: AppColors.parchment,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Unduh model resmi Abdou/quran-asr-small (${status.sizeLabel}, lisensi MIT) sekali saja agar bacaan Anda dapat dikoreksi kata per kata tanpa internet.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.parchment.withValues(alpha: 0.86),
              ),
            ),
            if (isDownloading) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: progressFraction,
                color: AppColors.gold,
                backgroundColor: AppColors.parchment.withValues(alpha: 0.2),
                semanticsLabel: 'Progres unduhan model koreksi',
              ),
              const SizedBox(height: 6),
              Text(
                progressMessage ?? 'Mengunduh model...',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.gold,
                ),
              ),
            ] else ...[
              if (errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  errorMessage!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFFFFCDD2),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.navy,
                  minimumSize: const Size(double.infinity, 48),
                ),
                onPressed: onDownload,
                icon: const Icon(Icons.download_rounded),
                label: Text('Unduh model resmi (${status.sizeLabel})'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
