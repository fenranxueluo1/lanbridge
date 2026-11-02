import 'package:flutter/services.dart';

import '../platform/app_platform.dart';

/// Subtle haptic feedback on touch platforms. Desktop builds are unaffected.
class Haptics {
  const Haptics._();

  static void tap() {
    if (!AppPlatform.isMobile) return;
    HapticFeedback.selectionClick();
  }

  static void action() {
    if (!AppPlatform.isMobile) return;
    HapticFeedback.lightImpact();
  }

  static void success() {
    if (!AppPlatform.isMobile) return;
    HapticFeedback.mediumImpact();
  }
}
