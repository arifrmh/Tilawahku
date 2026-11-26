import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawahku/core/preferences/app_preferences.dart';
import 'package:tilawahku/features/reading/data/reading_repository.dart';
import 'package:tilawahku/features/reading/presentation/home_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HomeScreen (Tab Al-Qur’an)', () {
    testWidgets('displays Mulai Membaca and AmiriQuran Arabic surah names when no progress exists', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            preferences: const AppPreferences(),
            repository: _FakeReadingRepository(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mulai Membaca'), findsOneWidget);
      expect(find.text('Cari surah, ayat, atau terjemahan...'), findsOneWidget);
      expect(find.widgetWithText(ActionChip, 'Al-Kahfi'), findsOneWidget);
      expect(find.widgetWithText(ActionChip, 'Al-Mulk'), findsOneWidget);

      final arabicFinder = find.text('الفاتحة');
      expect(arabicFinder, findsOneWidget);
      final arabicText = tester.widget<Text>(arabicFinder);
      expect(arabicText.style?.fontFamily, 'AmiriQuran');
    });

    testWidgets('displays populated reading progress hero with juz and page count', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({'selected_voice_id': 'ar.alafasy'});

      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            preferences: const AppPreferences(),
            repository: _FakeReadingRepository(
              lastRead: const AyahEntry(
                globalNumber: 262,
                surahNumber: 2,
                ayahNumber: 255,
                juzNumber: 3,
                pageNumber: 42,
                uthmaniText: 'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ',
                surahNameIndonesian: 'Al-Baqarah',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Lanjutkan Terakhir'), findsOneWidget);
      expect(
        find.text('Al-Baqarah 2:255 · Juz 3 · Hal. 42/604'),
        findsOneWidget,
      );
    });

    testWidgets('switches to Juz tab showing surah range and page badges', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            preferences: const AppPreferences(),
            repository: _FakeReadingRepository(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Juz'));
      await tester.pumpAndSettle();

      expect(find.text('Juz 1'), findsOneWidget);
      expect(find.text('Al-Fatihah 1 - Al-Baqarah 141'), findsOneWidget);
      expect(find.text('Hal. 1-21'), findsOneWidget);
    });

    testWidgets('opens ReadingScreen from quick surah chip and SearchScreen from search trigger', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final repo = _FakeReadingRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            preferences: const AppPreferences(),
            repository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cari surah, ayat, atau terjemahan...'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Cari'), findsWidgets);

      Navigator.of(tester.element(find.byType(Scaffold).last)).pop();
      await tester.pumpAndSettle();

      final alMulkChip = find.widgetWithText(ActionChip, 'Al-Mulk');
      await tester.ensureVisible(alMulkChip);
      await tester.pumpAndSettle();
      await tester.tap(alMulkChip);
      await tester.pumpAndSettle();
      expect(repo.lastOpenedSurah, 67);
    });

    testWidgets('validates page range in jump-to-page dialog and opens target page', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final repo = _FakeReadingRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            preferences: const AppPreferences(),
            repository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Lompat ke halaman'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '999');
      await tester.tap(find.text('Buka'));
      await tester.pumpAndSettle();
      expect(
        find.text('Masukkan nomor halaman antara 1 sampai 604.'),
        findsOneWidget,
      );

      await tester.enterText(find.byType(TextField), '250');
      await tester.tap(find.text('Buka'));
      await tester.pumpAndSettle();
      expect(repo.lastOpenedPage, 250);
    });
  });
}

class _FakeReadingRepository extends ReadingRepository {
  _FakeReadingRepository({this.lastRead});

  final AyahEntry? lastRead;
  int? lastOpenedSurah;
  int? lastOpenedPage;

  @override
  Future<List<Surah>> getSurahs() async => const [
    Surah(
      id: 1,
      nameArabic: 'الفاتحة',
      nameIndonesian: 'Al-Fatihah',
      ayahCount: 7,
    ),
    Surah(
      id: 67,
      nameArabic: 'الملك',
      nameIndonesian: 'Al-Mulk',
      ayahCount: 30,
    ),
  ];

  @override
  Future<List<AyahEntry>> getAyahsForSurah(int surahNumber, {int? limit}) async {
    lastOpenedSurah = surahNumber;
    return [
      AyahEntry(
        globalNumber: 1,
        surahNumber: surahNumber,
        ayahNumber: 1,
        juzNumber: 1,
        pageNumber: 1,
        uthmaniText: 'بِسْمِ ٱللَّهِ',
        surahNameIndonesian: 'Surah $surahNumber',
      ),
    ];
  }

  @override
  Future<List<AyahEntry>> getAyahsForPage(int pageNumber) async {
    lastOpenedPage = pageNumber;
    return [
      AyahEntry(
        globalNumber: 100,
        surahNumber: 2,
        ayahNumber: 93,
        juzNumber: 13,
        pageNumber: pageNumber,
        uthmaniText: 'قُلْ',
        surahNameIndonesian: 'Al-Baqarah',
      ),
    ];
  }

  @override
  Future<AyahEntry?> getProgress(String voiceId) async => lastRead;
}
