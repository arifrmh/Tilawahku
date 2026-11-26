import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawahku/core/preferences/app_preferences.dart';
import 'package:tilawahku/features/memorization/data/memorization_repository.dart';
import 'package:tilawahku/features/memorization/domain/memorization_models.dart';
import 'package:tilawahku/features/navigation/presentation/main_navigation_screen.dart';
import 'package:tilawahku/features/reading/data/reading_repository.dart';
import 'package:tilawahku/features/tajwid/data/tajwid_repository.dart';
import 'package:tilawahku/features/tasbih/data/tasbih_repository.dart';
import 'package:tilawahku/features/tasbih/domain/tasbih_models.dart';
import 'package:tilawahku/features/tasbih/presentation/tasbih_controller.dart';
import 'package:tilawahku/features/tasbih/presentation/tasbih_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TasbihState transitions', () {
    test('increments across rounds and undoes accurately at boundaries', () {
      var state = const TasbihState(target: 3);

      var (next1, reached1) = state.increment();
      expect(next1.count, 1);
      expect(next1.completedRounds, 0);
      expect(next1.totalCount, 1);
      expect(reached1, isFalse);

      var (next2, reached2) = next1.increment();
      expect(next2.count, 2);
      expect(reached2, isFalse);

      var (next3, reached3) = next2.increment();
      expect(next3.count, 3);
      expect(next3.completedRounds, 1);
      expect(next3.totalCount, 3);
      expect(reached3, isTrue);

      // Next tap starts round 2 at 1
      var (next4, reached4) = next3.increment();
      expect(next4.count, 1);
      expect(next4.completedRounds, 1);
      expect(next4.totalCount, 4);
      expect(reached4, isFalse);

      // Undo from round 2 count 1 returns to target of round 1
      final undoToRound1 = next4.decrement();
      expect(undoToRound1.count, 3);
      expect(undoToRound1.completedRounds, 1);
      expect(undoToRound1.totalCount, 3);

      // Undo from completed target decrements completedRounds as well
      final undoBeforeTarget = undoToRound1.decrement();
      expect(undoBeforeTarget.count, 2);
      expect(undoBeforeTarget.completedRounds, 0);
      expect(undoBeforeTarget.totalCount, 2);
    });

    test('persists state and respects haptic toggle in controller', () async {
      SharedPreferences.setMockInitialValues({});
      var tapHaptics = 0;
      var targetHaptics = 0;
      final repository = TasbihRepository();
      final controller = TasbihController(
        repository: repository,
        onTapHaptic: () async => tapHaptics++,
        onTargetReachedHaptic: () async => targetHaptics++,
      );
      await controller.load();
      await controller.setTarget(2);

      await controller.tap();
      await controller.tap();
      expect(tapHaptics, 1);
      expect(targetHaptics, 1);
      expect(controller.state.count, 2);
      expect(controller.state.completedRounds, 1);

      await controller.toggleHaptic();
      await controller.tap();
      expect(tapHaptics, 1);
      expect(controller.state.hapticEnabled, isFalse);

      final reloaded = await repository.loadState();
      expect(reloaded.count, 1);
      expect(reloaded.target, 2);
      expect(reloaded.completedRounds, 1);
      expect(reloaded.totalCount, 3);
      expect(reloaded.hapticEnabled, isFalse);

      controller.dispose();
    });
  });

  group('TasbihScreen widget & navigation', () {
    testWidgets('counts taps, sets custom target, and confirms safe reset', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final controller = TasbihController(
        repository: TasbihRepository(),
        onTapHaptic: () async {},
        onTargetReachedHaptic: () async {},
      );

      await tester.pumpWidget(
        MaterialApp(
          home: TasbihScreen(
            preferences: const AppPreferences(),
            controller: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tasbih digital'), findsOneWidget);
      expect(find.text('سُبْحَانَ اللَّهِ'), findsOneWidget);

      await tester.tap(find.text('Kustom'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '2');
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();
      expect(find.text('dari 2'), findsOneWidget);

      final tapButton = find.byKey(const ValueKey('tasbih-tap-button'));
      await tester.tap(tapButton);
      await tester.pumpAndSettle();
      expect(find.text('1'), findsOneWidget);

      await tester.tap(tapButton);
      await tester.pumpAndSettle();
      expect(find.text('Target tercapai'), findsOneWidget);

      await tester.tap(find.byTooltip('Reset hitungan'));
      await tester.pumpAndSettle();
      expect(find.text('Reset hitungan tasbih?'), findsOneWidget);
      await tester.tap(find.text('Reset semua'));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Putaran selesai: 0 · Total hitungan: 0'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('0'), findsOneWidget);
      expect(find.text('Putaran selesai: 0 · Total hitungan: 0'), findsOneWidget);

      controller.dispose();
    });

    testWidgets('Aktivitas tab opens Tasbih digital screen', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final readingRepository = _FakeReadingRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: MainNavigationScreen(
            preferences: const AppPreferences(),
            onSetDarkMode: (_) {},
            readingRepository: readingRepository,
            memorizationRepository: MemorizationRepository(
              store: _EmptyMemorizationStore(),
              readingRepository: readingRepository,
            ),
            tajwidRepository: TajwidRepository(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Aktivitas').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tasbih digital'));
      await tester.pumpAndSettle();

      expect(find.byType(TasbihScreen), findsOneWidget);
      expect(find.text('سُبْحَانَ اللَّهِ'), findsOneWidget);
    });
  });
}

class _FakeReadingRepository extends ReadingRepository {
  @override
  Future<List<Surah>> getSurahs() async => const [];

  @override
  Future<AyahEntry?> getProgress(String voiceId) async => null;
}

class _EmptyMemorizationStore implements MemorizationStore {
  @override
  Future<List<MemorizationProgram>> getPrograms() async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
