import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawahku/core/preferences/app_preferences.dart';
import 'package:tilawahku/features/voices/data/voice_catalog.dart';
import 'package:tilawahku/features/voices/data/voice_preview_controller.dart';
import 'package:tilawahku/features/voices/presentation/voice_selection_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('qari list identifies and selects surah-based audio', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final controller = VoicePreviewController(
      player: _NoopVoicePreviewPlayer(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: VoiceSelectionScreen(
          preferences: const AppPreferences(),
          onSetDarkMode: (_) {},
          previewController: controller,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Audio Per Ayat'), findsWidgets);
    final luhaidanName = find.text('Muhammad Al-Luhaidan');
    await tester.scrollUntilVisible(
      luhaidanName,
      500,
      scrollable: find.byType(Scrollable).first,
    );
    final luhaidanCard = find.byKey(
      const ValueKey('voice-selection-muhammad-al-luhaidan'),
    );
    await tester.ensureVisible(luhaidanCard);
    await tester.pumpAndSettle();
    expect(find.text('Audio Per Surah'), findsOneWidget);
    expect(
      find.textContaining(
        'Memutar satu surah secara utuh. Pengulangan ayat atau rentang ayat',
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('voice-preview-muhammad-al-luhaidan')),
      findsNothing,
    );
    expect(find.text('Pilih qari terlebih dahulu'), findsOneWidget);
    await tester.tap(luhaidanCard);
    await tester.pump();
    expect(find.text('Pilih suara'), findsWidgets);
    expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
    final selectedContainer = tester.widget<AnimatedContainer>(luhaidanCard);
    final decoration = selectedContainer.decoration! as BoxDecoration;
    expect(decoration.border, isNotNull);
    expect(decoration.border!.top.width, 2.0);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  testWidgets('active qari disables CTA as Dipilih until another qari is tapped', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'selected_voice_id': 'husary'});
    final controller = VoicePreviewController(
      player: _NoopVoicePreviewPlayer(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: VoiceSelectionScreen(
          preferences: const AppPreferences(),
          onSetDarkMode: (_) {},
          allowBack: true,
          catalog: const _TestVoiceCatalog(),
          previewController: controller,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Aktif'), findsNothing);
    expect(find.text('Dipilih'), findsOneWidget);
    final disabledButton = tester.widget<FilledButton>(
      find.byType(FilledButton),
    );
    expect(disabledButton.onPressed, isNull);

    await tester.tap(find.byKey(const ValueKey('voice-selection-minshawi')));
    await tester.pump();
    expect(find.text('Dipilih'), findsNothing);
    final enabledButton = tester.widget<FilledButton>(
      find.byType(FilledButton),
    );
    expect(enabledButton.onPressed, isNotNull);

    await tester.tap(find.byKey(const ValueKey('voice-selection-husary')));
    await tester.pump();
    expect(find.text('Dipilih'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}

class _NoopVoicePreviewPlayer implements VoicePreviewPlayer {
  @override
  Future<void> stop() async {}

  @override
  Future<void> setUrl(String url) async {}

  @override
  Future<void> play() async {}

  @override
  Future<void> dispose() async {}
}

class _TestVoiceCatalog extends VoiceCatalog {
  const _TestVoiceCatalog();

  @override
  Future<List<Voice>> load() async => const [
    Voice(
      id: 'husary',
      name: 'Mahmoud Khalil Al-Husary',
      style: 'Murattal',
      status: VoiceStatus.active,
      audioMode: VoiceAudioMode.ayah,
      editionId: 'ar.husary',
      bitrateKbps: 128,
      attribution: 'Test',
    ),
    Voice(
      id: 'minshawi',
      name: 'Muhammad Siddiq Al-Minshawi',
      style: 'Murattal',
      status: VoiceStatus.active,
      audioMode: VoiceAudioMode.ayah,
      editionId: 'ar.minshawi',
      bitrateKbps: 128,
      attribution: 'Test',
    ),
  ];
}
