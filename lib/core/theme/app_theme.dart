import 'package:flutter/material.dart';

import 'app_palette.dart';

/// Material 3 theme with a restrained, premium visual language:
/// deep neutral surfaces, a single aurora accent and generous radii.
class AppTheme {
  const AppTheme._();

  static ThemeData dark() => _build(Brightness.dark, AppPalette.dark);

  static ThemeData light() => _build(Brightness.light, AppPalette.light);

  static ThemeData _build(Brightness brightness, AppPalette palette) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: palette.brand,
      onPrimary: Colors.white,
      primaryContainer: palette.brandSoft,
      onPrimaryContainer: palette.textPrimary,
      secondary: AppColors.sky,
      onSecondary: Colors.white,
      secondaryContainer: palette.brandSoft,
      onSecondaryContainer: palette.textPrimary,
      tertiary: AppColors.cyan,
      onTertiary: const Color(0xFF04222A),
      error: AppColors.red,
      onError: Colors.white,
      errorContainer: const Color(0x33FF5F6D),
      onErrorContainer: AppColors.red,
      surface: palette.surface,
      onSurface: palette.textPrimary,
      surfaceContainerHighest: palette.surfaceElevated,
      onSurfaceVariant: palette.textSecondary,
      outline: palette.hairline,
      outlineVariant: palette.hairline,
      shadow: palette.shadow,
      scrim: Colors.black,
      inverseSurface: brightness == Brightness.dark
          ? const Color(0xFFF2F5FF)
          : const Color(0xFF141827),
      onInverseSurface: brightness == Brightness.dark
          ? const Color(0xFF141827)
          : const Color(0xFFF2F5FF),
      inversePrimary: palette.brandAlt,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: palette.bg,
      canvasColor: palette.bg,
      dividerColor: palette.hairline,
      extensions: [palette],
      visualDensity: VisualDensity.standard,
      splashFactory: InkRipple.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.ohos: ZoomPageTransitionsBuilder(),
          TargetPlatform.fuchsia: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );

    final textTheme = _textTheme(base.textTheme, palette);

    return base.copyWith(
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      iconTheme: IconThemeData(color: palette.textSecondary, size: 22),
      primaryIconTheme: const IconThemeData(color: Colors.white, size: 22),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: palette.brand,
        selectionColor: palette.brand.withValues(alpha: 0.25),
        selectionHandleColor: palette.brand,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.surfaceElevated,
        hintStyle: textTheme.bodyMedium?.copyWith(color: palette.textTertiary),
        labelStyle: textTheme.bodyMedium?.copyWith(color: palette.textSecondary),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: _inputBorder(palette.hairline),
        enabledBorder: _inputBorder(palette.hairline),
        focusedBorder: _inputBorder(palette.brand.withValues(alpha: 0.7)),
        errorBorder: _inputBorder(AppColors.red.withValues(alpha: 0.6)),
        focusedErrorBorder: _inputBorder(AppColors.red),
        prefixIconColor: palette.textTertiary,
        suffixIconColor: palette.textTertiary,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: palette.brand,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 50),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: textTheme.labelLarge,
          shape: const StadiumBorder(),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.textPrimary,
          minimumSize: const Size(0, 50),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          textStyle: textTheme.labelLarge,
          side: BorderSide(color: palette.hairline),
          shape: const StadiumBorder(),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: palette.brand,
          textStyle: textTheme.labelLarge,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          shape: const StadiumBorder(),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: palette.textSecondary,
          highlightColor: palette.brandSoft,
          shape: const CircleBorder(),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: palette.surfaceElevated,
        contentTextStyle:
            textTheme.bodyMedium?.copyWith(color: palette.textPrimary),
        actionTextColor: palette.brand,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: palette.hairline),
        ),
        insetPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      ),
      tooltipTheme: TooltipThemeData(
        waitDuration: const Duration(milliseconds: 450),
        decoration: BoxDecoration(
          color: palette.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: palette.hairline),
        ),
        textStyle: textTheme.bodySmall?.copyWith(color: palette.textPrimary),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: palette.surfaceElevated,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        textStyle: textTheme.bodyMedium?.copyWith(color: palette.textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: palette.hairline),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle:
            textTheme.bodyMedium?.copyWith(color: palette.textSecondary),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        modalBackgroundColor: palette.surface,
        modalElevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        dragHandleColor: palette.textTertiary.withValues(alpha: 0.4),
        dragHandleSize: const Size(44, 5),
      ),
      dividerTheme: DividerThemeData(
        color: palette.hairline,
        thickness: 1,
        space: 1,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return brightness == Brightness.dark
              ? const Color(0xFF9AA3B8)
              : Colors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return palette.brand;
          return palette.textTertiary.withValues(alpha: 0.28);
        }),
        trackOutlineColor:
            WidgetStatePropertyAll(palette.hairline.withValues(alpha: 0.6)),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thickness: const WidgetStatePropertyAll(6),
        radius: const Radius.circular(3),
        thumbColor: WidgetStatePropertyAll(
          palette.textTertiary.withValues(alpha: 0.45),
        ),
        crossAxisMargin: 2,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: palette.brand,
        linearTrackColor: palette.hairline,
        circularTrackColor: palette.hairline,
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: color),
      );

  static TextTheme _textTheme(TextTheme base, AppPalette palette) {
    final theme = base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
        fontSize: 46,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.4,
        height: 1.08,
      ),
      displayMedium: base.displayMedium?.copyWith(
        fontSize: 38,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.1,
        height: 1.1,
      ),
      displaySmall: base.displaySmall?.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
        height: 1.14,
      ),
      headlineLarge: base.headlineLarge?.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        height: 1.2,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        height: 1.24,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontSize: 21,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        height: 1.3,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        height: 1.3,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontSize: 15.5,
        fontWeight: FontWeight.w600,
        height: 1.35,
      ),
      titleSmall: base.titleSmall?.copyWith(
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
        height: 1.35,
      ),
      bodyLarge: base.bodyLarge?.copyWith(fontSize: 15.5, height: 1.5),
      bodyMedium: base.bodyMedium?.copyWith(fontSize: 14, height: 1.5),
      bodySmall: base.bodySmall?.copyWith(fontSize: 12.5, height: 1.45),
      labelLarge: base.labelLarge?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
      labelMedium: base.labelMedium?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
      labelSmall: base.labelSmall?.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
        height: 1.3,
      ),
    );

    return theme.apply(
      bodyColor: palette.textPrimary,
      displayColor: palette.textPrimary,
      decoration: TextDecoration.none,
      decorationColor: Colors.transparent,
    );
  }
}
