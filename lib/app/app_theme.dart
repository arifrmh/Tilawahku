import 'package:flutter/material.dart';

abstract final class AppColors {
  static const navy = Color(0xFF132A4C);
  static const darkNavy = Color(0xFF132A4C);
  static const gold = Color(0xFFE6B325);
  static const parchment = Color(0xFFEDEAE0);
  static const blue = Color(0xFF2C4870);
  static const translation = blue;
  static const lightSurface = parchment;
}

abstract final class AppTheme {
  static ThemeData get light => _buildTheme(
    brightness: Brightness.light,
    foreground: AppColors.navy,
  );

  static ThemeData get dark => _buildTheme(
    brightness: Brightness.dark,
    foreground: AppColors.parchment,
  );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color foreground,
  }) {
    final isDark = brightness == Brightness.dark;
    final seedScheme = ColorScheme.fromSeed(
      seedColor: AppColors.navy,
      brightness: brightness,
      primary: isDark ? AppColors.gold : AppColors.navy,
      secondary: isDark ? AppColors.blue : AppColors.gold,
    );
    // Samakan latar halaman dengan warna latar NavigationBar (surfaceContainer)
    // agar tampilan layar dan bar navigasi bawah menyatu di mode terang & gelap.
    final background = seedScheme.surfaceContainer;
    final surface = isDark
        ? seedScheme.surfaceContainerHigh
        : seedScheme.surfaceContainerLowest;
    final colorScheme = seedScheme.copyWith(
      onPrimary: isDark ? AppColors.navy : AppColors.parchment,
      onSecondary: isDark ? AppColors.parchment : AppColors.navy,
      tertiary: isDark ? AppColors.parchment : AppColors.blue,
      onTertiary: isDark ? AppColors.navy : AppColors.parchment,
      surface: background,
      onSurface: foreground,
      surfaceContainerHighest: surface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: foreground,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: TextStyle(color: foreground),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        textStyle: TextStyle(color: foreground),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.gold,
        linearTrackColor: brightness == Brightness.dark
            ? AppColors.navy
            : AppColors.blue.withValues(alpha: 0.25),
        circularTrackColor: brightness == Brightness.dark
            ? AppColors.navy
            : AppColors.blue.withValues(alpha: 0.25),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: foreground,
        centerTitle: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      tabBarTheme: TabBarThemeData(
        indicatorColor: AppColors.gold,
        labelColor: brightness == Brightness.dark
            ? AppColors.gold
            : AppColors.navy,
        unselectedLabelColor: brightness == Brightness.dark
            ? AppColors.parchment.withValues(alpha: 0.72)
            : AppColors.blue,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 1,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: AppColors.gold,
        textColor: foreground,
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant.withValues(alpha: 0.4),
      ),
      iconTheme: IconThemeData(color: foreground),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.navy;
          return AppColors.parchment;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.gold;
          return brightness == Brightness.dark
              ? AppColors.navy
              : AppColors.blue.withValues(alpha: 0.25);
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.gold;
          return brightness == Brightness.dark
              ? AppColors.parchment.withValues(alpha: 0.45)
              : AppColors.blue.withValues(alpha: 0.5);
        }),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.gold,
        inactiveTrackColor: brightness == Brightness.dark
            ? AppColors.navy
            : AppColors.blue.withValues(alpha: 0.25),
        thumbColor: AppColors.gold,
        overlayColor: AppColors.gold.withValues(alpha: 0.18),
        valueIndicatorColor: AppColors.gold,
        valueIndicatorTextStyle: const TextStyle(
          color: AppColors.navy,
          fontWeight: FontWeight.w700,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.navy,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: isDark ? AppColors.gold : AppColors.navy,
          side: BorderSide(color: isDark ? AppColors.gold : AppColors.blue),
        ),
      ),
      textTheme: ThemeData(
        brightness: brightness,
        colorScheme: colorScheme,
      ).textTheme.apply(bodyColor: foreground, displayColor: foreground),
    );
  }
}
