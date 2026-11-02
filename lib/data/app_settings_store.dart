import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'models/app_settings.dart';

/// Persists user settings in the application support directory.
class AppSettingsStore {
  const AppSettingsStore._();

  static const _fileName = 'lanbridge_settings.json';

  static Future<AppSettings?> load({Directory? directory}) async {
    try {
      final dir = directory ?? await getApplicationSupportDirectory();
      final file = File(p.join(dir.path, _fileName));
      if (!await file.exists()) return null;
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map<String, dynamic>) return null;
      return AppSettings.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  static Future<void> save(
    AppSettings settings, {
    Directory? directory,
  }) async {
    try {
      final dir = directory ?? await getApplicationSupportDirectory();
      await dir.create(recursive: true);
      final file = File(p.join(dir.path, _fileName));
      await file.writeAsString(jsonEncode(settings.toJson()), flush: true);
    } catch (_) {
      // Settings persistence is best effort.
    }
  }
}
