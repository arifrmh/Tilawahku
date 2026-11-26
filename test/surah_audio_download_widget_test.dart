import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawahku/core/preferences/app_preferences.dart';
import 'package:tilawahku/features/download/data/audio_download_manager.dart';
import 'package:tilawahku/features/download/data/audio_package_repository.dart';
import 'package:tilawahku/features/download/data/surah_audio_repository.dart';
import 'package:tilawahku/features/download/presentation/download_screen.dart';
import 'package:tilawahku/features/player/data/audio_repository.dart';
import 'package:tilawahku/features/voices/data/voice_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('surah-based qari is not offered ayah-based offline downloads', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DownloadScreen(preferences: const _LuhaidanPreferences()),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Unduhan offline belum tersedia untuk sumber ini.'),
      findsOneWidget,
    );
    expect(find.text('Juz'), findsNothing);
    expect(find.text('Surah'), findsNothing);
  });

  testWidgets('unselected voice shows empty state without Bad state error', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DownloadScreen(
          preferences: const _NoVoicePreferences(),
          catalog: const _TestVoiceCatalog(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Belum ada qari dipilih'), findsOneWidget);
    expect(find.text('Pilih suara qari'), findsOneWidget);
    expect(find.textContaining('Bad state'), findsNothing);
    expect(find.text('Juz'), findsNothing);
    expect(find.text('Surah'), findsNothing);
  });

  testWidgets(
    'zero downloaded audio renders 30 juz and 114 surah packages cleanly without Bad state',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DownloadScreen(
            preferences: const _AyahVoicePreferences('abdulbasit'),
            catalog: const _TestVoiceCatalog(),
            packageRepository: _ZeroAudioPackageRepository(),
            surahPackageRepository: _ZeroSurahAudioRepository(),
            downloadManager: AudioDownloadManager(
              audioRepository: _NoopAudioRepository(),
              packageRepository: _ZeroAudioPackageRepository(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Bad state'), findsNothing);
      expect(find.text('Abdul Basit Abdus-Samad'), findsOneWidget);
      expect(find.textContaining('0/30 juz'), findsOneWidget);
      expect(
        find.text('Belum ada audio tersimpan · Streaming tetap aktif saat online'),
        findsOneWidget,
      );
      expect(find.text('Juz 1'), findsOneWidget);
      expect(find.text('148 ayat · Belum diunduh'), findsOneWidget);

      await tester.tap(find.text('Surah'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Bad state'), findsNothing);
      expect(find.text('Al-Fatihah'), findsOneWidget);
      expect(find.text('7 ayat · Belum diunduh'), findsOneWidget);
    },
  );
}

class _TestVoiceCatalog extends VoiceCatalog {
  const _TestVoiceCatalog();

  @override
  Future<List<Voice>> load() async => const [
    Voice(
      id: 'abdulbasit',
      name: 'Abdul Basit Abdus-Samad',
      style: 'murattal',
      status: VoiceStatus.active,
      audioMode: VoiceAudioMode.ayah,
      editionId: 'ar.abdulsamad',
      bitrateKbps: 64,
      attribution: 'AlQuran.cloud',
      avatarAsset: 'assets/voices/abdulbasit.png',
    ),
    Voice(
      id: 'muhammad-al-luhaidan',
      name: 'Muhammad Al-Luhaidan',
      style: 'murattal',
      status: VoiceStatus.active,
      audioMode: VoiceAudioMode.surah,
      editionId: 'ar.muhammadalluhaidan',
      bitrateKbps: 128,
      attribution: 'AlQuran.cloud',
    ),
  ];
}

class _LuhaidanPreferences extends AppPreferences {
  const _LuhaidanPreferences();

  @override
  Future<String?> get selectedVoiceId async => 'muhammad-al-luhaidan';
}

class _NoVoicePreferences extends AppPreferences {
  const _NoVoicePreferences();

  @override
  Future<String?> get selectedVoiceId async => null;
}

class _AyahVoicePreferences extends AppPreferences {
  const _AyahVoicePreferences(this.voiceId);

  final String voiceId;

  @override
  Future<String?> get selectedVoiceId async => voiceId;
}

class _NoopAudioRepository extends AudioRepository {}

class _ZeroAudioPackageRepository extends AudioPackageRepository {
  @override
  Future<void> recoverInterruptedDownloads(String voiceId) async {}

  @override
  Future<List<AudioPackage>> getPackages(String voiceId) async => List.generate(
    30,
    (index) => AudioPackage(
      voiceId: voiceId,
      juz: index + 1,
      status: AudioPackageStatus.notDownloaded,
      totalAyah: index == 0 ? 148 : 200,
      downloadedAyah: 0,
      totalBytes: 0,
      downloadedBytes: 0,
    ),
  );
}

class _ZeroSurahAudioRepository extends SurahAudioRepository {
  @override
  Future<List<SurahAudioPackage>> getPackages(String voiceId) async =>
      List.generate(
        114,
        (index) => SurahAudioPackage(
          voiceId: voiceId,
          surahNumber: index + 1,
          surahName: index == 0 ? 'Al-Fatihah' : 'Surah ${index + 1}',
          totalAyahs: index == 0 ? 7 : 10,
          downloadedAyahs: 0,
          downloadedBytes: 0,
        ),
      );
}
