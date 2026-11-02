import 'package:flutter/services.dart';

import 'app_platform.dart';

/// Keeps an active transfer alive when the mobile app goes to the background.
///
/// Android uses a foreground data-sync service; HarmonyOS uses a continuous
/// data-transfer task. iOS does not allow this kind of long-running raw socket
/// background transfer, so the controller cancels on iOS instead.
class BackgroundTransfer {
  const BackgroundTransfer._();

  static const MethodChannel _channel = MethodChannel('lanbridge/background');
  static bool _running = false;

  static Future<void> start() async {
    if (!AppPlatform.isAndroid && !AppPlatform.isHarmony) return;
    if (_running) return;
    try {
      await _channel.invokeMethod<void>('start');
      _running = true;
    } catch (_) {
      // Background execution is best effort.
    }
  }

  static Future<void> stop() async {
    if (!AppPlatform.isAndroid && !AppPlatform.isHarmony) return;
    if (!_running) return;
    _running = false;
    try {
      await _channel.invokeMethod<void>('stop');
    } catch (_) {
      // The service may already be gone.
    }
  }

  static Future<void> notifyComplete({
    required String title,
    required String body,
  }) async {
    if (!AppPlatform.isMobile) return;
    try {
      await _channel.invokeMethod<void>('notifyComplete', {
        'title': title,
        'body': body,
      });
    } catch (_) {
      // Notifications are best effort.
    }
  }
}
