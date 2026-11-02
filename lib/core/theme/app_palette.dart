import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Design tokens shared by every platform build.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.bg,
    required this.bgSecondary,
    required this.surface,
    required this.surfaceElevated,
    required this.hairline,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.brand,
    required this.brandAlt,
    required this.brandSoft,
    required this.glow,
    required this.shadow,
  });

  final Color bg;
  final Color bgSecondary;
  final Color surface;
  final Color surfaceElevated;
  final Color hairline;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color brand;
  final Color brandAlt;
  final Color brandSoft;
  final Color glow;
  final Color shadow;

  static const dark = AppPalette(
    bg: Color(0xFF070910),
    bgSecondary: Color(0xFF0B0E17),
    surface: Color(0xFF11141E),
    surfaceElevated: Color(0xFF181C28),
    hairline: Color(0x1FFFFFFF),
    textPrimary: Color(0xFFF2F5FF),
    textSecondary: Color(0xFFA2AABF),
    textTertiary: Color(0xFF6D7589),
    brand: Color(0xFF5EA8FF),
    brandAlt: Color(0xFF22D3EE),
    brandSoft: Color(0x2E2F80ED),
    glow: Color(0x4D2F80ED),
    shadow: Color(0x66000000),
  );

  static const light = AppPalette(
    bg: Color(0xFFF3F5FB),
    bgSecondary: Color(0xFFEAEDF7),
    surface: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFF7F9FF),
    hairline: Color(0xFFE3E7F1),
    textPrimary: Color(0xFF0E1220),
    textSecondary: Color(0xFF596174),
    textTertiary: Color(0xFF8A91A3),
    brand: Color(0xFF1D6FE8),
    brandAlt: Color(0xFF0891B2),
    brandSoft: Color(0x142F80ED),
    glow: Color(0x332F80ED),
    shadow: Color(0x140E1220),
  );

  @override
  AppPalette copyWith({
    Color? bg,
    Color? bgSecondary,
    Color? surface,
    Color? surfaceElevated,
    Color? hairline,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? brand,
    Color? brandAlt,
    Color? brandSoft,
    Color? glow,
    Color? shadow,
  }) {
    return AppPalette(
      bg: bg ?? this.bg,
      bgSecondary: bgSecondary ?? this.bgSecondary,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      hairline: hairline ?? this.hairline,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      brand: brand ?? this.brand,
      brandAlt: brandAlt ?? this.brandAlt,
      brandSoft: brandSoft ?? this.brandSoft,
      glow: glow ?? this.glow,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  AppPalette lerp(covariant ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      bg: Color.lerp(bg, other.bg, t)!,
      bgSecondary: Color.lerp(bgSecondary, other.bgSecondary, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      hairline: Color.lerp(hairline, other.hairline, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      brand: Color.lerp(brand, other.brand, t)!,
      brandAlt: Color.lerp(brandAlt, other.brandAlt, t)!,
      brandSoft: Color.lerp(brandSoft, other.brandSoft, t)!,
      glow: Color.lerp(glow, other.glow, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
    );
  }
}

class AppColors {
  const AppColors._();

  /// Flutter-icon inspired blue accent.
  static const brand = Color(0xFF2F80ED);
  static const sky = Color(0xFF54C5F8);
  static const cyan = Color(0xFF22D3EE);
  static const teal = Color(0xFF2DD4BF);
  static const blue = Color(0xFF3B82F6);
  static const amber = Color(0xFFFBBF24);
  static const orange = Color(0xFFFB923C);
  static const green = Color(0xFF34D399);
  static const red = Color(0xFFFF5F6D);
}

class AppGradients {
  const AppGradients._();

  static const aurora = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF54C5F8), Color(0xFF2196F3), Color(0xFF22D3EE)],
    stops: [0, 0.55, 1],
  );

  static const brandButton = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2F80ED), Color(0xFF1D4ED8)],
  );

  static const phone = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF38BDF8), Color(0xFF2563EB)],
  );

  static const tablet = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7DD3FC), Color(0xFF0284C7)],
  );

  static const laptop = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF22D3EE), Color(0xFF3B82F6)],
  );

  static const desktop = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2196F3), Color(0xFF06B6D4)],
  );

  static const tv = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFBBF24), Color(0xFFFB923C)],
  );

  static const nas = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2DD4BF), Color(0xFF34D399)],
  );

  static const teal = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2DD4BF), Color(0xFF0EA5E9)],
  );
}

extension AppThemeContext on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.dark;

  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  TextTheme get textStyles => Theme.of(this).textTheme;

  AppLocalizations get l10n => AppLocalizations.of(this);
}
