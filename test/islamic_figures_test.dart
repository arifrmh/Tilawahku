import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawahku/core/preferences/app_preferences.dart';
import 'package:tilawahku/features/islamic_figures/data/islamic_figures_repository.dart';
import 'package:tilawahku/features/islamic_figures/domain/islamic_figures_models.dart';
import 'package:tilawahku/features/islamic_figures/presentation/islamic_figures_screen.dart';
import 'package:tilawahku/features/memorization/data/memorization_repository.dart';
import 'package:tilawahku/features/memorization/domain/memorization_models.dart';
import 'package:tilawahku/features/navigation/presentation/main_navigation_screen.dart';
import 'package:tilawahku/features/reading/data/reading_repository.dart';
import 'package:tilawahku/features/tajwid/data/tajwid_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Islamic figures dataset validation', () {
    test('covers all 5 categories with verified non-empty fields and references', () {
      final raw = File(
        IslamicFiguresRepository.assetPath,
      ).readAsStringSync();
      expect(raw.contains('—'), isFalse, reason: 'Avoid em dash in copy');

      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      expect(decoded['_meta'], isA<Map<String, dynamic>>());

      final items = (decoded['items'] as List<dynamic>)
          .map((item) => IslamicFigure.fromJson(item as Map<String, dynamic>))
          .toList();

      expect(items.length, greaterThanOrEqualTo(15));
      expect(items.map((item) => item.id).toSet().length, items.length);
      expect(
        items.map((item) => item.category).toSet(),
        FigureCategory.values.toSet(),
      );

      for (final item in items) {
        expect(item.id, isNotEmpty);
        expect(item.name, isNotEmpty);
        expect(item.arabicName, isNotEmpty);
        expect(item.epithet, isNotEmpty);
        expect(item.eraLabel, isNotEmpty);
        expect(item.summary, isNotEmpty);
        expect(item.monogram, isNotEmpty);
        expect(item.biographySections, isNotEmpty);
        for (final section in item.biographySections) {
          expect(section.title, isNotEmpty);
          expect(section.body, isNotEmpty);
        }
        expect(item.keyLessons, isNotEmpty);
        expect(item.references, isNotEmpty);
      }
    });
  });

  group('filterIslamicFigures & repository', () {
    test('filters by category, query, and favorite ids', () async {
      SharedPreferences.setMockInitialValues({});
      final repository = IslamicFiguresRepository();
      final items = await repository.loadFigures();

      final scientists = filterIslamicFigures(
        items,
        category: FigureCategory.ilmuwan,
      );
      expect(scientists, isNotEmpty);
      expect(
        scientists.every((item) => item.category == FigureCategory.ilmuwan),
        isTrue,
      );

      final byEpithet = filterIslamicFigures(items, query: 'aljabar');
      expect(byEpithet.map((item) => item.id), contains('al-khawarizmi'));

      final byFavorites = filterIslamicFigures(
        items,
        favoriteIds: {'ibnu-sina'},
      );
      expect(byFavorites.map((item) => item.id), ['ibnu-sina']);

      await repository.saveFavorites({'ibnu-sina', 'kh-ahmad-dahlan'});
      expect(await repository.loadFavorites(), {'ibnu-sina', 'kh-ahmad-dahlan'});
    });
  });

  group('IslamicFiguresScreen widget & navigation', () {
    testWidgets('filters, bookmarks, and opens detail screen with references', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final repository = IslamicFiguresRepository(bundle: _TestAssetBundle());

      await tester.pumpWidget(
        MaterialApp(
          home: IslamicFiguresScreen(
            preferences: const AppPreferences(),
            repository: repository,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tokoh Islam'), findsOneWidget);
      expect(find.text('Nabi Muhammad SAW'), findsOneWidget);

      await tester.drag(find.byType(ListView).first, const Offset(-300, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tokoh Nusantara'));
      await tester.pumpAndSettle();
      expect(find.text('Sunan Kalijaga'), findsOneWidget);
      expect(find.text('Nabi Muhammad SAW'), findsNothing);

      await tester.enterText(find.byType(TextField), 'Dahlan');
      await tester.pumpAndSettle();
      expect(find.text('KH. Ahmad Dahlan'), findsOneWidget);
      expect(find.text('Sunan Kalijaga'), findsNothing);

      await tester.tap(find.text('KH. Ahmad Dahlan'));
      await tester.pumpAndSettle();

      expect(find.text('Ringkasan'), findsOneWidget);
      expect(find.text('A+'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Rujukan sejarah'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Keteladanan utama'), findsOneWidget);
      expect(find.text('Rujukan sejarah'), findsOneWidget);

      await tester.tap(find.byTooltip('Simpan tokoh'));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Hapus pencarian'));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView).first, const Offset(300, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Semua'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Tampilkan tokoh tersimpan'));
      await tester.pumpAndSettle();

      expect(find.text('KH. Ahmad Dahlan'), findsOneWidget);
      expect(find.text('Nabi Muhammad SAW'), findsNothing);
    });

    testWidgets('More tab opens Tokoh Islam screen', (tester) async {
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
      await tester.drag(
        find.byKey(const ValueKey('more-options-list')),
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tokoh Islam'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(IslamicFiguresScreen), findsOneWidget);
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
