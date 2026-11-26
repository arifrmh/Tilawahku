import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../core/preferences/app_preferences.dart';
import '../../about/presentation/about_screen.dart';
import '../../asmaul_husna/presentation/asmaul_husna_screen.dart';
import '../../assessment/presentation/recitation_check_screen.dart';
import '../../doa_dzikir/presentation/doa_dzikir_screen.dart';
import '../../hijri/presentation/hijri_calendar_screen.dart';
import '../../islamic_figures/presentation/islamic_figures_screen.dart';
import '../../kajian/data/kajian_audio_playback.dart';
import '../../kajian/data/kajian_repository.dart';
import '../../kajian/presentation/kajian_list_screen.dart';
import '../../memorization/data/memorization_repository.dart';
import '../../memorization/domain/memorization_models.dart';
import '../../memorization/presentation/memorization_home_screen.dart';
import '../../prayer/data/prayer_repository.dart';
import '../../prayer/presentation/prayer_times_screen.dart';
import '../../qibla/presentation/qibla_screen.dart';
import '../../quotes_stories/presentation/quotes_stories_screen.dart';
import '../../reading/data/reading_repository.dart';
import '../../reading/presentation/home_screen.dart';
import '../../reading/presentation/reading_screen.dart';
import '../../reading_stats/presentation/reading_stats_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../tajwid/data/tajwid_repository.dart';
import '../../tajwid/presentation/tajwid_home_screen.dart';
import '../../tasbih/presentation/tasbih_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({
    super.key,
    required this.preferences,
    required this.onSetDarkMode,
    this.readingRepository,
    this.memorizationRepository,
    this.tajwidRepository,
    this.prayerRepository,
    this.kajianRepository,
    this.kajianPlayback,
  });

  final AppPreferences preferences;
  final ValueChanged<bool> onSetDarkMode;
  final ReadingRepository? readingRepository;
  final MemorizationRepository? memorizationRepository;
  final TajwidRepository? tajwidRepository;
  final PrayerRepository? prayerRepository;
  final KajianRepository? kajianRepository;
  final KajianAudioPlayback? kajianPlayback;

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late final ReadingRepository _readingRepository;
  late final MemorizationRepository _memorizationRepository;
  late final TajwidRepository _tajwidRepository;
  late final PrayerRepository _prayerRepository;
  final ValueNotifier<int> _reloadSignal = ValueNotifier(0);
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _readingRepository = widget.readingRepository ?? ReadingRepository();
    _memorizationRepository =
        widget.memorizationRepository ??
        MemorizationRepository(readingRepository: _readingRepository);
    _tajwidRepository = widget.tajwidRepository ?? TajwidRepository();
    _prayerRepository = widget.prayerRepository ?? PrayerRepository();
  }

  Future<void> _openPrayerTimes() => Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => PrayerTimesScreen(repository: _prayerRepository),
    ),
  );

  Future<void> _openQibla() => Navigator.of(
    context,
  ).push<void>(MaterialPageRoute<void>(builder: (_) => const QiblaScreen()));

  Future<void> _openHijriCalendar() => Navigator.of(context).push<void>(
    MaterialPageRoute<void>(builder: (_) => const HijriCalendarScreen()),
  );

  Future<void> _openAsmaulHusna() => Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => AsmaulHusnaScreen(
        preferences: widget.preferences,
        readingRepository: _readingRepository,
      ),
    ),
  );

  Future<void> _openQuotesStories() => Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => QuotesStoriesScreen(preferences: widget.preferences),
    ),
  );

  Future<void> _openIslamicFigures() => Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => IslamicFiguresScreen(preferences: widget.preferences),
    ),
  );

  Future<void> _openKajian() => Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => KajianListScreen(
        preferences: widget.preferences,
        repository: widget.kajianRepository,
        playback: widget.kajianPlayback,
      ),
    ),
  );

  Future<void> _openMemorization() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => MemorizationHomeScreen(
          repository: _memorizationRepository,
          readingRepository: _readingRepository,
        ),
      ),
    );
    if (!mounted) return;
    _reloadSignal.value++;
  }

  Future<void> _openTajwid() => Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => TajwidHomeScreen(
        repository: _tajwidRepository,
        readingRepository: _readingRepository,
      ),
    ),
  );

  Future<void> _openTasbih() => Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => TasbihScreen(preferences: widget.preferences),
    ),
  );

  Future<void> _openDoaDzikir() => Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => DoaDzikirScreen(preferences: widget.preferences),
    ),
  );

  Future<void> _openReadingStats() => Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => ReadingStatsScreen(
        preferences: widget.preferences,
        readingRepository: _readingRepository,
        memorizationRepository: _memorizationRepository,
        tajwidRepository: _tajwidRepository,
      ),
    ),
  );

  Future<void> _openRecitationCheck() => Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => RecitationCheckScreen(
        readingRepository: _readingRepository,
        preferences: widget.preferences,
      ),
    ),
  );

  Future<void> _openSettings() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => SettingsScreen(
          preferences: widget.preferences,
          onSetDarkMode: widget.onSetDarkMode,
        ),
      ),
    );
    if (!mounted) return;
    _reloadSignal.value++;
  }

  Future<void> _openAbout() => Navigator.of(
    context,
  ).push<void>(MaterialPageRoute<void>(builder: (_) => const AboutScreen()));

  @override
  void dispose() {
    _reloadSignal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: IndexedStack(
      index: _selectedIndex,
      children: [
        _HomeDashboard(
          preferences: widget.preferences,
          readingRepository: _readingRepository,
          memorizationRepository: _memorizationRepository,
          reloadSignal: _reloadSignal,
          onOpenQuran: () => setState(() => _selectedIndex = 1),
          onOpenMemorization: _openMemorization,
          onOpenTajwid: _openTajwid,
          onOpenPrayerTimes: _openPrayerTimes,
          onOpenReadingStats: _openReadingStats,
        ),
        HomeScreen(
          preferences: widget.preferences,
          repository: _readingRepository,
          reloadSignal: _reloadSignal,
        ),
        _ActivitiesScreen(
          onOpenMemorization: _openMemorization,
          onOpenTajwid: _openTajwid,
          onOpenTasbih: _openTasbih,
          onOpenDoaDzikir: _openDoaDzikir,
          onOpenRecitationCheck: _openRecitationCheck,
          onOpenReadingStats: _openReadingStats,
        ),
        _MoreScreen(
          onOpenSettings: _openSettings,
          onOpenAbout: _openAbout,
          onOpenPrayerTimes: _openPrayerTimes,
          onOpenQibla: _openQibla,
          onOpenHijriCalendar: _openHijriCalendar,
          onOpenAsmaulHusna: _openAsmaulHusna,
          onOpenKajian: _openKajian,
          onOpenIslamicFigures: _openIslamicFigures,
          onOpenQuotesStories: _openQuotesStories,
        ),
      ],
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) {
        if (index != _selectedIndex) {
          setState(() => _selectedIndex = index);
          if (index == 0) _reloadSignal.value++;
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: 'Beranda',
        ),
        NavigationDestination(
          icon: Icon(Icons.menu_book_outlined),
          selectedIcon: Icon(Icons.menu_book_rounded),
          label: 'Al-Qur’an',
        ),
        NavigationDestination(
          icon: Icon(Icons.local_library_outlined),
          selectedIcon: Icon(Icons.local_library_rounded),
          label: 'Aktivitas',
        ),
        NavigationDestination(
          icon: Icon(Icons.grid_view_outlined),
          selectedIcon: Icon(Icons.grid_view_rounded),
          label: 'Lainnya',
        ),
      ],
    ),
  );
}

class _HomeDashboard extends StatefulWidget {
  const _HomeDashboard({
    required this.preferences,
    required this.readingRepository,
    required this.memorizationRepository,
    required this.reloadSignal,
    required this.onOpenQuran,
    required this.onOpenMemorization,
    required this.onOpenTajwid,
    required this.onOpenPrayerTimes,
    required this.onOpenReadingStats,
  });

  final AppPreferences preferences;
  final ReadingRepository readingRepository;
  final MemorizationRepository memorizationRepository;
  final ValueListenable<int> reloadSignal;
  final VoidCallback onOpenQuran;
  final VoidCallback onOpenMemorization;
  final VoidCallback onOpenTajwid;
  final VoidCallback onOpenPrayerTimes;
  final VoidCallback onOpenReadingStats;

  @override
  State<_HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<_HomeDashboard> {
  late Future<_DashboardData> _dashboard;

  @override
  void initState() {
    super.initState();
    _dashboard = _loadDashboard();
    widget.reloadSignal.addListener(_reload);
  }

  @override
  void didUpdateWidget(covariant _HomeDashboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reloadSignal == widget.reloadSignal) return;
    oldWidget.reloadSignal.removeListener(_reload);
    widget.reloadSignal.addListener(_reload);
  }

  @override
  void dispose() {
    widget.reloadSignal.removeListener(_reload);
    super.dispose();
  }

  void _reload() {
    setState(() {
      _dashboard = _loadDashboard();
    });
  }

  Future<_DashboardData> _loadDashboard() async {
    final voiceId = await widget.preferences.selectedVoiceId;
    final lastRead = voiceId == null
        ? null
        : await widget.readingRepository.getProgress(voiceId);
    final programs = await widget.memorizationRepository.getPrograms();
    var totalProgramAyahs = 0;
    var masteredAyahs = 0;
    var completedToday = 0;
    var targetToday = 0;
    for (final program in programs) {
      totalProgramAyahs += program.totalAyahs;
      final progress = await widget.memorizationRepository.getProgress(
        program.id,
      );
      masteredAyahs += progress.values
          .where((item) => item.status == MemorizationStatus.mastered)
          .length;
      final daily = await widget.memorizationRepository.getDailyProgress(
        program,
      );
      completedToday += daily.completedNewAyahs;
      targetToday += daily.dailyTarget;
    }
    return _DashboardData(
      lastRead: lastRead,
      programCount: programs.length,
      masteredAyahs: masteredAyahs,
      totalProgramAyahs: totalProgramAyahs,
      completedToday: completedToday,
      targetToday: targetToday,
    );
  }

  Future<void> _continueReading(AyahEntry? lastRead) async {
    final ayah = lastRead;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ReadingScreen(
          repository: widget.readingRepository,
          preferences: widget.preferences,
          surahNumber: ayah?.surahNumber ?? 1,
          startingAyah: ayah?.ayahNumber ?? 1,
        ),
      ),
    );
    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            padding: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF0B2A5B),
              border: Border.all(
                color: AppColors.gold.withValues(alpha: 0.65),
                width: 1.2,
              ),
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/branding/tilawahku_icon.png',
                width: 32,
                height: 32,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'Tilawahku',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    ),
    body: FutureBuilder<_DashboardData>(
      future: _dashboard,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _DashboardMessage(
            icon: Icons.error_outline_rounded,
            message: 'Ringkasan aktivitas tidak dapat dimuat.',
            detail: '${snapshot.error}',
            action: TextButton(
              onPressed: _reload,
              child: const Text('Coba lagi'),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data!;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Text(
              'Tilawah hari ini',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            const Text('Bacaan terakhir, target hafalan, dan akses ibadah'),
            const SizedBox(height: 16),
            _ContinueReadingCard(
              lastRead: data.lastRead,
              onPressed: () => _continueReading(data.lastRead),
            ),
            const SizedBox(height: 12),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _SummaryCard(
                      icon: Icons.auto_stories_outlined,
                      title: 'Progres mushaf',
                      value: data.lastRead == null
                          ? '0 / 604 halaman'
                          : 'Hal. ${data.lastRead!.pageNumber} / 604',
                      onTap: widget.onOpenReadingStats,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SummaryCard(
                      icon: Icons.psychology_alt_rounded,
                      title: 'Hafalan dikuasai',
                      value: data.programCount == 0
                          ? 'Belum ada program'
                          : '${data.masteredAyahs} dari ${data.totalProgramAyahs} ayat',
                      onTap: widget.onOpenMemorization,
                    ),
                  ),
                ],
              ),
            ),
            if (data.programCount > 0) ...[
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.flag_outlined),
                  title: const Text('Target hafalan hari ini'),
                  subtitle: Text(
                    '${data.completedToday} dari ${data.targetToday} ayat baru '
                    'di seluruh program',
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            _QuickAccessGrid(
              title: 'Akses cepat',
              items: [
                _MenuItemData(
                  icon: Icons.schedule_rounded,
                  title: 'Waktu salat',
                  subtitle: 'Jadwal dan pengingat',
                  onTap: widget.onOpenPrayerTimes,
                ),
                _MenuItemData(
                  icon: Icons.menu_book_rounded,
                  title: 'Buka Al-Qur’an',
                  subtitle: 'Daftar surah dan juz',
                  onTap: widget.onOpenQuran,
                ),
                _MenuItemData(
                  icon: Icons.psychology_alt_rounded,
                  title: 'Program hafalan',
                  subtitle: 'Target dan perkembangan',
                  onTap: widget.onOpenMemorization,
                ),
                _MenuItemData(
                  icon: Icons.school_outlined,
                  title: 'Belajar Tajwid',
                  subtitle: 'Hukum bacaan dan latihan',
                  onTap: widget.onOpenTajwid,
                ),
              ],
            ),
          ],
        );
      },
    ),
  );
}

class _DashboardData {
  const _DashboardData({
    required this.lastRead,
    required this.programCount,
    required this.masteredAyahs,
    required this.totalProgramAyahs,
    required this.completedToday,
    required this.targetToday,
  });

  final AyahEntry? lastRead;
  final int programCount;
  final int masteredAyahs;
  final int totalProgramAyahs;
  final int completedToday;
  final int targetToday;
}

class _ContinueReadingCard extends StatelessWidget {
  const _ContinueReadingCard({required this.lastRead, required this.onPressed});

  static const int _totalMushafPages = 604;

  final AyahEntry? lastRead;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final current = lastRead;
    final hasProgress = current != null;
    final pageFraction = hasProgress
        ? (current.pageNumber / _totalMushafPages).clamp(0.0, 1.0)
        : 0.0;
    final pagePercent = (pageFraction * 100).round();
    final scripture = current?.uthmaniText.trim() ?? '';

    return Card(
      color: AppColors.navy,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColors.gold.withValues(alpha: 0.4)),
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
                    width: 112,
                    height: 112,
                    child: CustomPaint(
                      painter: _MushafStarPainter(
                        color: AppColors.gold.withValues(alpha: 0.07),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Text(
                        hasProgress ? 'Tilawah terakhir' : 'Mushaf 30 juz',
                        style: const TextStyle(
                          color: AppColors.gold,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      if (hasProgress)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.parchment.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Juz ${current.juzNumber}',
                            style: const TextStyle(
                              color: AppColors.parchment,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Lanjutkan membaca',
                    style: TextStyle(
                      color: AppColors.parchment,
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasProgress
                        ? '${current.surahNameIndonesian ?? 'Surah ${current.surahNumber}'} '
                              '${current.surahNumber}:${current.ayahNumber} · '
                              'Hal. ${current.pageNumber}/$_totalMushafPages'
                        : 'Mulai dari Al-Fatihah · 114 surah offline',
                    style: TextStyle(
                      color: AppColors.parchment.withValues(alpha: 0.88),
                      fontSize: 13,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  if (scripture.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.parchment.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.parchment.withValues(alpha: 0.14),
                        ),
                      ),
                      child: Text(
                        scripture,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontFamily: 'AmiriQuran',
                          fontSize: 19,
                          height: 1.7,
                          color: AppColors.parchment,
                        ),
                      ),
                    ),
                  ],
                  if (hasProgress) ...[
                    const SizedBox(height: 14),
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
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Text(
                        hasProgress
                            ? '$pagePercent% mushaf'
                            : 'Siap dibaca kapan saja',
                        style: TextStyle(
                          color: AppColors.parchment.withValues(alpha: 0.82),
                          fontSize: 12,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const Spacer(),
                      Container(
                        constraints: const BoxConstraints(minHeight: 40),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.gold,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              hasProgress
                                  ? Icons.play_arrow_rounded
                                  : Icons.menu_book_rounded,
                              color: AppColors.navy,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              hasProgress ? 'Lanjutkan' : 'Mulai',
                              style: const TextStyle(
                                color: AppColors.navy,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MushafStarPainter extends CustomPainter {
  const _MushafStarPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
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
  bool shouldRepaint(covariant _MushafStarPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: colors.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: colors.primary, size: 20),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: colors.onSurface.withValues(alpha: 0.45),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(title, style: theme.textTheme.bodySmall),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
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

class _MenuItemData {
  const _MenuItemData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
}

class _QuickAccessGrid extends StatelessWidget {
  const _QuickAccessGrid({required this.title, required this.items});

  final String title;
  final List<_MenuItemData> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final rows = <List<_MenuItemData>>[];
    for (var i = 0; i < items.length; i += 2) {
      rows.add(items.sublist(i, math.min(i + 2, items.length)));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 10),
        for (var rowIndex = 0; rowIndex < rows.length; rowIndex++) ...[
          if (rowIndex > 0) const SizedBox(height: 12),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _QuickAccessTile(item: rows[rowIndex][0])),
                const SizedBox(width: 12),
                Expanded(
                  child: rows[rowIndex].length > 1
                      ? _QuickAccessTile(item: rows[rowIndex][1])
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _QuickAccessTile extends StatelessWidget {
  const _QuickAccessTile({required this.item});

  final _MenuItemData item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      color: colors.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colors.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(item.icon, size: 20, color: colors.primary),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: colors.onSurface.withValues(alpha: 0.42),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                item.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurface.withValues(alpha: 0.72),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuSection extends StatelessWidget {
  const _MenuSection({required this.title, required this.items});

  final String title;
  final List<_MenuItemData> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: colors.outlineVariant.withValues(alpha: 0.45),
            ),
          ),
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    thickness: 1,
                    indent: 62,
                    color: colors.outlineVariant.withValues(alpha: 0.35),
                  ),
                ListTile(
                  minTileHeight: 64,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 4,
                  ),
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      items[i].icon,
                      size: 20,
                      color: colors.primary,
                    ),
                  ),
                  title: Text(
                    items[i].title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    items[i].subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurface.withValues(alpha: 0.72),
                    ),
                  ),
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: colors.onSurface.withValues(alpha: 0.5),
                  ),
                  onTap: items[i].onTap,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ActivitiesScreen extends StatelessWidget {
  const _ActivitiesScreen({
    required this.onOpenMemorization,
    required this.onOpenTajwid,
    required this.onOpenTasbih,
    required this.onOpenDoaDzikir,
    required this.onOpenRecitationCheck,
    required this.onOpenReadingStats,
  });

  final VoidCallback onOpenMemorization;
  final VoidCallback onOpenTajwid;
  final VoidCallback onOpenTasbih;
  final VoidCallback onOpenDoaDzikir;
  final VoidCallback onOpenRecitationCheck;
  final VoidCallback onOpenReadingStats;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Aktivitas')),
    body: ListView(
      key: const ValueKey('activities-options-list'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _MenuSection(
          title: 'Hafalan dan bacaan',
          items: [
            _MenuItemData(
              icon: Icons.psychology_alt_rounded,
              title: 'Hafalan Al-Qur’an',
              subtitle: 'Program, latihan, dan progres hafalan',
              onTap: onOpenMemorization,
            ),
            _MenuItemData(
              icon: Icons.history_rounded,
              title: 'Riwayat hafalan',
              subtitle: 'Riwayat tersedia di dalam detail setiap program',
              onTap: onOpenMemorization,
            ),
            _MenuItemData(
              icon: Icons.school_outlined,
              title: 'Belajar Tajwid',
              subtitle: 'Materi dan latihan Tajwid',
              onTap: onOpenTajwid,
            ),
            _MenuItemData(
              icon: Icons.record_voice_over_outlined,
              title: 'Koreksi bacaan',
              subtitle:
                  'Cek kata benar/salah langsung pada teks ayat secara offline',
              onTap: onOpenRecitationCheck,
            ),
          ],
        ),
        const SizedBox(height: 20),
        _MenuSection(
          title: 'Dzikir dan doa',
          items: [
            _MenuItemData(
              icon: Icons.touch_app_outlined,
              title: 'Tasbih digital',
              subtitle: 'Penghitung dzikir, target 33/99/kustom, dan getar',
              onTap: onOpenTasbih,
            ),
            _MenuItemData(
              icon: Icons.volunteer_activism_outlined,
              title: 'Doa dan dzikir',
              subtitle: 'Doa harian serta dzikir pagi dan petang berujukan',
              onTap: onOpenDoaDzikir,
            ),
          ],
        ),
        const SizedBox(height: 20),
        _MenuSection(
          title: 'Ringkasan aktivitas',
          items: [
            _MenuItemData(
              icon: Icons.insights_outlined,
              title: 'Statistik membaca',
              subtitle:
                  'Progres tilawah, grafik hafalan 7 hari, tajwid, dan tasbih',
              onTap: onOpenReadingStats,
            ),
          ],
        ),
      ],
    ),
  );
}

class _MoreScreen extends StatelessWidget {
  const _MoreScreen({
    required this.onOpenSettings,
    required this.onOpenAbout,
    required this.onOpenPrayerTimes,
    required this.onOpenQibla,
    required this.onOpenHijriCalendar,
    required this.onOpenAsmaulHusna,
    required this.onOpenKajian,
    required this.onOpenIslamicFigures,
    required this.onOpenQuotesStories,
  });

  final VoidCallback onOpenSettings;
  final VoidCallback onOpenAbout;
  final VoidCallback onOpenPrayerTimes;
  final VoidCallback onOpenQibla;
  final VoidCallback onOpenHijriCalendar;
  final VoidCallback onOpenAsmaulHusna;
  final VoidCallback onOpenKajian;
  final VoidCallback onOpenIslamicFigures;
  final VoidCallback onOpenQuotesStories;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Lainnya')),
    body: ListView(
      key: const ValueKey('more-options-list'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _MenuSection(
          title: 'Panduan ibadah',
          items: [
            _MenuItemData(
              icon: Icons.schedule_rounded,
              title: 'Waktu salat',
              subtitle: 'Jadwal lima waktu, hijriah, dan pengingat',
              onTap: onOpenPrayerTimes,
            ),
            _MenuItemData(
              icon: Icons.explore_outlined,
              title: 'Arah kiblat',
              subtitle: 'Kompas perangkat atau dial manual',
              onTap: onOpenQibla,
            ),
            _MenuItemData(
              icon: Icons.calendar_month_outlined,
              title: 'Kalender Hijriah',
              subtitle: 'Tanggal Hijri, kalender bulanan, dan event penting',
              onTap: onOpenHijriCalendar,
            ),
          ],
        ),
        const SizedBox(height: 20),
        _MenuSection(
          title: 'Wawasan Islam',
          items: [
            _MenuItemData(
              icon: Icons.auto_stories_outlined,
              title: 'Asmaul Husna',
              subtitle: '99 nama Allah, makna, dan rujukan ayat',
              onTap: onOpenAsmaulHusna,
            ),
            _MenuItemData(
              icon: Icons.mic_none_rounded,
              title: 'Kajian dan ceramah',
              subtitle:
                  'Pemutar RSS podcast kajian resmi, cache lokal, dan riwayat',
              onTap: onOpenKajian,
            ),
            _MenuItemData(
              icon: Icons.person_outline_rounded,
              title: 'Tokoh Islam',
              subtitle:
                  'Biografi nabi, sahabat, ulama, ilmuwan, dan tokoh Nusantara',
              onTap: onOpenIslamicFigures,
            ),
            _MenuItemData(
              icon: Icons.format_quote_rounded,
              title: 'Quotes dan kisah Islam',
              subtitle: 'Kutipan hikmah dan kisah teladan berujukan',
              onTap: onOpenQuotesStories,
            ),
          ],
        ),
        const SizedBox(height: 20),
        _MenuSection(
          title: 'Aplikasi',
          items: [
            _MenuItemData(
              icon: Icons.settings_outlined,
              title: 'Pengaturan',
              subtitle: 'Tema, tampilan ayat, suara, dan unduhan',
              onTap: onOpenSettings,
            ),
            _MenuItemData(
              icon: Icons.info_outline_rounded,
              title: 'Tentang aplikasi',
              subtitle: 'Sumber konten dan informasi Tilawahku',
              onTap: onOpenAbout,
            ),
          ],
        ),
      ],
    ),
  );
}

class _DashboardMessage extends StatelessWidget {
  const _DashboardMessage({
    required this.icon,
    required this.message,
    required this.detail,
    this.action,
  });

  final IconData icon;
  final String message;
  final String detail;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(detail, textAlign: TextAlign.center),
          if (action != null) ...[const SizedBox(height: 12), action!],
        ],
      ),
    ),
  );
}
