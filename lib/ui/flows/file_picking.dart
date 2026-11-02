import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/platform/app_platform.dart';
import '../../core/platform/ohos_picker.dart';
import '../../data/models/transfer.dart';

/// Picks real files through the platform file picker.
Future<List<TransferFile>> pickTransferFiles(FileType type) async {
  if (AppPlatform.isHarmony) {
    final kind = switch (type) {
      FileType.image => 'image',
      FileType.video => 'video',
      _ => 'any',
    };
    final files = await OhosPicker.pickFiles(kind);
    return [
      for (final file in files)
        TransferFile(name: file.name, size: file.size, path: file.path),
    ];
  }

  final result = await FilePicker.pickFiles(
    allowMultiple: true,
    type: type,
  );
  if (result == null) return const [];
  return result.files
      .where((file) => file.path != null)
      .map(
        (file) => TransferFile(
          name: file.name,
          size: file.size,
          path: file.path,
        ),
      )
      .toList();
}

/// Picks a folder and expands it into individual files with relative paths.
Future<List<TransferFile>> pickTransferFolder() async {
  if (AppPlatform.isHarmony) {
    final folder = await OhosPicker.pickFolder();
    if (folder == null) return const [];
    final root = Directory(folder.path);
    if (!await root.exists()) return const [];
    final name = folder.name.trim().isEmpty
        ? p.basename(folder.path)
        : folder.name.trim();
    return _expandFolder(root, name);
  }

  final directory = await FilePicker.getDirectoryPath();
  if (directory == null || directory.isEmpty) return const [];

  final root = Directory(directory);
  if (!await root.exists()) return const [];
  return _expandFolder(root, p.basename(root.path));
}

Future<List<TransferFile>> _expandFolder(
  Directory root,
  String rootName,
) async {
  final files = <TransferFile>[];
  try {
    await for (final entity
        in root.list(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      try {
        final relative = p
            .relative(entity.path, from: root.path)
            .replaceAll('\\', '/');
        final size = await entity.length();
        files.add(
          TransferFile(
            name: '$rootName/$relative',
            size: size,
            path: entity.path,
          ),
        );
      } catch (_) {
        // Skip files that disappeared or cannot be read.
      }
      if (files.length >= 5000) break;
    }
  } catch (_) {
    return files;
  }
  return files;
}

/// Expands OS-dropped file and folder paths into transfer entries.
Future<List<TransferFile>> transferFilesFromPaths(List<String> paths) async {
  final files = <TransferFile>[];
  for (final rawPath in paths) {
    if (rawPath.trim().isEmpty || files.length >= 5000) continue;
    try {
      final type = await FileSystemEntity.type(rawPath, followLinks: true);
      if (type == FileSystemEntityType.file) {
        final file = File(rawPath);
        final size = await file.length();
        files.add(
          TransferFile(
            name: p.basename(rawPath),
            size: size,
            path: rawPath,
          ),
        );
      } else if (type == FileSystemEntityType.directory) {
        final root = Directory(rawPath);
        files.addAll(await _expandFolder(root, p.basename(root.path)));
      }
    } catch (_) {
      // Skip paths that cannot be read.
    }
  }
  return files.length > 5000
      ? files.sublist(0, 5000)
      : files;
}

Future<TransferFile?> createTextTransferFile(String text) async {
  if (text.trim().isEmpty) return null;
  Directory directory;
  try {
    directory = await getTemporaryDirectory();
  } catch (_) {
    directory = Directory.systemTemp;
  }
  final name = 'lanbridge-message-${DateTime.now().millisecondsSinceEpoch}.txt';
  final file = File(p.join(directory.path, name));
  await file.writeAsString(text, flush: true);
  final size = await file.length();
  return TransferFile(
    name: name,
    size: size,
    path: file.path,
  );
}
