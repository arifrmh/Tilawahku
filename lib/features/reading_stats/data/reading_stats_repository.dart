import '../../../core/preferences/app_preferences.dart';
import '../../memorization/data/memorization_repository.dart';
import '../../memorization/domain/memorization_models.dart';
import '../../reading/data/reading_repository.dart';
import '../../tajwid/data/tajwid_repository.dart';
import '../../tasbih/data/tasbih_repository.dart';
import '../domain/reading_stats_models.dart';

class ReadingStatsRepository {
  ReadingStatsRepository({
    AppPreferences? preferences,
    ReadingRepository? readingRepository,
    MemorizationRepository? memorizationRepository,
    TajwidRepository? tajwidRepository,
    TasbihRepository? tasbihRepository,
    DateTime Function()? clock,
  }) : _preferences = preferences ?? const AppPreferences(),
       _readingRepository = readingRepository ?? ReadingRepository(),
       _memorizationRepository =
           memorizationRepository ??
           MemorizationRepository(
             readingRepository: readingRepository ?? ReadingRepository(),
           ),
       _tajwidRepository = tajwidRepository ?? TajwidRepository(),
       _tasbihRepository =
           tasbihRepository ??
           TasbihRepository(
             preferences: preferences ?? const AppPreferences(),
           ),
       _clock = clock ?? DateTime.now;

  final AppPreferences _preferences;
  final ReadingRepository _readingRepository;
  final MemorizationRepository _memorizationRepository;
  final TajwidRepository _tajwidRepository;
  final TasbihRepository _tasbihRepository;
  final DateTime Function() _clock;

  Future<ReadingStatsSnapshot> loadSnapshot() async {
    final voiceId = await _preferences.selectedVoiceId;
    final lastRead = voiceId == null
        ? null
        : await _readingRepository.getProgress(voiceId);
    final bookmarks = await _readingRepository.getBookmarks();

    final programs = await _memorizationRepository.getPrograms();
    var totalProgramAyahs = 0;
    var masteredAyahs = 0;
    final allSessions = <MemorizationSession>[];

    for (final program in programs) {
      totalProgramAyahs += program.totalAyahs;
      final progress = await _memorizationRepository.getProgress(program.id);
      masteredAyahs += progress.values
          .where((item) => item.status == MemorizationStatus.mastered)
          .length;
      final sessions = await _memorizationRepository.getSessions(program.id);
      allSessions.addAll(sessions);
    }

    final tajwidProgress = await _tajwidRepository.getProgress();
    final tasbihState = await _tasbihRepository.loadState();
    final now = _clock();

    return ReadingStatsSnapshot(
      lastRead: lastRead,
      bookmarkCount: bookmarks.length,
      programCount: programs.length,
      masteredAyahs: masteredAyahs,
      totalProgramAyahs: totalProgramAyahs,
      totalSessions: allSessions.length,
      activeStreakDays: computeActiveStreakDays(
        allSessions.map((session) => session.dayKey),
        now,
      ),
      last7Days: buildLast7DaysStats(allSessions, now),
      tajwidProgress: tajwidProgress,
      tasbihState: tasbihState,
    );
  }
}
