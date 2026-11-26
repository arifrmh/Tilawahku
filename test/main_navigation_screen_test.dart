import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawahku/core/preferences/app_preferences.dart';
import 'package:tilawahku/features/memorization/data/memorization_repository.dart';
import 'package:tilawahku/features/memorization/domain/memorization_models.dart';
import 'package:tilawahku/features/reading/data/reading_repository.dart';
import 'package:tilawahku/features/tajwid/data/tajwid_repository.dart';
import 'package:tilawahku/features/navigation/presentation/main_navigation_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('main navigation switches between the four primary sections', (
    tester,
  ) async {
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

    expect(find.text('Akses cepat'), findsOneWidget);
    final prayerPos = tester.getTopLeft(find.text('Waktu salat'));
    final quranPos = tester.getTopLeft(find.text('Buka Al-Qur’an'));
    final memoPos = tester.getTopLeft(find.text('Program hafalan'));
    final tajwidPos = tester.getTopLeft(find.text('Belajar Tajwid'));
    expect(prayerPos.dy, closeTo(quranPos.dy, 1));
    expect(prayerPos.dx, lessThan(quranPos.dx));
    expect(memoPos.dy, closeTo(tajwidPos.dy, 1));
    expect(memoPos.dx, lessThan(tajwidPos.dx));
    expect(memoPos.dy, greaterThan(prayerPos.dy));

    await tester.tap(find.text('Al-Qur’an').last);
    await tester.pumpAndSettle();
    expect(find.text('Juz'), findsOneWidget);
    expect(find.text('Surah'), findsOneWidget);

    await tester.tap(find.text('Aktivitas').last);
    await tester.pumpAndSettle();
    expect(find.text('Hafalan dan bacaan'), findsOneWidget);
    expect(find.text('Riwayat hafalan'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Dzikir dan doa'),
      200,
      scrollable: find.descendant(
        of: find.byKey(const ValueKey('activities-options-list')),
        matching: find.byType(Scrollable),
      ),
    );
    expect(find.text('Dzikir dan doa'), findsOneWidget);
    expect(find.text('Tasbih digital'), findsOneWidget);
    expect(find.text('Doa dan dzikir'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Ringkasan aktivitas'),
      200,
      scrollable: find.descendant(
        of: find.byKey(const ValueKey('activities-options-list')),
        matching: find.byType(Scrollable),
      ),
    );
    expect(find.text('Ringkasan aktivitas'), findsOneWidget);

    await tester.tap(find.text('Lainnya').last);
    await tester.pumpAndSettle();
    expect(find.text('Panduan ibadah'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Wawasan Islam'),
      200,
      scrollable: find.descendant(
        of: find.byKey(const ValueKey('more-options-list')),
        matching: find.byType(Scrollable),
      ),
    );
    expect(find.text('Wawasan Islam'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Pengaturan'),
      200,
      scrollable: find.descendant(
        of: find.byKey(const ValueKey('more-options-list')),
        matching: find.byType(Scrollable),
      ),
    );
    expect(find.text('Aplikasi'), findsOneWidget);
    expect(find.text('Pengaturan'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Tentang aplikasi'),
      200,
      scrollable: find.descendant(
        of: find.byKey(const ValueKey('more-options-list')),
        matching: find.byType(Scrollable),
      ),
    );
    expect(find.text('Tentang aplikasi'), findsOneWidget);

    await tester.tap(find.text('Beranda').last);
    await tester.pumpAndSettle();
    expect(find.text('Akses cepat'), findsOneWidget);
  });

  testWidgets('Beranda continue reading card renders last read scripture preview and opens reader', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'selected_voice_id': 'ar.alafasy'});
    const previewAyah = AyahEntry(
      globalNumber: 262,
      surahNumber: 2,
      ayahNumber: 255,
      juzNumber: 3,
      pageNumber: 42,
      uthmaniText: 'ٱللَّهُ لَآ إِلَٰهَ إِلَّا هُوَ ٱلْحَىُّ ٱلْقَيُّومُ',
      surahNameIndonesian: 'Al-Baqarah',
    );
    final readingRepository = _FakeReadingRepository(lastRead: previewAyah);

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

    expect(find.text('Lanjutkan membaca'), findsOneWidget);
    expect(find.text('Juz 3'), findsOneWidget);
    expect(find.text('Al-Baqarah 2:255 · Hal. 42/604'), findsOneWidget);
    expect(find.text('7% mushaf'), findsOneWidget);
    expect(find.text('Hal. 42 / 604'), findsOneWidget);

    final scriptureText = tester.widget<Text>(find.text(previewAyah.uthmaniText));
    expect(scriptureText.style?.fontFamily, 'AmiriQuran');

    await tester.tap(find.text('Lanjutkan'));
    await tester.pumpAndSettle();
    expect(readingRepository.openedSurah, 2);
  });
}

class _FakeReadingRepository extends ReadingRepository {
  _FakeReadingRepository({this.lastRead});

  final AyahEntry? lastRead;
  int? openedSurah;

  @override
  Future<List<Surah>> getSurahs() async => const [];

  @override
  Future<AyahEntry?> getProgress(String voiceId) async => lastRead;

  @override
  Future<List<AyahEntry>> getAyahsForSurah(int surahNumber, {int? limit}) async {
    openedSurah = surahNumber;
    return [if (lastRead != null) lastRead!];
  }
}

class _EmptyMemorizationStore implements MemorizationStore {
  @override
  Future<List<MemorizationProgram>> getPrograms() async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
