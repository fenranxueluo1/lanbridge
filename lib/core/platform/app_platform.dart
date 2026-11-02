import 'package:flutter/foundation.dart';

/// Thin abstraction over the platforms LANBridge ships on.
///
/// The Flutter SDK used by this project is the OpenHarmony fork, which exposes
/// [TargetPlatform.ohos], so no `dart:io` import is required and the code stays
/// web-safe.
class AppPlatform {
  const AppPlatform._();

  static bool get isWeb => kIsWeb;

  static TargetPlatform get targetPlatform => defaultTargetPlatform;

  static bool get isIOS => !isWeb && defaultTargetPlatform == TargetPlatform.iOS;

  static bool get isAndroid =>
      !isWeb && defaultTargetPlatform == TargetPlatform.android;

  static bool get isHarmony =>
      !isWeb && defaultTargetPlatform == TargetPlatform.ohos;

  static bool get isWindows =>
      !isWeb && defaultTargetPlatform == TargetPlatform.windows;

  static bool get isLinux =>
      !isWeb && defaultTargetPlatform == TargetPlatform.linux;

  static bool get isMacOS =>
      !isWeb && defaultTargetPlatform == TargetPlatform.macOS;

  static bool get isDesktop => isWindows || isLinux || isMacOS;

  static bool get isMobile => isAndroid || isIOS || isHarmony;

  /// iOS leans on Cupertino interaction details (page transitions, bouncing
  /// physics, adaptive switches) while the rest of the UI stays consistent.
  static bool get prefersCupertinoFeel => isIOS;

  /// Desktop builds use a rail/sidebar shell and dialogs instead of sheets.
  static bool get usesDesktopShell => isDesktop;

  static String get platformLabel {
    if (isWeb) return 'Web';
    if (isHarmony) return 'HarmonyOS';
    if (isIOS) return 'iOS';
    if (isAndroid) return 'Android';
    if (isWindows) return 'Windows';
    if (isLinux) return 'Linux';
    if (isMacOS) return 'macOS';
    return 'Unknown';
  }

  /// A short, human friendly device model used as the local device's subtitle.
  static String get localModelLabel {
    if (isWeb) return 'Web browser';
    if (isHarmony) return 'HarmonyOS device';
    if (isIOS) return 'iPhone · iPad';
    if (isAndroid) return 'Android device';
    if (isWindows) return 'Windows PC';
    if (isLinux) return 'Linux desktop';
    if (isMacOS) return 'Mac';
    return 'Device';
  }
}
