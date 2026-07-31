import 'package:flutter/material.dart';

/// Palet warna persis dari template HTML (tailwind-config).
class AppColor {
  static const Color primary = Color(0xFF2563EB);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFDBE1FF);
  static const Color onPrimaryContainer = Color(0xFF00174B);
  static const Color secondary = Color(0xFF0058BE);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFF2170E4);
  static const Color onSecondaryContainer = Color(0xFFFEFCFF);
  static const Color tertiary = Color(0xFF943700);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFFBC4800);
  static const Color onTertiaryContainer = Color(0xFFFFEDE6);
  static const Color surface = Color(0xFFFAF8FF);
  static const Color onSurface = Color(0xFF191B23);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF3F3FE);
  static const Color surfaceContainer = Color(0xFFEDEDF9);
  static const Color surfaceContainerHigh = Color(0xFFE7E7F3);
  static const Color surfaceContainerHighest = Color(0xFFE1E2ED);
  static const Color surfaceVariant = Color(0xFFE1E2ED);
  static const Color surfaceDim = Color(0xFFD9D9E5);
  static const Color surfaceBright = Color(0xFFFAF8FF);
  static const Color onSurfaceVariant = Color(0xFF434655);
  static const Color outline = Color(0xFF737686);
  static const Color outlineVariant = Color(0xFFC3C6D7);
  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);
  static const Color background = Color(0xFFFAF8FF);
  static const Color inversePrimary = Color(0xFFB4C5FF);
  static const Color primaryFixed = Color(0xFFDBE1FF);
  static const Color primaryFixedDim = Color(0xFFB4C5FF);
  static const Color secondaryFixed = Color(0xFFD8E2FF);
  static const Color secondaryFixedDim = Color(0xFFADC6FF);
  static const Color tertiaryFixed = Color(0xFFFFDBCD);
  static const Color tertiaryFixedDim = Color(0xFFFFB596);
  static const Color surfaceTint = Color(0xFF0053DB);
  static const Color onPrimaryFixed = Color(0xFF00174B);
  static const Color onSecondaryFixed = Color(0xFF001A42);
  static const Color onTertiaryFixed = Color(0xFF360F00);
  static const Color onPrimaryFixedVariant = Color(0xFF003EA8);
  static const Color onSecondaryFixedVariant = Color(0xFF004395);
  static const Color onTertiaryFixedVariant = Color(0xFF7D2D00);

  static const Color success = Color(0xFF16A34A);
  static const Color onSuccess = Color(0xFFFFFFFF);
  static const Color successContainer = Color(0xFFDCFCE7);
  static const Color onSuccessContainer = Color(0xFF15803D);

  static const Color green = Color(0xFF16A34A);
  static const Color amber = Color(0xFFF59E0B);
  static const Color amber50 = Color(0xFFFFFBEB);
  static const Color amber100 = Color(0xFFFEF3C7);
  static const Color amber700 = Color(0xFFB45309);
  static const Color amber800 = Color(0xFF92400E);
  static const Color amber900 = Color(0xFF78350F);
  static const Color green50 = Color(0xFFF0FDF4);
  static const Color green100 = Color(0xFFDCFCE7);
  static const Color green600 = Color(0xFF16A34A);
  static const Color green700 = Color(0xFF15803D);
  static const Color red50 = Color(0xFFFEF2F2);
  static const Color red600 = Color(0xFFDC2626);
  static const Color red700 = Color(0xFFB91C1C);
  static const Color qrisRed = Color(0xFFDC2626);
}

/// ColorScheme eksplisit mengikuti warna template (bukan dari seed).
class AppScheme {
  static ColorScheme get light {
    return const ColorScheme.light(
      primary: AppColor.primary,
      onPrimary: AppColor.onPrimary,
      primaryContainer: AppColor.primaryContainer,
      onPrimaryContainer: AppColor.onPrimaryContainer,
      secondary: AppColor.secondary,
      onSecondary: AppColor.onSecondary,
      secondaryContainer: AppColor.secondaryContainer,
      onSecondaryContainer: AppColor.onSecondaryContainer,
      tertiary: AppColor.tertiary,
      onTertiary: AppColor.onTertiary,
      tertiaryContainer: AppColor.tertiaryContainer,
      onTertiaryContainer: AppColor.onTertiaryContainer,
      surface: AppColor.surface,
      onSurface: AppColor.onSurface,
      surfaceContainerLowest: AppColor.surfaceContainerLowest,
      surfaceContainerLow: AppColor.surfaceContainerLow,
      surfaceContainer: AppColor.surfaceContainer,
      surfaceContainerHigh: AppColor.surfaceContainerHigh,
      surfaceContainerHighest: AppColor.surfaceContainerHighest,
      surfaceDim: AppColor.surfaceDim,
      surfaceBright: AppColor.surfaceBright,
      onSurfaceVariant: AppColor.onSurfaceVariant,
      outline: AppColor.outline,
      outlineVariant: AppColor.outlineVariant,
      error: AppColor.error,
      onError: AppColor.onError,
      errorContainer: AppColor.errorContainer,
      onErrorContainer: AppColor.onErrorContainer,
      inversePrimary: AppColor.inversePrimary,
      primaryFixed: AppColor.primaryFixed,
      primaryFixedDim: AppColor.primaryFixedDim,
      secondaryFixed: AppColor.secondaryFixed,
      secondaryFixedDim: AppColor.secondaryFixedDim,
      tertiaryFixed: AppColor.tertiaryFixed,
      tertiaryFixedDim: AppColor.tertiaryFixedDim,
      surfaceTint: AppColor.surfaceTint,
      brightness: Brightness.light,
    );
  }
}

class AppTheme {
  static ThemeData get lightTheme {
    final scheme = AppScheme.light;
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColor.background,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
        foregroundColor: AppColor.onSurface,
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColor.onSurface,
          letterSpacing: -0.3,
        ),
        iconTheme: const IconThemeData(color: AppColor.onSurface, size: 24),
        actionsIconTheme: const IconThemeData(color: AppColor.onSurfaceVariant, size: 24),
      ),
      cardTheme: CardThemeData(
        color: AppColor.surfaceContainerLowest,
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.04),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColor.primary,
          foregroundColor: AppColor.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          minimumSize: const Size(double.infinity, 52),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColor.primary,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          side: BorderSide(color: AppColor.outlineVariant),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          minimumSize: const Size(double.infinity, 52),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColor.primary,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColor.primaryContainer,
          foregroundColor: AppColor.onPrimaryContainer,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          minimumSize: const Size(double.infinity, 52),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColor.surfaceContainerLowest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColor.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColor.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColor.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColor.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: TextStyle(color: AppColor.onSurfaceVariant.withValues(alpha: 0.6), fontSize: 15),
        labelStyle: const TextStyle(color: AppColor.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w500),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColor.surface,
        indicatorColor: AppColor.primary.withValues(alpha: 0.12),
        elevation: 0,
        height: 72,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppColor.primary : AppColor.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColor.primary : AppColor.onSurfaceVariant,
            size: 24,
          );
        }),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColor.surfaceContainerHigh,
        selectedColor: AppColor.primary,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColor.onSurfaceVariant),
        secondaryLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColor.onPrimary),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        side: BorderSide.none,
      ),
      iconTheme: const IconThemeData(color: AppColor.onSurfaceVariant, size: 24),
      dividerTheme: DividerThemeData(color: AppColor.outlineVariant.withValues(alpha: 0.3), thickness: 1, space: 1),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: AppColor.onSurface, letterSpacing: -0.5),
        displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColor.onSurface, letterSpacing: -0.5),
        displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColor.onSurface),
        headlineLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColor.onSurface),
        headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColor.onSurface),
        headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColor.onSurface),
        titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColor.onSurface),
        titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColor.onSurface),
        titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColor.onSurface),
        bodyLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: AppColor.onSurface),
        bodyMedium: TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: AppColor.onSurfaceVariant),
        bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: AppColor.onSurfaceVariant),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColor.onSurface),
        labelMedium: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColor.onSurfaceVariant),
        labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColor.onSurfaceVariant),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColor.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColor.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColor.primary,
        foregroundColor: AppColor.onPrimary,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColor.onSurface,
        contentTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColor.primary,
        linearTrackColor: AppColor.surfaceContainerHigh,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected) ? AppColor.onPrimary : AppColor.surfaceContainerHigh;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected) ? AppColor.primary : AppColor.surfaceContainerHighest;
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected) ? AppColor.primary : Colors.transparent;
        }),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        side: const BorderSide(color: AppColor.outlineVariant),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected) ? AppColor.primary : AppColor.onSurfaceVariant;
        }),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColor.primary,
        unselectedLabelColor: AppColor.onSurfaceVariant,
        indicatorColor: AppColor.primary,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(color: AppColor.onSurface, borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}
