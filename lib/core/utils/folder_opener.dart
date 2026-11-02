import 'dart:io';

import 'package:flutter/services.dart';

import '../platform/app_platform.dart';

/// Opens a folder in the platform file manager.
Future<bool> openFolder(String path) async {
  try {
    if (AppPlatform.isWindows) {
      await Process.run('explorer.exe', [path]);
      return true;
    }
    if (AppPlatform.isLinux) {
      await Process.run('xdg-open', [path]);
      return true;
    }
    if (AppPlatform.isMacOS) {
      await Process.run('open', [path]);
      return true;
    }
    final result = await const MethodChannel('lanbridge/network')
        .invokeMethod<bool>('openFolder', {'path': path});
    return result ?? false;
  } catch (_) {
    return false;
  }
}
