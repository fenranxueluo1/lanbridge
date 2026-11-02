import 'package:flutter/services.dart';

import 'app_platform.dart';

/// Android public save folders need "All files access" (or legacy storage on
/// older releases). This opens the system settings page for that permission.
class StorageAccess {
  const StorageAccess._();

  static const MethodChannel _channel = MethodChannel('lanbridge/storage');

  static Future<bool> ensureManageStorage() async {
    if (!AppPlatform.isAndroid) return true;
    try {
      return await _channel.invokeMethod<bool>('ensureManageStorage') ?? false;
    } catch (_) {
      return false;
    }
  }
}
