import '../../memorization/domain/memorization_models.dart';
import '../../reading/data/reading_repository.dart';
import '../../tajwid/domain/tajwid_models.dart';
import '../../tasbih/domain/tasbih_models.dart';

const int totalQuranAyahs = 6236;
const int totalMushafPages = 604;
const int totalQuranJuz = 30;

const List<String> _indonesianWeekdays = [
  'Sen',
  'Sel',
  'Rab',
  'Kam',
  'Jum',
  'Sab',
  'Min',
];

class DailyActivityStat {
  const DailyActivityStat({
    required this.dayKey,
    required this.shortLabel,
    required this.dateLabel,
    required this.newAyahs,
    required this.repeatedAyahs,
    required this.sessionCount,
  });

  final String dayKey;
  final String shortLabel;
  final String dateLabel;
  final int newAyahs;
  final int repeatedAyahs;
  final int sessionCount;

  int get totalPracticed => newAyahs + repeatedAyahs;
}

class ReadingStatsSnapshot {
  const ReadingStatsSnapshot({
    required this.lastRead,
    required this.bookmarkCount,
    required this.programCount,
    required this.masteredAyahs,
    required this.totalProgramAyahs,
    required this.totalSessions,
    required this.activeStreakDays,
    required this.last7Days,
    required this.tajwidProgress,
    required this.tasbihState,
  });

  final AyahEntry? lastRead;
  final int bookmarkCount;
  final int programCount;
  final int masteredAyahs;
  final int totalProgramAyahs;
  final int totalSessions;
  final int activeStreakDays;
  final List<DailyActivityStat> last7Days;
  final TajwidQuizProgress tajwidProgress;
  final TasbihState tasbihState;

  double get pageProgress => lastRead == null
      ? 0
      : (lastRead!.pageNumber / totalMushafPages).clamp(0.0, 1.0);

  double get ayahProgress => lastRead == null
      ? 0
      : (lastRead!.globalNumber / totalQuranAyahs).clamp(0.0, 1.0);

  double get masteryProgress => totalProgramAyahs == 0
      ? 0
      : (masteredAyahs / totalProgramAyahs).clamp(0.0, 1.0);

  int get last7DaysTotalPracticed =>
      last7Days.fold(0, (sum, item) => sum + item.totalPracticed);

  int get last7DaysNewAyahs =>
      last7Days.fold(0, (sum, item) => sum + item.newAyahs);

  int get last7DaysRepeatedAyahs =>
      last7Days.fold(0, (sum, item) => sum + item.repeatedAyahs);

  int get last7DaysSessions =>
      last7Days.fold(0, (sum, item) => sum + item.sessionCount);
}

String formatStatsDayKey(DateTime date) {
  final local = date.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '${local.year}-$month-$day';
}

List<DailyActivityStat> buildLast7DaysStats(
  List<MemorizationSession> sessions,
  DateTime now,
) {
  final byDay = <String, _DayAccumulator>{};
  for (final session in sessions) {
    final acc = byDay.putIfAbsent(session.dayKey, _DayAccumulator.new);
    acc.newAyahs += session.newAyahCount;
    acc.repeatedAyahs += session.repeatedAyahCount;
    acc.sessionCount += 1;
  }

  final localNow = now.toLocal();
  final stats = <DailyActivityStat>[];
  for (var offset = 6; offset >= 0; offset--) {
    final date = DateTime(localNow.year, localNow.month, localNow.day - offset);
    final key = formatStatsDayKey(date);
    final acc = byDay[key];
    final dayPadded = date.day.toString().padLeft(2, '0');
    final monthPadded = date.month.toString().padLeft(2, '0');
    stats.add(
      DailyActivityStat(
        dayKey: key,
        shortLabel: _indonesianWeekdays[date.weekday - 1],
        dateLabel: '$dayPadded/$monthPadded',
        newAyahs: acc?.newAyahs ?? 0,
        repeatedAyahs: acc?.repeatedAyahs ?? 0,
        sessionCount: acc?.sessionCount ?? 0,
      ),
    );
  }
  return List.unmodifiable(stats);
}

int computeActiveStreakDays(Iterable<String> dayKeys, DateTime now) {
  final activeDays = dayKeys.where((key) => key.trim().isNotEmpty).toSet();
  if (activeDays.isEmpty) return 0;

  final localNow = now.toLocal();
  final today = DateTime(localNow.year, localNow.month, localNow.day);
  final todayKey = formatStatsDayKey(today);
  final yesterday = DateTime(localNow.year, localNow.month, localNow.day - 1);
  final yesterdayKey = formatStatsDayKey(yesterday);

  var cursor = activeDays.contains(todayKey)
      ? today
      : (activeDays.contains(yesterdayKey) ? yesterday : null);
  if (cursor == null) return 0;

  var streak = 0;
  while (activeDays.contains(formatStatsDayKey(cursor!))) {
    streak += 1;
    cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
  }
  return streak;
}

class _DayAccumulator {
  int newAyahs = 0;
  int repeatedAyahs = 0;
  int sessionCount = 0;
}
