import 'package:flutter/services.dart';

class OhosPickedFile {
  const OhosPickedFile({
    required this.name,
    required this.size,
    required this.path,
  });

  final String name;
  final int size;
  final String path;
}

/// Bridge to the local OpenHarmony picker implementation.
class OhosPicker {
  const OhosPicker._();

  static const MethodChannel _channel = MethodChannel('lanbridge/picker');

  static Future<List<OhosPickedFile>> pickFiles(String kind) async {
    final raw = await _channel.invokeMethod<List<dynamic>>(
      'pickFiles',
      <String, dynamic>{'kind': kind},
    );
    if (raw == null) return const [];

    final files = <OhosPickedFile>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final map = Map<Object?, Object?>.from(item);
      final path = map['path'] as String?;
      if (path == null || path.isEmpty) continue;
      final name = (map['name'] as String?)?.trim();
      files.add(
        OhosPickedFile(
          name: name == null || name.isEmpty ? 'file' : name,
          size: (map['size'] as num?)?.toInt() ?? 0,
          path: path,
        ),
      );
    }
    return files;
  }
}
