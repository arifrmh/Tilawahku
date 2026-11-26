import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawahku/core/preferences/app_preferences.dart';
import 'package:tilawahku/features/memorization/data/memorization_repository.dart';
import 'package:tilawahku/features/memorization/domain/memorization_models.dart';
import 'package:tilawahku/features/navigation/presentation/main_navigation_screen.dart';
import 'package:tilawahku/features/reading/data/reading_repository.dart';
import 'package:tilawahku/features/reading_stats/data/reading_stats_repository.dart';
import 'package:tilawahku/features/reading_stats/domain/reading_stats_models.dart';
import 'package:tilawahku/features/reading_stats/presentation/reading_stats_screen.dart';
import 'package:tilawahku/features/tajwid/data/tajwid_repository.dart';
import 'package:tilawahku/features/tajwid/domain/tajwid_models.dart';
import 'package:tilawahku/features/tasbih/data/tasbih_repository.dart';
import 'package:tilawahku/features/tasbih/domain/tasbih_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Reading stats domain calculations', () {
    test('buildLast7DaysStats aggregates sessions per day and ignores older days', () {
      final now = DateTime(2026, 11, 25, 14, 30); // Rabu
      final sessions = [
        const MemorizationSession(
          id: 's1',
          programId: 'p1',
          mode: MemorizationSessionMode.learn,
          dayKey: '2026-11-25',
          startedAt: '2026-11-25T07:00:00Z',
          completedAt: '2026-11-25T07:10:00Z',
          newAyahCount: 3,
          repeatedAyahCount: 2,
        ),
        const MemorizationSession(
          id: 's2',
          programId: 'p1',
          mode: MemorizationSessionMode.recall,
          dayKey: '2026-11-25',
          startedAt: '2026-11-25T10:00:00Z',
          completedAt: '2026-11-25T10:15:00Z',
          newAyahCount: 1,
          repeatedAyahCount: 4,
        ),
        const MemorizationSession(
          id: 's3',
          programId: 'p1',
          mode: MemorizationSessionMode.learn,
          dayKey: '2026-11-23',
          startedAt: '2026-11-23T08:00:00Z',
          completedAt: '2026-11-23T08:10:00Z',
          newAyahCount: 5,
          repeatedAyahCount: 0,
        ),
        const MemorizationSession(
          id: 'old',
          programId: 'p1',
          mode: MemorizationSessionMode.learn,
          dayKey: '2026-11-10',
          startedAt: '2026-11-10T08:00:00Z',
          completedAt: '2026-11-10T08:10:00Z',
          newAyahCount: 99,
          repeatedAyahCount: 99,
        ),
      ];

      final stats = buildLast7DaysStats(sessions, now);

      expect(stats, hasLength(7));
      expect(stats.first.dayKey, '2026-11-19');
      expect(stats.first.shortLabel, 'Kam');
      expect(stats.first.dateLabel, '19/11');
      expect(stats.first.totalPracticed, 0);

      final monday = stats.firstWhere((item) => item.dayKey == '2026-11-23');
      expect(monday.shortLabel, 'Sen');
      expect(monday.newAyahs, 5);
      expect(monday.repeatedAyahs, 0);
      expect(monday.sessionCount, 1);

      final today = stats.last;
      expect(today.dayKey, '2026-11-25');
      expect(today.shortLabel, 'Rab');
      expect(today.newAyahs, 4);
      expect(today.repeatedAyahs, 6);
      expect(today.totalPracticed, 10);
      expect(today.sessionCount, 2);
    });

    test('computeActiveStreakDays handles empty, today, yesterday, and gaps', () {
      final now = DateTime(2026, 11, 25, 10);

      expect(computeActiveStreakDays(const [], now), 0);
      expect(computeActiveStreakDays(['2026-11-22'], now), 0);
      expect(
        computeActiveStreakDays(['2026-11-25', '2026-11-24', '2026-11-23'], now),
        3,
      );
      // Duplicate days on same date should not inflate streak
      expect(
        computeActiveStreakDays(['2026-11-25', '2026-11-25', '2026-11-24'], now),
        2,
      );
      // Yesterday streak stays active until today ends
      expect(
        computeActiveStreakDays(['2026-11-24', '2026-11-23'], now),
        2,
      );
      // Gap on 2026-11-24 breaks streak before 2026-11-23
      expect(
        computeActiveStreakDays(['2026-11-25', '2026-11-23'], now),
        1,
      );
    });
  });

  group('ReadingStatsRepository', () {
    test('aggregates local reading, memorization, tajwid, and tasbih data', () async {
      SharedPreferences.setMockInitialValues({'selected_voice_id': 'ar.alafasy'});
      const preferences = AppPreferences();
      final tasbihRepo = TasbihRepository(preferences: preferences);
      await tasbihRepo.saveState(
        const TasbihState(
          presetId: 'istighfar',
          count: 10,
          target: 33,
          completedRounds: 2,
          totalCount: 76,
        ),
      );

      final readingRepo = _FakeReadingRepository(
        lastRead: const AyahEntry(
          globalNumber: 293,
          surahNumber: 2,
          ayahNumber: 286,
          juzNumber: 3,
          pageNumber: 49,
          uthmaniText: 'لَا يُكَلِّفُ اللَّهُ نَفْسًا إِلَّا وُسْعَهَا',
          surahNameIndonesian: 'Al-Baqarah',
        ),
        bookmarks: const [
          AyahEntry(
            globalNumber: 1,
            surahNumber: 1,
            ayahNumber: 1,
            juzNumber: 1,
            pageNumber: 1,
            uthmaniText: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
          ),
          AyahEntry(
            globalNumber: 262,
            surahNumber: 2,
            ayahNumber: 255,
            juzNumber: 3,
            pageNumber: 42,
            uthmaniText: 'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ',
          ),
        ],
      );

      final memRepo = MemorizationRepository(
        store: _FakeMemorizationStore(
          programs: const [
            MemorizationProgram(
              id: 'p1',
              name: 'Juz Amma',
              scope: MemorizationScope.surah,
              startGlobalAyah: 6222,
              endGlobalAyah: 6231,
              dailyTarget: 3,
              createdAt: '2026-11-20T00:00:00Z',
              updatedAt: '2026-11-25T00:00:00Z',
            ),
          ],
          progressByProgram: const {
            'p1': [
              MemorizationAyahProgress(
                globalAyahNumber: 6222,
                status: MemorizationStatus.mastered,
                firstLearnedOn: '2026-11-24',
                lastPracticedAt: '2026-11-25T07:00:00Z',
              ),
              MemorizationAyahProgress(
                globalAyahNumber: 6223,
                status: MemorizationStatus.mastered,
                firstLearnedOn: '2026-11-24',
                lastPracticedAt: '2026-11-25T07:00:00Z',
              ),
              MemorizationAyahProgress(
                globalAyahNumber: 6224,
                status: MemorizationStatus.learning,
                firstLearnedOn: '2026-11-25',
                lastPracticedAt: '2026-11-25T07:05:00Z',
              ),
            ],
          },
          sessionsByProgram: const {
            'p1': [
              MemorizationSession(
                id: 's1',
                programId: 'p1',
                mode: MemorizationSessionMode.learn,
                dayKey: '2026-11-24',
                startedAt: '2026-11-24T07:00:00Z',
                completedAt: '2026-11-24T07:10:00Z',
                newAyahCount: 2,
                repeatedAyahCount: 1,
              ),
              MemorizationSession(
                id: 's2',
                programId: 'p1',
                mode: MemorizationSessionMode.recall,
                dayKey: '2026-11-25',
                startedAt: '2026-11-25T07:00:00Z',
                completedAt: '2026-11-25T07:10:00Z',
                newAyahCount: 1,
                repeatedAyahCount: 3,
              ),
            ],
          },
        ),
        readingRepository: readingRepo,
      );

      final tajwidRepo = _FakeTajwidRepository(
        const TajwidQuizProgress(
          completedAttempts: 3,
          totalCorrectAnswers: 13,
          totalAnsweredQuestions: 15,
          bestScoreFraction: 1.0,
          latestAttempt: null,
        ),
      );

      final statsRepo = ReadingStatsRepository(
        preferences: preferences,
        readingRepository: readingRepo,
        memorizationRepository: memRepo,
        tajwidRepository: tajwidRepo,
        tasbihRepository: tasbihRepo,
        clock: () => DateTime(2026, 11, 25, 12),
      );

      final snapshot = await statsRepo.loadSnapshot();

      expect(snapshot.lastRead?.surahNameIndonesian, 'Al-Baqarah');
      expect(snapshot.bookmarkCount, 2);
      expect(snapshot.programCount, 1);
      expect(snapshot.masteredAyahs, 2);
      expect(snapshot.totalProgramAyahs, 10);
      expect(snapshot.totalSessions, 2);
      expect(snapshot.activeStreakDays, 2);
      expect(snapshot.last7DaysTotalPracticed, 7);
      expect(snapshot.last7DaysNewAyahs, 3);
      expect(snapshot.last7DaysRepeatedAyahs, 4);
      expect(snapshot.tajwidProgress.completedAttempts, 3);
      expect(snapshot.tasbihState.totalCount, 76);
      expect(snapshot.tasbihState.completedRounds, 2);
    });
  });

  group('ReadingStatsScreen widgets & navigation', () {
    testWidgets('renders honest empty state when no local activity exists', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final readingRepo = _FakeReadingRepository();
      final statsRepo = ReadingStatsRepository(
        preferences: const AppPreferences(),
        readingRepository: readingRepo,
        memorizationRepository: MemorizationRepository(
          store: const _FakeMemorizationStore(),
          readingRepository: readingRepo,
        ),
        tajwidRepository: _FakeTajwidRepository(
          const TajwidQuizProgress.empty(),
        ),
        clock: () => DateTime(2026, 11, 25, 12),
      );

      await tester.pumpWidget(
        MaterialApp(home: ReadingStatsScreen(repository: statsRepo)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Statistik membaca'), findsOneWidget);
      expect(find.text('Belum ada catatan bacaan'), findsOneWidget);
      expect(find.text('Ayat ditandai: 0 ayat'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Belum ada sesi latihan hafalan dalam 7 hari terakhir.'),
        200,
      );
      expect(
        find.text('Belum ada sesi latihan hafalan dalam 7 hari terakhir.'),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.text('Belum ada kuis Tajwid yang diselesaikan.'),
        200,
      );
      expect(
        find.text('Belum ada kuis Tajwid yang diselesaikan.'),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.text('Belum ada hitungan tasbih tercatat.'),
        200,
      );
      expect(
        find.text('Belum ada hitungan tasbih tercatat.'),
        findsOneWidget,
      );
    });

    testWidgets('renders populated statistics and opens from Aktivitas tab', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({'selected_voice_id': 'ar.alafasy'});
      const preferences = AppPreferences();
      final readingRepo = _FakeReadingRepository(
        lastRead: const AyahEntry(
          globalNumber: 7,
          surahNumber: 1,
          ayahNumber: 7,
          juzNumber: 1,
          pageNumber: 1,
          uthmaniText: 'صِرَاطَ الَّذِينَ أَنْعَمْتَ عَلَيْهِمْ',
          surahNameIndonesian: 'Al-Fatihah',
        ),
        bookmarks: const [
          AyahEntry(
            globalNumber: 7,
            surahNumber: 1,
            ayahNumber: 7,
            juzNumber: 1,
            pageNumber: 1,
            uthmaniText: 'صِرَاطَ الَّذِينَ أَنْعَمْتَ عَلَيْهِمْ',
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MainNavigationScreen(
            preferences: preferences,
            onSetDarkMode: (_) {},
            readingRepository: readingRepo,
            memorizationRepository: MemorizationRepository(
              store: const _FakeMemorizationStore(),
              readingRepository: readingRepo,
            ),
            tajwidRepository: _FakeTajwidRepository(
              const TajwidQuizProgress(
                completedAttempts: 1,
                totalCorrectAnswers: 4,
                totalAnsweredQuestions: 5,
                bestScoreFraction: 0.8,
                latestAttempt: null,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Aktivitas').last);
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Statistik membaca'),
        200,
        scrollable: find.descendant(
          of: find.byKey(const ValueKey('activities-options-list')),
          matching: find.byType(Scrollable),
        ),
      );
      expect(find.text('Belum tersedia'), findsNothing);

      await tester.tap(find.text('Statistik membaca'));
      await tester.pumpAndSettle();

      expect(find.text('Posisi bacaan terakhir'), findsOneWidget);
      expect(find.text('Al-Fatihah 1:7'), findsOneWidget);
      expect(find.text('Ayat ditandai: 1 ayat'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Aktivitas hafalan 7 hari terakhir'),
        200,
      );
      expect(find.text('Aktivitas hafalan 7 hari terakhir'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.textContaining('1 kuis selesai, skor terbaik 80%'),
        200,
      );
      expect(
        find.textContaining('1 kuis selesai, skor terbaik 80%'),
        findsOneWidget,
      );
    });
  });
}

class _FakeReadingRepository extends ReadingRepository {
  _FakeReadingRepository({
    this.lastRead,
    this.bookmarks = const [],
  });

  final AyahEntry? lastRead;
  final List<AyahEntry> bookmarks;

  @override
  Future<List<Surah>> getSurahs() async => const [];

  @override
  Future<AyahEntry?> getProgress(String voiceId) async => lastRead;

  @override
  Future<List<AyahEntry>> getBookmarks() async => bookmarks;
}

class _FakeMemorizationStore implements MemorizationStore {
  const _FakeMemorizationStore({
    this.programs = const [],
    this.progressByProgram = const {},
    this.sessionsByProgram = const {},
  });

  final List<MemorizationProgram> programs;
  final Map<String, List<MemorizationAyahProgress>> progressByProgram;
  final Map<String, List<MemorizationSession>> sessionsByProgram;

  @override
  Future<List<MemorizationProgram>> getPrograms() async => programs;

  @override
  Future<List<MemorizationAyahProgress>> getProgress(String programId) async =>
      progressByProgram[programId] ?? const [];

  @override
  Future<List<MemorizationSession>> getSessions(String programId) async =>
      sessionsByProgram[programId] ?? const [];

  @override
  Future<int> getNewAyahCount(String programId, String dayKey) async => 0;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeTajwidRepository extends TajwidRepository {
  _FakeTajwidRepository(this._progress);

  final TajwidQuizProgress _progress;

  @override
  Future<TajwidQuizProgress> getProgress() async => _progress;
}
