import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawahku/core/preferences/app_preferences.dart';
import 'package:tilawahku/features/settings/presentation/settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('SettingsScreen displays grouped sections, toggles preferences, and scales live Arabic preview', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'arabic_text_scale': 1.0});
    const preferences = AppPreferences();
    bool? lastDarkMode;

    await tester.pumpWidget(
      MaterialApp(
        home: SettingsScreen(
          preferences: preferences,
          onSetDarkMode: (value) => lastDarkMode = value,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tampilan'), findsOneWidget);
    expect(find.text('Ukuran teks Arab'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Audio dan penyimpanan'), 200);
    expect(find.text('Audio dan penyimpanan'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Informasi aplikasi'), 200);
    expect(find.text('Informasi aplikasi'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Mode gelap'), -200);
    await tester.ensureVisible(find.text('Mode gelap'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mode gelap'));
    await tester.pumpAndSettle();
    expect(lastDarkMode, isTrue);
    expect(await preferences.darkMode, isTrue);

    expect(find.text('100%'), findsOneWidget);
    const basmalah = 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ';
    final initialPreview = tester.widget<Text>(find.text(basmalah));
    expect(initialPreview.style?.fontFamily, 'AmiriQuran');
    expect(initialPreview.style?.fontSize, 24.0);

    await tester.tap(find.byTooltip('Perbesar teks Arab'));
    await tester.pumpAndSettle();
    expect(find.text('110%'), findsOneWidget);
    expect(await preferences.arabicTextScale, closeTo(1.1, 0.001));
    final enlargedPreview = tester.widget<Text>(find.text(basmalah));
    expect(enlargedPreview.style?.fontSize, closeTo(26.4, 0.01));

    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();
    expect(find.text('100%'), findsOneWidget);
    expect(await preferences.arabicTextScale, closeTo(1.0, 0.001));
  });
}
