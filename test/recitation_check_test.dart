import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawahku/core/preferences/app_preferences.dart';
import 'package:tilawahku/features/assessment/data/asr_model_manager.dart';
import 'package:tilawahku/features/assessment/data/asr_model_release.dart';
import 'package:tilawahku/features/assessment/data/asr_runtime.dart';
import 'package:tilawahku/features/assessment/data/recitation_playback.dart';
import 'package:tilawahku/features/assessment/data/recitation_recorder.dart';
import 'package:tilawahku/features/assessment/domain/arabic_comparison.dart';
import 'package:tilawahku/features/assessment/domain/recitation_audio.dart';
import 'package:tilawahku/features/assessment/presentation/recitation_check_screen.dart';
import 'package:tilawahku/features/memorization/data/memorization_repository.dart';
import 'package:tilawahku/features/memorization/domain/memorization_models.dart';
import 'package:tilawahku/features/navigation/presentation/main_navigation_screen.dart';
import 'package:tilawahku/features/reading/data/reading_repository.dart';
import 'package:tilawahku/features/tajwid/data/tajwid_repository.dart';

const _fatihah1 = 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ';
const _fatihah2 = 'ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَٰلَمِينَ';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('alignArabicAyahWords', () {
    test('marks all Utsmani words correct with full harakat preserved', () {
      final alignment = alignArabicAyahWords(
        _fatihah1,
        'بسم الله الرحمن الرحيم',
      );

      expect(alignment.assessable, isTrue);
      expect(alignment.verdict, RecitationVerdict.accurate);
      expect(alignment.words, hasLength(4));
      expect(alignment.words[0].displayWord, 'بِسْمِ');
      expect(alignment.words[1].displayWord, 'ٱللَّهِ');
      expect(
        alignment.words.every((w) => w.verdict == AyahWordVerdict.correct),
        isTrue,
      );
      expect(alignment.extraWords, isEmpty);
    });

    test('highlights substituted and missing words in original reading order', () {
      final alignment = alignArabicAyahWords(
        _fatihah1,
        'بسم الله الغفور',
      );

      expect(alignment.assessable, isTrue);
      expect(alignment.verdict, RecitationVerdict.needsCorrection);
      expect(alignment.words[0].verdict, AyahWordVerdict.correct);
      expect(alignment.words[1].verdict, AyahWordVerdict.correct);
      expect(
        alignment.words.any((w) => w.verdict == AyahWordVerdict.substituted),
        isTrue,
      );
      expect(
        alignment.words.any((w) => w.verdict == AyahWordVerdict.missing),
        isTrue,
      );
      final substituted = alignment.words.firstWhere(
        (w) => w.verdict == AyahWordVerdict.substituted,
      );
      expect(substituted.recognizedWord, 'الغفور');
    });

    test('handles spellingMap multi-word expansion without breaking display tokens', () {
      const targetWord = 'يَٰٓأَيُّهَا';
      final alignment = alignArabicAyahWords(
        '$targetWord ٱلنَّاسُ',
        'يا ايها الناس',
        spellingMap: {normalizeArabic(targetWord): 'يا ايها'},
      );

      expect(alignment.assessable, isTrue);
      expect(alignment.verdict, RecitationVerdict.accurate);
      expect(alignment.words, hasLength(2));
      expect(alignment.words[0].displayWord, targetWord);
      expect(alignment.words[0].verdict, AyahWordVerdict.correct);
      expect(alignment.words[1].verdict, AyahWordVerdict.correct);
    });

    test('marks very short transcripts unscorable', () {
      final alignment = alignArabicAyahWords(_fatihah1, 'بسم');
      expect(alignment.assessable, isFalse);
      expect(alignment.verdict, RecitationVerdict.unscorable);
    });
  });

  group('LocalAsrModelManager', () {
    test('downloads official root files without /asr/ prefix, verifies SHA-256, and deletes cache', () async {
      final previousOverrides = HttpOverrides.current;
      HttpOverrides.global = null;
      try {
        final tempDir = Directory.systemTemp.createTempSync('tilawahku-mgr-test');
        final modelBytes = Uint8List.fromList(List.generate(2048, (i) => i % 251));
        final tokenBytes = Uint8List.fromList('a\nb\nc\n'.codeUnits);
        final release = AsrModelRelease(
          id: 'test-hf',
          version: 'v1',
          directory: 'asr',
          model: AsrModelFile(
            name: 'model.int8.onnx',
            byteLength: modelBytes.length,
            sha256Hex: sha256.convert(modelBytes).toString(),
          ),
          tokens: AsrModelFile(
            name: 'tokens.txt',
            byteLength: tokenBytes.length,
            sha256Hex: sha256.convert(tokenBytes).toString(),
          ),
        );

        final requestedPaths = <String>[];
        final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        server.listen((request) {
          requestedPaths.add(request.uri.path);
          if (request.uri.path == '/resolve/main/model.int8.onnx') {
            request.response.add(modelBytes);
          } else if (request.uri.path == '/resolve/main/tokens.txt') {
            request.response.add(tokenBytes);
          } else {
            request.response.statusCode = HttpStatus.notFound;
          }
          request.response.close();
        });

        try {
          final manager = LocalAsrModelManager(
            release: release,
            directory: tempDir,
            downloadBaseUrl: Uri.parse(
              'http://127.0.0.1:${server.port}/resolve/main/',
            ),
            includeReleaseDirectory: false,
            platformSupportedOverride: true,
          );

          final initial = await manager.checkStatus();
          expect(initial.state, AsrModelInstallState.notDownloaded);

          await manager.downloadModel();
          expect(requestedPaths, [
            '/resolve/main/model.int8.onnx',
            '/resolve/main/tokens.txt',
          ]);

          final ready = await manager.checkStatus();
          expect(ready.isReady, isTrue);

          await manager.deleteModel();
          final afterDelete = await manager.checkStatus();
          expect(afterDelete.state, AsrModelInstallState.notDownloaded);
        } finally {
          await server.close(force: true);
          if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
        }
      } finally {
        HttpOverrides.global = previousOverrides;
      }
    });
  });

  group('RecitationCheckScreen widgets & navigation', () {
    testWidgets('downloads model, scores recitation with word highlights, and switches ayah', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final modelRepo = _FakeAsrModelRepository();
      final runtime = _FakeAsrRuntime('بسم الله الغفور الرحيم');
      final readingRepo = _FakeReadingRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: RecitationCheckScreen(
            readingRepository: readingRepo,
            preferences: const AppPreferences(),
            runtime: runtime,
            createCapture: _FakeCapture.new,
            createPlayback: _FakePlayback.new,
            modelRepository: modelRepo,
            loadSpellingMap: () async => const {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially offers official model download
      expect(find.text('Aktifkan koreksi kata otomatis (offline)'), findsOneWidget);
      await tester.tap(find.text('Unduh model resmi (36.0 MB)'));
      await tester.pumpAndSettle();
      expect(find.text('Model koreksi offline siap'), findsOneWidget);

      // Start and stop recording -> shows highlighted word feedback & verdict
      await tester.scrollUntilVisible(find.text('Rekam bacaan'), 200);
      await tester.ensureVisible(find.text('Rekam bacaan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rekam bacaan'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Berhenti & nilai'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Berhenti & nilai'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Salah / tertukar'), findsWidgets);
      expect(find.text('Perbaikan bacaan'), findsOneWidget);
      expect(find.text('Terbaca'), findsWidgets);
      expect(find.text('Seharusnya'), findsWidgets);
      expect(find.text('الغفور'), findsWidgets);

      // Switch to next ayah resets scored highlight cleanly
      await tester.scrollUntilVisible(
        find.byTooltip('Ayat berikutnya'),
        -200,
      );
      await tester.ensureVisible(find.byTooltip('Ayat berikutnya'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Ayat berikutnya'));
      await tester.pumpAndSettle();
      expect(find.text('Al-Fatihah 1:2'), findsOneWidget);
      expect(find.text('Perbaikan bacaan'), findsNothing);
    });

    testWidgets('opens Koreksi bacaan from Aktivitas tab', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final readingRepo = _FakeReadingRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: MainNavigationScreen(
            preferences: const AppPreferences(),
            onSetDarkMode: (_) {},
            readingRepository: readingRepo,
            memorizationRepository: MemorizationRepository(
              store: _EmptyMemorizationStore(),
              readingRepository: readingRepo,
            ),
            tajwidRepository: TajwidRepository(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Aktivitas').last);
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Koreksi bacaan'),
        200,
        scrollable: find.descendant(
          of: find.byKey(const ValueKey('activities-options-list')),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.tap(find.text('Koreksi bacaan'));
      await tester.pumpAndSettle();

      expect(find.text('Al-Fatihah 1:1'), findsOneWidget);
    });
  });
}

class _FakeAsrModelRepository implements AsrModelRepository {
  bool _ready = false;

  @override
  Future<AsrModelStatus> checkStatus() async => AsrModelStatus(
    state: _ready
        ? AsrModelInstallState.ready
        : AsrModelInstallState.notDownloaded,
    totalBytes: 36 * 1024 * 1024,
    downloadedBytes: _ready ? 36 * 1024 * 1024 : 0,
  );

  @override
  Future<void> downloadModel({
    void Function(double fraction, String message)? onProgress,
  }) async {
    onProgress?.call(0.5, 'Mengunduh model...');
    _ready = true;
    onProgress?.call(1.0, 'Model siap');
  }

  @override
  Future<void> deleteModel() async {
    _ready = false;
  }
}

class _FakeAsrRuntime implements AsrRuntime {
  _FakeAsrRuntime(this.transcript);

  final String transcript;

  @override
  Future<void> prepare({AsrProgress? onProgress}) async {}

  @override
  Future<String> recognize(RecitationAudio audio) async => transcript;

  @override
  void dispose() {}
}

class _FakeCapture implements RecitationCapture {
  @override
  Future<void> start() async {}

  @override
  Future<RecitationAudio> stop() async => RecitationAudio(Float32List(32000));

  @override
  Future<void> cancel() async {}

  @override
  Future<void> dispose() async {}
}

class _FakePlayback implements RecitationPlayback {
  @override
  Future<void> play(RecitationAudio audio, {void Function()? onCompleted}) async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}

class _FakeReadingRepository extends ReadingRepository {
  @override
  Future<List<Surah>> getSurahs() async => const [
    Surah(
      id: 1,
      nameArabic: 'الفاتحة',
      nameIndonesian: 'Al-Fatihah',
      ayahCount: 7,
    ),
  ];

  @override
  Future<List<AyahEntry>> getAyahsForSurah(int surahNumber, {int? limit}) async => const [
    AyahEntry(
      globalNumber: 1,
      surahNumber: 1,
      ayahNumber: 1,
      juzNumber: 1,
      pageNumber: 1,
      uthmaniText: _fatihah1,
      surahNameIndonesian: 'Al-Fatihah',
      indonesianTranslation: 'Dengan nama Allah Yang Maha Pengasih lagi Maha Penyayang.',
    ),
    AyahEntry(
      globalNumber: 2,
      surahNumber: 1,
      ayahNumber: 2,
      juzNumber: 1,
      pageNumber: 1,
      uthmaniText: _fatihah2,
      surahNameIndonesian: 'Al-Fatihah',
      indonesianTranslation: 'Segala puji bagi Allah, Tuhan seluruh alam.',
    ),
  ];

  @override
  Future<AyahEntry?> getProgress(String voiceId) async => null;
}

class _EmptyMemorizationStore implements MemorizationStore {
  @override
  Future<List<MemorizationProgram>> getPrograms() async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
