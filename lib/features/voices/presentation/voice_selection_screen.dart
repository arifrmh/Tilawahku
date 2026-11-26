import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../core/preferences/app_preferences.dart';
import '../../download/data/audio_download_manager.dart';
import '../../download/data/audio_package_repository.dart';
import '../../player/data/quran_audio_handler.dart';
import '../../navigation/presentation/main_navigation_screen.dart';
import '../data/voice_catalog.dart';
import '../data/voice_preview_controller.dart';
import '../data/voice_repository.dart';
import 'qari_avatar.dart';

class VoiceSelectionScreen extends StatefulWidget {
  const VoiceSelectionScreen({
    super.key,
    required this.preferences,
    required this.onSetDarkMode,
    this.allowBack = false,
    this.previewController,
    this.isMainAudioPlaying,
    this.mainAudioPlayingStream,
  });

  final AppPreferences preferences;
  final ValueChanged<bool> onSetDarkMode;
  final bool allowBack;
  final VoicePreviewController? previewController;
  final bool Function()? isMainAudioPlaying;
  final Stream<bool>? mainAudioPlayingStream;

  @override
  State<VoiceSelectionScreen> createState() => _VoiceSelectionScreenState();
}

class _VoiceSelectionScreenState extends State<VoiceSelectionScreen> {
  final VoiceCatalog _catalog = const VoiceCatalog();
  final VoiceRepository _voiceRepository = VoiceRepository();
  final AudioDownloadManager _downloadManager = AudioDownloadManager.instance;
  final AudioPackageRepository _packageRepository = AudioPackageRepository();
  late final Future<List<Voice>> _voices = _catalog.load();
  late final VoicePreviewController _previewController;
  StreamSubscription<bool>? _mainPlaybackSubscription;
  String? _selectedVoiceId;
  bool _mainAudioPlaying = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _previewController =
        widget.previewController ?? VoicePreviewController(enabled: !kIsWeb);
    final mainHandler = QuranAudioHandler.instance;
    _mainAudioPlaying =
        widget.isMainAudioPlaying?.call() ??
        (mainHandler?.playbackState.value.playing ?? false);
    final mainPlaybackStream =
        widget.mainAudioPlayingStream ??
        mainHandler?.playbackState.map((state) => state.playing);
    _mainPlaybackSubscription = mainPlaybackStream?.listen(
      _handleMainAudioPlaying,
    );
    _loadSelectedVoice();
  }

  void _handleMainAudioPlaying(bool playing) {
    if (!mounted || playing == _mainAudioPlaying) return;
    setState(() => _mainAudioPlaying = playing);
    final preview = _previewController.state.value;
    if (playing &&
        (preview.status == VoicePreviewStatus.loading ||
            preview.status == VoicePreviewStatus.playing)) {
      unawaited(_stopPreviewForMainAudio());
    }
  }

  Future<void> _stopPreviewForMainAudio() async {
    try {
      await _previewController.stop();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghentikan preview: $error')),
        );
      }
    }
  }

  bool get _isMainAudioPlaying =>
      widget.isMainAudioPlaying?.call() ??
      (QuranAudioHandler.instance?.playbackState.value.playing ?? false);

  Future<void> _togglePreview(Voice voice) async {
    if (kIsWeb) return;
    if (_isMainAudioPlaying) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Preview tidak tersedia saat audio utama sedang diputar.',
          ),
        ),
      );
      return;
    }

    final preview = _previewController.state.value;
    if (preview.voiceId == voice.id &&
        (preview.status == VoicePreviewStatus.loading ||
            preview.status == VoicePreviewStatus.playing)) {
      try {
        await _previewController.stop();
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menghentikan preview: $error')),
          );
        }
      }
      return;
    }
    await _previewController.play(voice);
  }

  Future<void> _loadSelectedVoice() async {
    try {
      final selected = await widget.preferences.selectedVoiceId;
      if (mounted) setState(() => _selectedVoiceId = selected);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  Future<void> _continue() async {
    final voiceId = _selectedVoiceId;
    if (voiceId == null) return;

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final voices = await _voices;
      if (!mounted) return;
      final selectedVoice = voices.firstWhere((voice) => voice.id == voiceId);
      if (kIsWeb) {
        await _voiceRepository.save(selectedVoice);
        await widget.preferences.setSelectedVoiceId(voiceId);
        if (!mounted) return;
        _leaveSelection(voiceId);
        return;
      }

      if (selectedVoice.audioMode == VoiceAudioMode.surah) {
        await _voiceRepository.save(selectedVoice);
        await widget.preferences.setSelectedVoiceId(voiceId);
        if (!mounted) return;
        _leaveSelection(voiceId);
        return;
      }

      final previousVoiceId = await widget.preferences.selectedVoiceId;
      if (!mounted) return;
      if (previousVoiceId == voiceId) {
        await _voiceRepository.save(selectedVoice);
        if (!mounted) return;
        _leaveSelection(voiceId);
        return;
      }

      var selectedJuz = 1;
      final juzToDownload = await showDialog<int>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Unduh satu juz untuk offline?'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pilih satu juz audio per ayat untuk ${selectedVoice.name}. '
                  'Anda dapat mengunduh juz lain nanti dari menu Unduhan. '
                  'Gunakan Wi-Fi dan pastikan ruang penyimpanan cukup.',
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  initialValue: selectedJuz,
                  decoration: const InputDecoration(labelText: 'Pilih juz'),
                  items: List.generate(
                    30,
                    (index) => DropdownMenuItem(
                      value: index + 1,
                      child: Text('Juz ${index + 1}'),
                    ),
                  ),
                  onChanged: (juz) {
                    if (juz != null) {
                      setDialogState(() => selectedJuz = juz);
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Nanti'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(selectedJuz),
                child: const Text('Unduh juz ini'),
              ),
            ],
          ),
        ),
      );
      if (!mounted) return;
      if (juzToDownload == null) {
        await _voiceRepository.save(selectedVoice);
        await widget.preferences.setSelectedVoiceId(voiceId);
        if (!mounted) return;
        _leaveSelection(voiceId);
        return;
      }

      await _voiceRepository.save(selectedVoice);
      await widget.preferences.setSelectedVoiceId(voiceId);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      _leaveSelection(voiceId);
      unawaited(
        _startJuzDownload(
          voice: selectedVoice,
          juz: juzToDownload,
          messenger: messenger,
        ),
      );
    } catch (error) {
      if (mounted) {
        final message = error.toString().replaceFirst('Bad state: ', '');
        setState(() {
          _saving = false;
          _error = 'Gagal menyimpan pilihan suara: $message';
        });
      }
    }
  }

  Future<void> _startJuzDownload({
    required Voice voice,
    required int juz,
    required ScaffoldMessengerState messenger,
  }) async {
    try {
      final packages = await _packageRepository.getPackages(voice.id);
      final package = packages.firstWhere((item) => item.juz == juz);
      if (package.status == AudioPackageStatus.complete) {
        if (messenger.mounted) {
          messenger.showSnackBar(
            SnackBar(content: Text('Audio Juz $juz sudah tersedia.')),
          );
        }
        return;
      }

      final totalBytes = package.totalBytes > 0
          ? package.totalBytes
          : await _downloadManager.estimatePackageSize(
              voice: voice,
              juz: juz,
              sampleOnly: true,
            );
      await _downloadManager.downloadPackage(
        voice: voice,
        juz: juz,
        totalBytes: totalBytes,
      );
    } catch (error) {
      if (messenger.mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Unduhan Juz $juz gagal dimulai: $error')),
        );
      }
    }
  }

  void _leaveSelection(String voiceId) {
    if (widget.allowBack) {
      Navigator.of(context).pop(voiceId);
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => MainNavigationScreen(
            preferences: widget.preferences,
            onSetDarkMode: widget.onSetDarkMode,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _mainPlaybackSubscription?.cancel();
    unawaited(_previewController.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Pilih suara'),
      leading: widget.allowBack ? const BackButton() : null,
    ),
    body: FutureBuilder<List<Voice>>(
      future: _voices,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _VoiceMessage(
            message: 'Gagal membaca katalog suara: ${snapshot.error}',
            action: TextButton(
              onPressed: () => setState(() {}),
              child: const Text('Coba lagi'),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final voices = snapshot.data!;
        final theme = Theme.of(context);
        final colors = theme.colorScheme;
        return Column(
          children: [
            if (kIsWeb)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: _VoiceNoticeBanner(
                  icon: Icons.info_outline_rounded,
                  message:
                      'Pemilihan qari opsional. Pemutaran dan unduhan audio '
                      'tidak tersedia di Web preview.',
                ),
              ),
            if (!kIsWeb && _mainAudioPlaying)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: _VoiceNoticeBanner(
                  icon: Icons.volume_up_outlined,
                  message:
                      'Preview dinonaktifkan selama audio utama sedang diputar.',
                ),
              ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: colors.outlineVariant.withValues(alpha: 0.45),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: colors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.graphic_eq_rounded,
                            size: 20,
                            color: colors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pilih qari untuk menemani tilawah Anda.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Semua contoh suara memutar Al-Fatihah ayat 1.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colors.onSurface.withValues(
                                    alpha: 0.72,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final voice in voices)
                    _VoiceCard(
                      voice: voice,
                      selected: _selectedVoiceId == voice.id,
                      previewController: _previewController,
                      previewEnabled:
                          !kIsWeb &&
                          !_mainAudioPlaying &&
                          voice.status == VoiceStatus.active,
                      onPreview: () => _togglePreview(voice),
                      onSelect: voice.status == VoiceStatus.active
                          ? () => setState(() => _selectedVoiceId = voice.id)
                          : null,
                    ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        _error!,
                        style: TextStyle(color: colors.error),
                      ),
                    ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                border: Border(
                  top: BorderSide(
                    color: colors.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _selectedVoiceId == null || _saving
                          ? null
                          : _continue,
                      child: Text(_saving ? 'Menyimpan...' : 'Pilih suara'),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}

class _VoiceNoticeBanner extends StatelessWidget {
  const _VoiceNoticeBanner({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.secondaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _VoiceCard extends StatelessWidget {
  const _VoiceCard({
    required this.voice,
    required this.selected,
    required this.onSelect,
    required this.previewController,
    required this.previewEnabled,
    required this.onPreview,
  });

  final Voice voice;
  final bool selected;
  final VoidCallback? onSelect;
  final VoicePreviewController previewController;
  final bool previewEnabled;
  final VoidCallback onPreview;

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<VoicePreviewState>(
        valueListenable: previewController.state,
        builder: (context, previewState, _) =>
            _buildCard(context, previewState),
      );

  Widget _buildCard(BuildContext context, VoicePreviewState previewState) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final unavailable = voice.status != VoiceStatus.active;
    final isCurrentPreview = previewState.voiceId == voice.id;
    final isPreviewActive =
        isCurrentPreview &&
        (previewState.status == VoicePreviewStatus.playing ||
            previewState.status == VoicePreviewStatus.loading);
    final styleLabel = unavailable
        ? 'Segera hadir'
        : '${_capitalize(voice.style)} · ${voice.bitrateKbps} kbps';

    return Card(
      key: ValueKey('voice-selection-${voice.id}'),
      margin: const EdgeInsets.only(top: 10),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      color: selected
          ? colors.primary.withValues(alpha: 0.05)
          : colors.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected
              ? AppColors.gold
              : colors.outlineVariant.withValues(alpha: 0.45),
          width: selected ? 1.5 : 1.0,
        ),
      ),
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              QariAvatar(voice: voice, size: 54, selected: selected),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            voice.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (selected) ...[
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.check_circle_rounded,
                            size: 20,
                            color: AppColors.gold,
                            semanticLabel: 'Qari dipilih',
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: voice.audioMode == VoiceAudioMode.surah
                                ? colors.tertiaryContainer
                                : colors.secondaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            voice.audioMode == VoiceAudioMode.surah
                                ? 'Audio Per Surah'
                                : 'Audio Per Ayat',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colors.surfaceContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            styleLabel,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colors.onSurface.withValues(alpha: 0.78),
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (voice.audioMode == VoiceAudioMode.surah) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Memutar satu surah secara utuh. Pengulangan ayat '
                        'atau rentang ayat belum tersedia untuk sumber audio ini.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurface.withValues(alpha: 0.74),
                        ),
                      ),
                    ],
                    if (isCurrentPreview &&
                        previewState.status == VoicePreviewStatus.error) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Preview gagal: ${previewState.error}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (voice.audioMode == VoiceAudioMode.ayah) ...[
                const SizedBox(width: 8),
                DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isPreviewActive
                        ? AppColors.gold.withValues(alpha: 0.16)
                        : colors.primary.withValues(alpha: 0.08),
                  ),
                  child: IconButton(
                    key: ValueKey('voice-preview-${voice.id}'),
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    tooltip: isPreviewActive
                        ? 'Hentikan preview ${voice.name}'
                        : 'Dengarkan contoh ${voice.name}',
                    onPressed: previewEnabled ? onPreview : null,
                    color: isPreviewActive ? AppColors.gold : colors.primary,
                    icon:
                        isCurrentPreview &&
                            previewState.status == VoicePreviewStatus.loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            isCurrentPreview &&
                                    previewState.status ==
                                        VoicePreviewStatus.playing
                                ? Icons.stop_circle_outlined
                                : Icons.play_circle_outline_rounded,
                          ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

String _capitalize(String text) {
  if (text.isEmpty) return text;
  return '${text[0].toUpperCase()}${text.substring(1)}';
}

class _VoiceMessage extends StatelessWidget {
  const _VoiceMessage({required this.message, required this.action});

  final String message;
  final Widget action;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          action,
        ],
      ),
    ),
  );
}
