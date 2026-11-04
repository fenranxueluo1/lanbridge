import 'package:flutter/services.dart';

/// HarmonyOS keeps received files inside the app sandbox by default. When the
/// user opts into the public downloads folder, finished transfers are moved
/// (native copy + delete) into `Download/<bundleName>`, whose authorization is
/// granted through a DOWNLOAD-mode save and persists across restarts.
class HarmonyDownloads {
  const HarmonyDownloads._();

  static const MethodChannel _channel = MethodChannel('lanbridge/downloads');

  /// Returns the downloads directory path when it is already authorized,
  /// otherwise null. Never triggers any system UI.
  static Future<String?> directory() async {
    try {
      return await _channel.invokeMethod<String>('getDir');
    } catch (_) {
      return null;
    }
  }

  /// Ensures the persistent authorization for `Download/<bundleName>` and
  /// returns its path, or null when the folder is unavailable.
  static Future<String?> authorize() async {
    try {
      return await _channel.invokeMethod<String>('authorize');
    } catch (_) {
      return null;
    }
  }

  /// Moves [files] into [dir]. Returns one entry per input file: the final
  /// destination path on success, or null when the file stayed in place.
  static Future<List<String?>> exportFiles(
    String dir,
    List<String> files,
  ) async {
    try {
      final raw = await _channel.invokeMethod<List<dynamic>>(
        'exportFiles',
        {'dir': dir, 'files': files},
      );
      return raw?.cast<String?>() ?? const [];
    } catch (_) {
      return const [];
    }
  }
}
