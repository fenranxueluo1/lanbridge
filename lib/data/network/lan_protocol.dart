import 'dart:io';

import 'package:path/path.dart' as p;

import '../models/device.dart';

const lanProtocolVersion = '2.2';
const lanDefaultPort = 53317;
const lanMulticastGroup = '224.0.0.167';

typedef LanPeerHandler = void Function(LanPeer peer);

const _reservedWindowsNames = {
  'CON', 'PRN', 'AUX', 'NUL', //
  'COM1', 'COM2', 'COM3', 'COM4', 'COM5', 'COM6', 'COM7', 'COM8', 'COM9',
  'LPT1', 'LPT2', 'LPT3', 'LPT4', 'LPT5', 'LPT6', 'LPT7', 'LPT8', 'LPT9',
};

/// What we advertise about ourselves.
class LanDeviceInfo {
  LanDeviceInfo({
    required this.alias,
    required this.deviceModel,
    required this.deviceType,
    required this.fingerprint,
    required this.port,
    required this.https,
    this.download = false,
    this.ip = '',
  });

  String alias;
  final String deviceModel;
  final String deviceType;
  final String fingerprint;
  final int port;
  final bool https;
  final bool download;
  final String ip;

  String get protocol => https ? 'https' : 'http';

  Map<String, dynamic> toInfoJson() => {
        'alias': alias,
        'version': lanProtocolVersion,
        'deviceModel': deviceModel,
        'deviceType': deviceType,
        'fingerprint': fingerprint,
        'download': download,
        if (ip.isNotEmpty) 'ip': ip,
      };

  Map<String, dynamic> toRegisterJson() => {
        ...toInfoJson(),
        'port': port,
        'protocol': protocol,
      };

  Map<String, dynamic> toMulticastJson({bool announcement = true}) => {
        ...toRegisterJson(),
        'announcement': announcement,
        'announce': announcement,
      };
}

/// A device discovered on the LAN.
class LanPeer {
  const LanPeer({
    required this.ip,
    required this.alias,
    required this.deviceModel,
    required this.deviceType,
    required this.fingerprint,
    required this.port,
    required this.https,
    required this.version,
  });

  final String ip;
  final String alias;
  final String deviceModel;
  final String deviceType;
  final String fingerprint;
  final int port;
  final bool https;
  final String version;

  factory LanPeer.fromMap(
    Map<String, dynamic> json, {
    required String ip,
    required bool fallbackHttps,
    required int fallbackPort,
  }) {
    final protocol = json['protocol'];
    final advertisedIp = (json['ip'] as String?)?.trim();
    return LanPeer(
      ip: advertisedIp == null || advertisedIp.isEmpty ? ip : advertisedIp,
      alias: (json['alias'] as String?)?.trim().isNotEmpty == true
          ? json['alias'] as String
          : ip,
      deviceModel: (json['deviceModel'] as String?) ?? 'Unknown device',
      deviceType: (json['deviceType'] as String?) ?? 'desktop',
      fingerprint: (json['fingerprint'] as String?) ?? '',
      port: (json['port'] as num?)?.toInt() ?? fallbackPort,
      https: protocol != null ? protocol == 'https' : fallbackHttps,
      version: (json['version'] as String?) ?? '1.0',
    );
  }

  factory LanPeer.fromRegister(
    Map<String, dynamic> json, {
    required String ip,
    required int fallbackPort,
    required bool fallbackHttps,
  }) =>
      LanPeer.fromMap(
        json,
        ip: ip,
        fallbackPort: fallbackPort,
        fallbackHttps: fallbackHttps,
      );

  Device toDevice({bool favorite = false}) {
    return Device(
      id: fingerprint.isNotEmpty ? fingerprint : ip,
      name: alias,
      model: deviceModel,
      kind: kindFromDeviceType(deviceType, deviceModel),
      ip: ip,
      fingerprint: fingerprint,
      status: DeviceStatus.online,
      isFavorite: favorite,
      supportsDelta: false,
      supportsResume: false,
      supportsManifest: false,
      port: port,
      https: https,
      version: version,
      lastSeen: DateTime.now(),
    );
  }
}

DeviceKind kindFromDeviceType(String type, String model) {
  final lower = '$type $model'.toLowerCase();
  if (lower.contains('phone') || lower.contains('mobile')) {
    return DeviceKind.phone;
  }
  if (lower.contains('tablet') || lower.contains('ipad')) {
    return DeviceKind.tablet;
  }
  if (lower.contains('tv')) return DeviceKind.tv;
  if (lower.contains('server') || lower.contains('nas')) return DeviceKind.nas;
  if (lower.contains('desktop') || lower.contains('windows')) {
    return DeviceKind.desktop;
  }
  return DeviceKind.laptop;
}

class LanFileEntry {
  const LanFileEntry({
    required this.id,
    required this.fileName,
    required this.size,
    required this.mime,
    this.sourcePath,
  });

  final String id;
  final String fileName;
  final int size;
  final String mime;
  final String? sourcePath;

  Map<String, dynamic> toFileJson() => {
        'id': id,
        'fileName': fileName,
        'size': size,
        'fileType': mime,
      };

  factory LanFileEntry.fromJson(Map<String, dynamic> json) => LanFileEntry(
        id: json['id'] as String,
        fileName: json['fileName'] as String,
        size: (json['size'] as num).toInt(),
        mime: (json['fileType'] as String?) ?? 'application/octet-stream',
      );
}

class LanPrepareResult {
  const LanPrepareResult({required this.sessionId, required this.tokens});

  final String sessionId;
  final Map<String, String> tokens;
}

class LanIncomingRequest {
  const LanIncomingRequest({
    required this.sessionId,
    required this.sender,
    required this.files,
  });

  final String sessionId;
  final LanPeer sender;
  final List<LanFileEntry> files;
}

class LanProgress {
  const LanProgress({
    required this.sessionId,
    required this.fileId,
    required this.fileName,
    required this.received,
    required this.total,
  });

  final String sessionId;
  final String fileId;
  final String fileName;
  final int received;
  final int total;
}

class LanCompletion {
  const LanCompletion({
    required this.sessionId,
    required this.success,
    this.savedFiles = const [],
    this.cancelled = false,
  });

  final String sessionId;
  final bool success;
  final List<String> savedFiles;
  final bool cancelled;
}

class LanHttpException implements Exception {
  const LanHttpException(this.statusCode, this.body);

  final int statusCode;
  final String body;

  @override
  String toString() => 'HTTP $statusCode: $body';
}

/// Resolves a peer-supplied relative file name below [root].
/// Returns null when the name attempts to escape the root.
String? safeResolvePath(String root, String fileName) {
  final normalizedName = fileName.replaceAll('\\', '/');
  final segments = normalizedName.split('/');
  final safeSegments = <String>[];

  for (final raw in segments) {
    if (raw.isEmpty || raw == '.') continue;
    if (raw == '..') return null;

    var segment = raw.replaceAll(
      RegExp(r'[\x00-\x1F<>:"|?*]'),
      '_',
    );
    segment = segment.replaceAll(RegExp(r'[. ]+$'), '');
    if (segment.isEmpty) continue;
    if (Platform.isWindows &&
        _reservedWindowsNames.contains(segment.toUpperCase())) {
      segment = '_$segment';
    }
    if (segment.length > 180) {
      segment = segment.substring(0, 180);
    }
    safeSegments.add(segment);
  }

  if (safeSegments.isEmpty) return null;
  final normalizedRoot = p.normalize(p.absolute(root));
  final target = p.normalize(p.joinAll([normalizedRoot, ...safeSegments]));
  if (!p.isWithin(normalizedRoot, target)) return null;
  return target;
}

File uniqueFile(String path) {
  final file = File(path);
  if (!file.existsSync()) return file;
  final dir = p.dirname(path);
  final extension = p.extension(path);
  final base = p.basenameWithoutExtension(path);
  for (var i = 1; i < 10000; i++) {
    final candidate = File(p.join(dir, '$base ($i)$extension'));
    if (!candidate.existsSync()) return candidate;
  }
  return File(p.join(dir, '$base-${DateTime.now().millisecondsSinceEpoch}$extension'));
}
