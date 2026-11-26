import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawahku/core/preferences/app_preferences.dart';
import 'package:tilawahku/features/asmaul_husna/data/asmaul_husna_repository.dart';
import 'package:tilawahku/features/asmaul_husna/domain/asmaul_husna_models.dart';
import 'package:tilawahku/features/asmaul_husna/presentation/asmaul_husna_controller.dart';
import 'package:tilawahku/features/asmaul_husna/presentation/asmaul_husna_screen.dart';
import 'package:tilawahku/features/memorization/data/memorization_repository.dart';
import 'package:tilawahku/features/memorization/domain/memorization_models.dart';
import 'package:tilawahku/features/navigation/presentation/main_navigation_screen.dart';
import 'package:tilawahku/features/reading/data/reading_repository.dart';
import 'package:tilawahku/features/tajwid/data/tajwid_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Asmaul Husna bundled dataset validation', () {
    test('contains exactly 99 unique valid entries and valid Quran refs', () {
      final assetFile = File(AsmaulHusnaRepository.assetPath);
      expect(assetFile.existsSync(), isTrue);

      final decoded =
          jsonDecode(assetFile.readAsStringSync()) as Map<String, dynamic>;
      final meta = decoded['_meta'] as Map<String, dynamic>?;
      expect(meta, isNotNull);
      expect((meta!['source'] as String).trim(), isNotEmpty);

      final entries = (decoded['items'] as List<dynamic>)
          .map(
            (item) => AsmaulHusnaEntry.fromJson(item as Map<String, dynamic>),
          )
          .toList(growable: false);

      expect(entries.length, 99);
      final numbers = entries.map((entry) => entry.number).toList();
      expect(numbers, List<int>.generate(99, (index) => index + 1));

      // Validasi rujukan surah:ayat terhadap jumlah ayat resmi pada fixture lokal.
      final preview =
          jsonDecode(
                File('assets/data/quran_web_preview.json').readAsStringSync(),
              )
              as Map<String, dynamic>;
      final surahAyahCounts = <int, int>{
        for (final row in preview['surahs'] as List<dynamic>)
          (row as List<dynamic>)[0] as int: row[3] as int,
      };
      expect(surahAyahCounts.length, 114);

      for (final entry in entries) {
        expect(entry.arabic.trim(), isNotEmpty);
        expect(entry.transliteration.trim(), isNotEmpty);
        expect(entry.meaningId.trim(), isNotEmpty);
        expect(entry.descriptionId.trim(), isNotEmpty);
        for (final ref in entry.quranRefs) {
          final maxAyah = surahAyahCounts[ref.surah];
          expect(
            maxAyah,
            isNotNull,
            reason: 'Surah tidak valid pada #${entry.number}: ${ref.label}',
          );
          expect(
            ref.ayah,
            inInclusiveRange(1, maxAyah!),
            reason: 'Ayat di luar rentang pada #${entry.number}: ${ref.label}',
          );
        }
      }
    });
  });

  group('filterAsmaulHusna', () {
    const sample = [
      AsmaulHusnaEntry(
        number: 1,
        arabic: 'الرَّحْمَٰنُ',
        transliteration: 'Ar-Rahman',
        meaningId: 'Yang Maha Pengasih',
        descriptionId: 'Kasih sayang meliputi seluruh makhluk.',
        quranRefs: [AsmaulHusnaAyahRef(surah: 1, ayah: 3)],
      ),
      AsmaulHusnaEntry(
        number: 67,
        arabic: 'الْأَحَدُ',
        transliteration: 'Al-Ahad',
        meaningId: 'Yang Maha Esa',
        descriptionId: 'Satu-satunya Tuhan.',
        quranRefs: [AsmaulHusnaAyahRef(surah: 112, ayah: 1)],
      ),
    ];

    test('matches by number, normalized transliteration, and meaning', () {
      expect(
        filterAsmaulHusna(
          sample,
          query: '67',
          favoritesOnly: false,
          favorites: const {},
        ).map((e) => e.number),
        [67],
      );
      expect(
        filterAsmaulHusna(
          sample,
          query: 'ar rahman',
          favoritesOnly: false,
          favorites: const {},
        ).map((e) => e.number),
        [1],
      );
      expect(
        filterAsmaulHusna(
          sample,
          query: 'maha esa',
          favoritesOnly: false,
          favorites: const {},
        ).map((e) => e.number),
        [67],
      );
    });

    test('filters favorites when favoritesOnly is true', () {
      final result = filterAsmaulHusna(
        sample,
        query: '',
        favoritesOnly: true,
        favorites: const {67},
      );
      expect(result.map((e) => e.number), [67]);
    });
  });

  group('AsmaulHusnaScreen widget & navigation', () {
    testWidgets('searches, toggles favorites, and opens detail sheet', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final controller = AsmaulHusnaController(
        repository: _InMemoryAsmaulHusnaRepository(),
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: AsmaulHusnaScreen(
            preferences: const AppPreferences(),
            readingRepository: _FakeReadingRepository(),
            controller: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ar-Rahman'), findsOneWidget);
      expect(find.text('Al-Ahad'), findsOneWidget);

      // Search filters list
      await tester.enterText(find.byType(TextField), 'ahad');
      await tester.pumpAndSettle();
      expect(find.text('Al-Ahad'), findsOneWidget);
      expect(find.text('Ar-Rahman'), findsNothing);

      // Bookmark Al-Ahad then clear search and filter favorites
      await tester.tap(find.byTooltip('Simpan favorit'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Hapus pencarian'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Filter favorit'));
      await tester.pumpAndSettle();
      expect(find.text('Al-Ahad'), findsOneWidget);
      expect(find.text('Ar-Rahman'), findsNothing);

      // Open detail bottom sheet
      await tester.tap(find.text('Al-Ahad'));
      await tester.pumpAndSettle();
      expect(find.text('Makna dan penghayatan'), findsOneWidget);
      expect(find.text('QS 112:1'), findsOneWidget);
    });

    testWidgets('Lainnya tab opens Asmaul Husna screen instead of locked item', (
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

      await tester.tap(find.text('Lainnya').last);
      await tester.pumpAndSettle();

      expect(find.text('Asmaul Husna'), findsOneWidget);
      expect(
        find.text('99 nama Allah, makna, dan rujukan ayat'),
        findsOneWidget,
      );

      await tester.tap(find.text('Asmaul Husna'));
      await tester.pumpAndSettle();
      expect(find.byType(AsmaulHusnaScreen), findsOneWidget);
    });
  });
}

class _InMemoryAsmaulHusnaRepository extends AsmaulHusnaRepository {
  Set<int> _saved = <int>{};

  @override
  Future<List<AsmaulHusnaEntry>> loadEntries() async => const [
    AsmaulHusnaEntry(
      number: 1,
      arabic: 'الرَّحْمَٰنُ',
      transliteration: 'Ar-Rahman',
      meaningId: 'Yang Maha Pengasih',
      descriptionId: 'Kasih sayang meliputi seluruh makhluk.',
      quranRefs: [AsmaulHusnaAyahRef(surah: 1, ayah: 3)],
    ),
    AsmaulHusnaEntry(
      number: 67,
      arabic: 'الْأَحَدُ',
      transliteration: 'Al-Ahad',
      meaningId: 'Yang Maha Esa',
      descriptionId: 'Satu-satunya Tuhan.',
      quranRefs: [AsmaulHusnaAyahRef(surah: 112, ayah: 1)],
    ),
  ];

  @override
  Future<Set<int>> loadFavorites() async => {..._saved};

  @override
  Future<void> saveFavorites(Set<int> favorites) async {
    _saved = {...favorites};
  }
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
