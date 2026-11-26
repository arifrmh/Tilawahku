import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../core/preferences/app_preferences.dart';
import '../../memorization/data/memorization_repository.dart';
import '../../reading/data/reading_repository.dart';
import '../../tajwid/data/tajwid_repository.dart';
import '../../tajwid/domain/tajwid_models.dart';
import '../../tasbih/domain/tasbih_models.dart';
import '../data/reading_stats_repository.dart';
import '../domain/reading_stats_models.dart';

class ReadingStatsScreen extends StatefulWidget {
  const ReadingStatsScreen({
    super.key,
    this.repository,
    this.preferences,
    this.readingRepository,
    this.memorizationRepository,
    this.tajwidRepository,
  });

  final ReadingStatsRepository? repository;
  final AppPreferences? preferences;
  final ReadingRepository? readingRepository;
  final MemorizationRepository? memorizationRepository;
  final TajwidRepository? tajwidRepository;

  @override
  State<ReadingStatsScreen> createState() => _ReadingStatsScreenState();
}

class _ReadingStatsScreenState extends State<ReadingStatsScreen> {
  late final ReadingStatsRepository _repository;
  ReadingStatsSnapshot? _snapshot;
  Object? _error;
  bool _isLoading = true;
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    _repository =
        widget.repository ??
        ReadingStatsRepository(
          preferences: widget.preferences,
          readingRepository: widget.readingRepository,
          memorizationRepository: widget.memorizationRepository,
          tajwidRepository: widget.tajwidRepository,
        );
    _load();
  }

  Future<void> _load() async {
    final generation = ++_loadGeneration;
    if (_snapshot == null) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    try {
      final data = await _repository.loadSnapshot();
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _snapshot = data;
        _error = null;
        _isLoading = false;
      });
    } on Object catch (error) {
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _error = error;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Statistik membaca'),
      actions: [
        IconButton(
          tooltip: 'Muat ulang statistik',
          onPressed: _isLoading ? null : _load,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    ),
    body: _buildBody(context),
  );

  Widget _buildBody(BuildContext context) {
    if (_isLoading && _snapshot == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _snapshot == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48),
              const SizedBox(height: 12),
              const Text(
                'Statistik membaca tidak dapat dimuat.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text('$_error', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              TextButton(onPressed: _load, child: const Text('Coba lagi')),
            ],
          ),
        ),
      );
    }

    final data = _snapshot!;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _ReadingOverviewCard(snapshot: data),
          const SizedBox(height: 16),
          Text(
            'Ringkasan hafalan',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          _MemorizationKpiGrid(snapshot: data),
          const SizedBox(height: 16),
          _WeeklyActivityCard(snapshot: data),
          const SizedBox(height: 16),
          Text(
            'Aktivitas ibadah lainnya',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          _TajwidSummaryCard(progress: data.tajwidProgress),
          _TasbihSummaryCard(state: data.tasbihState),
          const SizedBox(height: 4),
          const _LocalDataNoteCard(),
        ],
      ),
    );
  }
}

class _ReadingOverviewCard extends StatelessWidget {
  const _ReadingOverviewCard({required this.snapshot});

  final ReadingStatsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final lastRead = snapshot.lastRead;
    final pagePercent = (snapshot.pageProgress * 100).round();
    final surahTitle = lastRead == null
        ? null
        : '${lastRead.surahNameIndonesian ?? 'Surah ${lastRead.surahNumber}'} '
              '${lastRead.surahNumber}:${lastRead.ayahNumber}';

    return Card(
      color: AppColors.navy,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.menu_book_rounded,
                  color: AppColors.gold,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Posisi bacaan terakhir',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.gold,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (lastRead == null) ...[
              Text(
                'Belum ada catatan bacaan',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.parchment,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Buka tab Al-Qur\'an dan baca ayat agar posisi terakhir tercatat di perangkat ini.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.parchment.withValues(alpha: 0.85),
                ),
              ),
            ] else ...[
              Text(
                surahTitle!,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.parchment,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Juz ${lastRead.juzNumber} dari $totalQuranJuz, '
                'Halaman ${lastRead.pageNumber} dari $totalMushafPages',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.parchment.withValues(alpha: 0.88),
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: snapshot.pageProgress,
                  minHeight: 8,
                  color: AppColors.gold,
                  backgroundColor: AppColors.parchment.withValues(alpha: 0.2),
                  semanticsLabel: 'Progres halaman mushaf',
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Ayat ${lastRead.globalNumber} dari $totalQuranAyahs',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.parchment.withValues(alpha: 0.85),
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  Text(
                    '$pagePercent% mushaf',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.gold,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Divider(color: AppColors.parchment.withValues(alpha: 0.2)),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.bookmark_rounded,
                  color: AppColors.gold,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Ayat ditandai: ${snapshot.bookmarkCount} ayat',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.parchment,
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MemorizationKpiGrid extends StatelessWidget {
  const _MemorizationKpiGrid({required this.snapshot});

  final ReadingStatsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final masteredLabel = snapshot.totalProgramAyahs == 0
        ? '0 ayat'
        : '${snapshot.masteredAyahs}/${snapshot.totalProgramAyahs}';
    final streakLabel = '${snapshot.activeStreakDays} hari';

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                icon: Icons.library_books_outlined,
                label: 'Program aktif',
                value: '${snapshot.programCount}',
                detail: snapshot.programCount == 0
                    ? 'Belum ada program'
                    : 'Program hafalan',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _KpiCard(
                icon: Icons.verified_outlined,
                label: 'Ayat dikuasai',
                value: masteredLabel,
                detail: snapshot.totalProgramAyahs == 0
                    ? 'Mulai program hafalan'
                    : '${(snapshot.masteryProgress * 100).round()}% target program',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                icon: Icons.history_rounded,
                label: 'Total sesi',
                value: '${snapshot.totalSessions}',
                detail: '${snapshot.last7DaysSessions} sesi 7 hari terakhir',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _KpiCard(
                icon: Icons.local_fire_department_outlined,
                label: 'Hari aktif beruntun',
                value: streakLabel,
                detail: snapshot.activeStreakDays == 0
                    ? 'Belum aktif hari ini'
                    : 'Berdasarkan sesi hafalan',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.detail,
  });

  final IconData icon;
  final String label;
  final String value;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: colors.primary),
            const SizedBox(height: 8),
            Text(label, style: theme.textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              detail,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurface.withValues(alpha: 0.72),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyActivityCard extends StatelessWidget {
  const _WeeklyActivityCard({required this.snapshot});

  final ReadingStatsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final newColor = isDark ? AppColors.gold : AppColors.navy;
    final repeatColor = isDark
        ? AppColors.parchment.withValues(alpha: 0.65)
        : AppColors.gold;
    final maxValue = snapshot.last7Days.fold<int>(
      0,
      (current, item) => math.max(current, item.totalPracticed),
    );

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aktivitas hafalan 7 hari terakhir',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              snapshot.last7DaysTotalPracticed == 0
                  ? 'Belum ada sesi latihan hafalan dalam 7 hari terakhir.'
                  : 'Total ${snapshot.last7DaysTotalPracticed} ayat dilatih '
                        '(${snapshot.last7DaysNewAyahs} baru, '
                        '${snapshot.last7DaysRepeatedAyahs} pengulangan).',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.78),
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 148,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final day in snapshot.last7Days)
                    Expanded(
                      child: _DayBarColumn(
                        day: day,
                        maxValue: maxValue,
                        newColor: newColor,
                        repeatColor: repeatColor,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _ChartLegendItem(color: newColor, label: 'Ayat baru'),
                _ChartLegendItem(color: repeatColor, label: 'Pengulangan'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DayBarColumn extends StatelessWidget {
  const _DayBarColumn({
    required this.day,
    required this.maxValue,
    required this.newColor,
    required this.repeatColor,
  });

  final DailyActivityStat day;
  final int maxValue;
  final Color newColor;
  final Color repeatColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const maxBarHeight = 84.0;
    final total = day.totalPracticed;
    final totalHeight = maxValue == 0 || total == 0
        ? 4.0
        : math.max(10.0, (total / maxValue) * maxBarHeight);
    final newHeight = total == 0 ? 0.0 : totalHeight * (day.newAyahs / total);
    final repeatHeight = total == 0 ? 0.0 : totalHeight - newHeight;
    final emptyTrackColor = theme.colorScheme.onSurface.withValues(alpha: 0.16);

    return Semantics(
      label:
          '${day.shortLabel} ${day.dateLabel}: $total ayat dilatih, '
          '${day.newAyahs} ayat baru, ${day.repeatedAyahs} pengulangan',
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '$total',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: total > 0 ? FontWeight.w700 : FontWeight.w500,
                  color: total > 0
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: maxBarHeight,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: total == 0
                        ? Container(
                            width: 22,
                            height: 4,
                            color: emptyTrackColor,
                          )
                        : SizedBox(
                            width: 22,
                            height: totalHeight,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (repeatHeight > 0)
                                  Container(
                                    width: 22,
                                    height: repeatHeight,
                                    color: repeatColor,
                                  ),
                                if (newHeight > 0)
                                  Container(
                                    width: 22,
                                    height: newHeight,
                                    color: newColor,
                                  ),
                              ],
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                day.shortLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                day.dateLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChartLegendItem extends StatelessWidget {
  const _ChartLegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
      const SizedBox(width: 6),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ],
  );
}

class _TajwidSummaryCard extends StatelessWidget {
  const _TajwidSummaryCard({required this.progress});

  final TajwidQuizProgress progress;

  @override
  Widget build(BuildContext context) {
    final bestPercent = (progress.bestScoreFraction * 100).round();
    final subtitle = progress.completedAttempts == 0
        ? 'Belum ada kuis Tajwid yang diselesaikan.'
        : '${progress.completedAttempts} kuis selesai, skor terbaik $bestPercent%, '
              '${progress.totalCorrectAnswers} dari ${progress.totalAnsweredQuestions} jawaban benar.';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(Icons.school_outlined),
        title: const Text('Latihan Tajwid'),
        subtitle: Text(subtitle),
      ),
    );
  }
}

class _TasbihSummaryCard extends StatelessWidget {
  const _TasbihSummaryCard({required this.state});

  final TasbihState state;

  @override
  Widget build(BuildContext context) {
    final subtitle = state.totalCount == 0
        ? 'Belum ada hitungan tasbih tercatat.'
        : '${state.preset.title}: ${state.completedRounds} putaran selesai, '
              'total ${state.totalCount} hitungan.';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(Icons.touch_app_outlined),
        title: const Text('Tasbih digital'),
        subtitle: Text(subtitle),
      ),
    );
  }
}

class _LocalDataNoteCard extends StatelessWidget {
  const _LocalDataNoteCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 18,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Seluruh statistik dihitung langsung dari catatan lokal di perangkat ini tanpa akun dan tanpa perkiraan durasi baca.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.78),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
