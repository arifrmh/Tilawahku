import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawahku/core/preferences/app_preferences.dart';
import 'package:tilawahku/features/doa_dzikir/data/doa_dzikir_repository.dart';
import 'package:tilawahku/features/doa_dzikir/domain/doa_dzikir_models.dart';
import 'package:tilawahku/features/doa_dzikir/presentation/doa_dzikir_screen.dart';
import 'package:tilawahku/features/memorization/data/memorization_repository.dart';
import 'package:tilawahku/features/memorization/domain/memorization_models.dart';
import 'package:tilawahku/features/navigation/presentation/main_navigation_screen.dart';
import 'package:tilawahku/features/reading/data/reading_repository.dart';
import 'package:tilawahku/features/tajwid/data/tajwid_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Doa dan dzikir dataset validation', () {
    test('covers harian, pagi, and petang with verified non-empty references', () {
      final raw = File(DoaDzikirRepository.assetPath).readAsStringSync();
      expect(raw.contains('—'), isFalse, reason: 'Avoid em dash in copy');

      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      expect(decoded['_meta'], isA<Map<String, dynamic>>());

      final items = (decoded['items'] as List<dynamic>)
          .map((item) => DoaDzikirEntry.fromJson(item as Map<String, dynamic>))
          .toList();

      expect(items.length, greaterThanOrEqualTo(20));
      expect(items.map((item) => item.id).toSet().length, items.length);
      expect(
        items.map((item) => item.category).toSet(),
        DoaDzikirCategory.values.toSet(),
      );

      for (final item in items) {
        expect(item.id, isNotEmpty);
        expect(item.title, isNotEmpty);
        expect(item.arabic, isNotEmpty);
        expect(item.transliteration, isNotEmpty);
        expect(item.translationId, isNotEmpty);
        expect(item.repeatCount, greaterThanOrEqualTo(1));
        expect(item.sourceRef, isNotEmpty);
      }
    });
  });

  group('filterDoaDzikir & repository', () {
    test('filters by category, query, and favorite ids', () async {
      SharedPreferences.setMockInitialValues({});
      final repository = DoaDzikirRepository(bundle: _TestAssetBundle());
      final items = await repository.loadEntries();

      final pagi = filterDoaDzikir(items, category: DoaDzikirCategory.pagi);
      expect(pagi, isNotEmpty);
      expect(
        pagi.every((item) => item.category == DoaDzikirCategory.pagi),
        isTrue,
      );

      final byQuery = filterDoaDzikir(items, query: 'Sayyidul Istighfar');
      expect(byQuery.length, greaterThanOrEqualTo(2));

      await repository.saveFavorites({'doa-keluar-rumah', 'pagi-ayat-kursi'});
      expect(await repository.loadFavorites(), {
        'doa-keluar-rumah',
        'pagi-ayat-kursi',
      });
    });
  });

  group('DoaDzikirScreen widget & navigation', () {
    testWidgets('filters by category, counts repeat chip, and filters favorites', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final repository = DoaDzikirRepository(bundle: _TestAssetBundle());

      await tester.pumpWidget(
        MaterialApp(
          home: DoaDzikirScreen(
            preferences: const AppPreferences(),
            repository: repository,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Doa dan dzikir'), findsOneWidget);
      expect(find.text('Doa Sebelum Makan'), findsOneWidget);

      await tester.tap(find.text('Dzikir Pagi'));
      await tester.pumpAndSettle();
      expect(find.text('Ayat Kursi'), findsOneWidget);
      expect(find.text('Doa Sebelum Makan'), findsNothing);

      await tester.enterText(find.byType(TextField), 'Perlindungan');
      await tester.pumpAndSettle();
      expect(find.text('Dzikir Perlindungan di Pagi Hari'), findsOneWidget);

      final repeatChip = find.byKey(const ValueKey('doa-repeat-pagi-bismillahilladzi'));
      expect(find.text('Dibaca 3x'), findsOneWidget);
      await tester.tap(repeatChip);
      await tester.pumpAndSettle();
      expect(find.text('1/3'), findsOneWidget);

      await tester.tap(find.byTooltip('Simpan bacaan'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Hapus pencarian'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Semua'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Tampilkan bacaan tersimpan'));
      await tester.pumpAndSettle();

      expect(find.text('Dzikir Perlindungan di Pagi Hari'), findsOneWidget);
      expect(find.text('Doa Sebelum Makan'), findsNothing);
    });

    testWidgets('Aktivitas tab opens Doa dan dzikir screen', (tester) async {
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
      await tester.tap(find.text('Doa dan dzikir'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(DoaDzikirScreen), findsOneWidget);
    });
  });
}

class _TestAssetBundle extends CachingAssetBundle {
  @override
  Future<String> loadString(String key, {bool cache = true}) async =>
      File(key).readAsStringSync();

  @override
  Future<ByteData> load(String key) async {
    final bytes = File(key).readAsBytesSync();
    return ByteData.sublistView(bytes);
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
