import 'dart:math' as math;

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../core/preferences/app_preferences.dart';
import '../../download/presentation/download_screen.dart';
import '../../player/data/quran_audio_handler.dart';
import '../data/reading_repository.dart';
import '../domain/juz_metadata.dart';
import 'bookmarks_screen.dart';
import 'reading_screen.dart';
import 'search_screen.dart';

const int _totalMushafPages = 604;

const List<({int surahNumber, String label})> _quickSurahShortcuts = [
  (surahNumber: 18, label: 'Al-Kahfi'),
  (surahNumber: 36, label: 'Yasin'),
  (surahNumber: 55, label: 'Ar-Rahman'),
  (surahNumber: 56, label: "Al-Waqi'ah"),
  (surahNumber: 67, label: 'Al-Mulk'),
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.preferences,
    this.repository,
    this.reloadSignal,
  });

  final AppPreferences preferences;
  final ReadingRepository? repository;
  final ValueListenable<int>? reloadSignal;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final ReadingRepository _repository;
  late Future<List<Surah>> _surahs;
  String? _voiceId;
  String? _loadError;
  AyahEntry? _lastProgress;
  bool _loadingProgress = false;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? ReadingRepository();
    _surahs = _repository.getSurahs();
    _loadVoice();
    widget.reloadSignal?.addListener(_reloadFromShell);
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reloadSignal == widget.reloadSignal) return;
    oldWidget.reloadSignal?.removeListener(_reloadFromShell);
    widget.reloadSignal?.addListener(_reloadFromShell);
  }

  @override
  void dispose() {
    widget.reloadSignal?.removeListener(_reloadFromShell);
    super.dispose();
  }

  void _reloadFromShell() => _loadVoice();

  Future<void> _loadVoice() async {
    try {
      final voiceId = await widget.preferences.selectedVoiceId;
      if (!mounted) return;
      setState(() {
        _voiceId = voiceId;
        _loadError = null;
      });
      await _loadProgress(voiceId);
    } catch (error) {
      if (mounted) setState(() => _loadError = error.toString());
    }
  }

  Future<void> _loadProgress(String? voiceId) async {
    if (mounted) {
      setState(() {
        _loadingProgress = voiceId != null;
        if (voiceId == null) _lastProgress = null;
      });
    }
    if (voiceId == null) return;
    try {
      final progress = await _repository.getProgress(voiceId);
      if (!mounted) return;
      setState(() {
        _lastProgress = progress;
        _loadingProgress = false;
        _loadError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingProgress = false;
        _loadError = 'Gagal memuat progres: $error';
      });
    }
  }

  void _reloadSurahs() {
    setState(() {
      _surahs = _repository.getSurahs();
    });
  }

  Future<void> _continueLast() async {
    final voiceId = _voiceId;
    if (voiceId == null) {
      await _openReading(surahNumber: 1);
      return;
    }
    try {
      await _loadProgress(voiceId);
      if (!mounted) return;
      final position = _lastProgress;
      if (position == null) {
        await _openReading(surahNumber: 1);
        return;
      }
      await _openReading(
        surahNumber: position.surahNumber,
        startingAyah: position.ayahNumber,
      );
    } catch (error) {
      if (mounted) _showMessage('Gagal memuat progres: $error');
    }
  }

  Future<void> _toggleCurrentPlayback() async {
    final handler = QuranAudioHandler.instance;
    if (handler == null) return;
    try {
      if (handler.playbackState.value.playing) {
        await handler.pause();
      } else {
        await handler.play();
      }
    } catch (error) {
      if (mounted) _showMessage('Gagal mengendalikan audio: $error');
    }
  }

  Future<void> _openPlayingAyah() async {
    final handler = QuranAudioHandler.instance;
    final item = handler?.mediaItem.value;
    final surahNumber = item?.extras?['surahNumber'];
    final ayahNumber = item?.extras?['ayahNumber'];
    if (surahNumber is! int || ayahNumber is! int) {
      _showMessage('Informasi ayat yang sedang diputar tidak tersedia.');
      return;
    }
    await _openReading(surahNumber: surahNumber, startingAyah: ayahNumber);
  }

  Future<void> _openReading({
    int? surahNumber,
    int? startingAyah,
    int? juzNumber,
    int? pageNumber,
  }) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ReadingScreen(
          repository: _repository,
          preferences: widget.preferences,
          surahNumber: surahNumber,
          startingAyah: startingAyah,
          juzNumber: juzNumber,
          pageNumber: pageNumber,
        ),
      ),
    );
    if (mounted && _voiceId != null) await _loadProgress(_voiceId);
  }

  void _openSearch() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => SearchScreen(
          repository: _repository,
          preferences: widget.preferences,
        ),
      ),
    );
  }

  Future<void> _openJumpToPage() async {
    final page = await showDialog<int>(
      context: context,
      builder: (_) => const _JumpToPageDialog(),
    );
    if (page == null || !mounted) return;
    await _openReading(pageNumber: page);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 2,
    child: Scaffold(
      appBar: AppBar(
        title: const Text(
          'Al-Qur’an',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Lompat ke halaman',
            onPressed: _openJumpToPage,
            icon: const Icon(Icons.find_in_page_outlined),
          ),
          IconButton(
            tooltip: 'Bookmark ayat',
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (_) => BookmarksScreen(
                  repository: _repository,
                  preferences: widget.preferences,
                ),
              ),
            ),
            icon: const Icon(Icons.bookmarks_outlined),
          ),
          IconButton(
            tooltip: 'Unduhan audio',
            onPressed: kIsWeb
                ? () => _showMessage(
                    'Audio belum tersedia secara lokal di Web preview. '
                    'Unduhan audio tidak diaktifkan di browser.',
                  )
                : () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          DownloadScreen(preferences: widget.preferences),
                    ),
                  ),
            icon: const Icon(Icons.download_rounded),
          ),
        ],
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (kIsWeb) ...[
                    const _WebPreviewNotice(),
                    const SizedBox(height: 12),
                  ],
                  _HomePlaybackSection(
                    handler: QuranAudioHandler.instance,
                    voiceId: _voiceId,
                    progress: _lastProgress,
                    isLoading: _loadingProgress,
                    error: _loadError,
                    onContinue: _continueLast,
                    onOpenReading: _openPlayingAyah,
                    onTogglePlayback: _toggleCurrentPlayback,
                  ),
                  const SizedBox(height: 12),
                  _SearchBarTrigger(onTap: _openSearch),
                  const SizedBox(height: 12),
                  _QuickSurahRow(
                    onSelectSurah: (surahNumber) =>
                        _openReading(surahNumber: surahNumber),
                  ),
                ],
              ),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _SegmentedTabBarHeaderDelegate(),
          ),
        ],
        body: TabBarView(
          children: [
            _SurahList(
              surahs: _surahs,
              onRetry: _reloadSurahs,
              onSelected: (surah) => _openReading(surahNumber: surah.id),
            ),
            _JuzList(onSelected: (juz) => _openReading(juzNumber: juz)),
          ],
        ),
      ),
    ),
  );
}

class _SegmentedTabBarHeaderDelegate extends SliverPersistentHeaderDelegate {
  @override
  double get minExtent => 64;

  @override
  double get maxExtent => 64;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      color: theme.scaffoldBackgroundColor,
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      child: Container(
        height: 48,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
          ),
        ),
        child: TabBar(
          dividerColor: Colors.transparent,
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: BoxDecoration(
            color: isDark ? AppColors.gold : AppColors.navy,
            borderRadius: BorderRadius.circular(10),
          ),
          labelColor: isDark ? AppColors.navy : AppColors.parchment,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700),
          unselectedLabelColor: theme.colorScheme.onSurface.withValues(
            alpha: 0.78,
          ),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Surah'),
            Tab(text: 'Juz'),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _SegmentedTabBarHeaderDelegate oldDelegate) =>
      false;
}

class _HomePlaybackSection extends StatelessWidget {
  const _HomePlaybackSection({
    required this.handler,
    required this.voiceId,
    required this.progress,
    required this.isLoading,
    required this.error,
    required this.onContinue,
    required this.onOpenReading,
    required this.onTogglePlayback,
  });

  final QuranAudioHandler? handler;
  final String? voiceId;
  final AyahEntry? progress;
  final bool isLoading;
  final String? error;
  final VoidCallback onContinue;
  final VoidCallback onOpenReading;
  final VoidCallback onTogglePlayback;

  @override
  Widget build(BuildContext context) => StreamBuilder<MediaItem?>(
    stream: handler?.mediaItem,
    initialData: handler?.mediaItem.value,
    builder: (context, snapshot) {
      final item = snapshot.data;
      if (handler == null ||
          voiceId == null ||
          item == null ||
          handler!.queue.value.isEmpty) {
        return _ContinueCard(
          onPressed: onContinue,
          voiceId: voiceId,
          progress: progress,
          isLoading: isLoading,
          error: error,
        );
      }
      return _NowPlayingCard(
        handler: handler!,
        item: item,
        onOpenReading: onOpenReading,
        onTogglePlayback: onTogglePlayback,
      );
    },
  );
}

class _NowPlayingCard extends StatelessWidget {
  const _NowPlayingCard({
    required this.handler,
    required this.item,
    required this.onOpenReading,
    required this.onTogglePlayback,
  });

  final QuranAudioHandler handler;
  final MediaItem item;
  final VoidCallback onOpenReading;
  final VoidCallback onTogglePlayback;

  @override
  Widget build(BuildContext context) => Card(
    color: AppColors.blue,
    margin: EdgeInsets.zero,
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onOpenReading,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 10),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.navy,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.graphic_eq_rounded,
                    color: AppColors.gold,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.parchment,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${item.artist ?? 'Qari'} · '
                        '${item.album ?? 'Tilawahku'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.parchment.withValues(alpha: 0.78),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                StreamBuilder<PlaybackState>(
                  stream: handler.playbackState,
                  initialData: handler.playbackState.value,
                  builder: (context, snapshot) {
                    final playing = snapshot.data?.playing ?? false;
                    return IconButton.filled(
                      tooltip: playing ? 'Jeda audio' : 'Putar audio',
                      onPressed: onTogglePlayback,
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: AppColors.navy,
                      ),
                      icon: Icon(
                        playing
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                      ),
                    );
                  },
                ),
              ],
            ),
            StreamBuilder<Duration?>(
              stream: handler.durationStream,
              initialData: handler.duration,
              builder: (context, durationSnapshot) {
                final duration = durationSnapshot.data;
                if (duration == null || duration <= Duration.zero) {
                  return const SizedBox(height: 4);
                }
                return StreamBuilder<Duration>(
                  stream: handler.positionStream,
                  initialData: handler.position,
                  builder: (context, positionSnapshot) {
                    final progress =
                        (positionSnapshot.data!.inMilliseconds /
                                duration.inMilliseconds)
                            .clamp(0.0, 1.0);
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 3,
                        backgroundColor: AppColors.navy,
                        color: AppColors.gold,
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    ),
  );
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({
    required this.onPressed,
    required this.voiceId,
    required this.progress,
    required this.isLoading,
    required this.error,
  });

  final VoidCallback onPressed;
  final String? voiceId;
  final AyahEntry? progress;
  final bool isLoading;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final currentProgress = progress;
    final pageFraction = currentProgress == null
        ? null
        : (currentProgress.pageNumber / _totalMushafPages).clamp(0.0, 1.0);

    return Card(
      color: AppColors.navy,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColors.gold.withValues(alpha: 0.45)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.blue, AppColors.navy],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Align(
                  alignment: Alignment.topRight,
                  child: SizedBox(
                    width: 120,
                    height: 120,
                    child: CustomPaint(
                      painter: _OctagramWatermarkPainter(
                        color: AppColors.gold.withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentProgress == null
                                  ? 'Mushaf 30 juz'
                                  : 'Tilawah terakhir',
                              style: const TextStyle(
                                color: AppColors.gold,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              currentProgress == null
                                  ? 'Mulai Membaca'
                                  : 'Lanjutkan Terakhir',
                              style: const TextStyle(
                                color: AppColors.parchment,
                                fontWeight: FontWeight.w700,
                                fontSize: 19,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              error ??
                                  (isLoading
                                      ? 'Memuat progres tilawah...'
                                      : currentProgress != null
                                      ? '${currentProgress.surahNameIndonesian ?? 'Surah ${currentProgress.surahNumber}'}'
                                            ' ${currentProgress.surahNumber}:${currentProgress.ayahNumber}'
                                            ' · Juz ${currentProgress.juzNumber}'
                                            ' · Hal. ${currentProgress.pageNumber}/$_totalMushafPages'
                                      : voiceId == null
                                      ? 'Audio belum tersedia secara lokal · Anda tetap bisa membaca'
                                      : 'Belum ada progres · mulai dari Al-Fatihah'),
                              style: TextStyle(
                                color: AppColors.parchment.withValues(
                                  alpha: 0.9,
                                ),
                                fontSize: 13,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.gold,
                        foregroundColor: AppColors.navy,
                        child: Icon(
                          currentProgress == null
                              ? Icons.menu_book_rounded
                              : Icons.play_arrow_rounded,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                  if (currentProgress != null &&
                      currentProgress.uthmaniText.trim().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.parchment.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.parchment.withValues(alpha: 0.14),
                        ),
                      ),
                      child: Text(
                        currentProgress.uthmaniText.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontFamily: 'AmiriQuran',
                          fontSize: 18,
                          height: 1.6,
                          color: AppColors.parchment,
                        ),
                      ),
                    ),
                  ],
                  if (pageFraction != null) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: pageFraction,
                        minHeight: 5,
                        color: AppColors.gold,
                        backgroundColor: AppColors.parchment.withValues(
                          alpha: 0.2,
                        ),
                        semanticsLabel: 'Progres halaman mushaf',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OctagramWatermarkPainter extends CustomPainter {
  const _OctagramWatermarkPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    final center = Offset(size.width * 0.72, size.height * 0.28);
    final side = size.width * 0.62;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.drawRect(
      Rect.fromCenter(center: Offset.zero, width: side, height: side),
      paint,
    );
    canvas.rotate(math.pi / 4);
    canvas.drawRect(
      Rect.fromCenter(center: Offset.zero, width: side, height: side),
      paint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _OctagramWatermarkPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _SearchBarTrigger extends StatelessWidget {
  const _SearchBarTrigger({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.search_rounded,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Cari surah, ayat, atau terjemahan...',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
                  ),
                ),
              ),
              Icon(
                Icons.tune_rounded,
                size: 18,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.56),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickSurahRow extends StatelessWidget {
  const _QuickSurahRow({required this.onSelectSurah});

  final ValueChanged<int> onSelectSurah;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Akses cepat surah pilihan',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _quickSurahShortcuts.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final item = _quickSurahShortcuts[index];
              return ActionChip(
                avatar: CircleAvatar(
                  backgroundColor: theme.colorScheme.primary.withValues(
                    alpha: 0.14,
                  ),
                  child: Text(
                    '${item.surahNumber}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                label: Text(item.label),
                onPressed: () => onSelectSurah(item.surahNumber),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MushafNumberBadge extends StatelessWidget {
  const _MushafNumberBadge({required this.number});

  final int number;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return SizedBox(
      width: 42,
      height: 42,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.rotate(
            angle: math.pi / 4,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: color.withValues(alpha: 0.55),
                  width: 1.2,
                ),
              ),
            ),
          ),
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: color.withValues(alpha: 0.35),
                width: 1.0,
              ),
            ),
          ),
          Text(
            '$number',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 13,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _WebPreviewNotice extends StatelessWidget {
  const _WebPreviewNotice();

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Web preview: teks, bookmark, navigasi, dan preferensi tersedia. '
              'Audio tidak tersedia secara lokal; pemutaran dan unduhan '
              'dinonaktifkan di browser.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    ),
  );
}

class _JuzList extends StatelessWidget {
  const _JuzList({required this.onSelected});

  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: quranJuzMetadata.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final info = quranJuzMetadata[index];
        return Card(
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => onSelected(info.number),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 68),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    _MushafNumberBadge(number: info.number),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Juz ${info.number}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            info.rangeLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.72,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        info.pageLabel,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.56,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SurahList extends StatelessWidget {
  const _SurahList({
    required this.surahs,
    required this.onRetry,
    required this.onSelected,
  });

  final Future<List<Surah>> surahs;
  final VoidCallback onRetry;
  final ValueChanged<Surah> onSelected;

  @override
  Widget build(BuildContext context) => FutureBuilder<List<Surah>>(
    future: surahs,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Gagal memuat daftar surah: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
                TextButton(onPressed: onRetry, child: const Text('Coba lagi')),
              ],
            ),
          ),
        );
      }
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      final items = snapshot.data!;
      if (items.isEmpty) {
        return const _EmptyContent(
          message:
              'Daftar surah akan tersedia setelah database Qur’an dipasang.',
        );
      }
      final theme = Theme.of(context);
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final surah = items[index];
          return Card(
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => onSelected(surah),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 68),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      _MushafNumberBadge(number: surah.id),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              surah.nameIndonesian,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${surah.ayahCount} ayat',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.72,
                                ),
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        surah.nameArabic,
                        textDirection: TextDirection.rtl,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontFamily: 'AmiriQuran',
                          fontSize: 22,
                          height: 1.4,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

class _JumpToPageDialog extends StatefulWidget {
  const _JumpToPageDialog();

  @override
  State<_JumpToPageDialog> createState() => _JumpToPageDialogState();
}

class _JumpToPageDialogState extends State<_JumpToPageDialog> {
  final TextEditingController _controller = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final parsed = int.tryParse(_controller.text.trim());
    if (parsed == null || parsed < 1 || parsed > _totalMushafPages) {
      setState(() {
        _errorText = 'Masukkan nomor halaman antara 1 sampai $_totalMushafPages.';
      });
      return;
    }
    Navigator.of(context).pop(parsed);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Lompat ke halaman'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Masukkan nomor halaman mushaf (1 sampai $_totalMushafPages).',
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          onSubmitted: (_) => _submit(),
          decoration: InputDecoration(
            labelText: 'Nomor halaman',
            hintText: '1 - $_totalMushafPages',
            errorText: _errorText,
            border: const OutlineInputBorder(),
          ),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Batal'),
      ),
      FilledButton(onPressed: _submit, child: const Text('Buka')),
    ],
  );
}

class _EmptyContent extends StatelessWidget {
  const _EmptyContent({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.menu_book_outlined, size: 48, color: AppColors.gold),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}
