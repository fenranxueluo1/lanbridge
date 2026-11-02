import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';

enum DeviceKind { phone, tablet, laptop, desktop, tv, nas }

enum DeviceStatus { online, busy, offline }

enum DeviceCapability { resume, delta, manifest, pin, webShare }

extension DeviceKindX on DeviceKind {
  IconData get icon => switch (this) {
        DeviceKind.phone => Icons.smartphone_rounded,
        DeviceKind.tablet => Icons.tablet_mac_rounded,
        DeviceKind.laptop => Icons.laptop_mac_rounded,
        DeviceKind.desktop => Icons.desktop_windows_rounded,
        DeviceKind.tv => Icons.tv_rounded,
        DeviceKind.nas => Icons.dns_rounded,
      };

  LinearGradient get gradient => switch (this) {
        DeviceKind.phone => AppGradients.phone,
        DeviceKind.tablet => AppGradients.tablet,
        DeviceKind.laptop => AppGradients.laptop,
        DeviceKind.desktop => AppGradients.desktop,
        DeviceKind.tv => AppGradients.tv,
        DeviceKind.nas => AppGradients.nas,
      };
}

class Device {
  const Device({
    required this.id,
    required this.name,
    required this.model,
    required this.kind,
    required this.ip,
    required this.fingerprint,
    required this.status,
    this.isFavorite = false,
    this.supportsDelta = true,
    this.supportsResume = true,
    this.supportsManifest = true,
    this.lastSeen,
    this.port = 53317,
    this.https = true,
    this.version = '2.2',
  });

  final String id;
  final String name;
  final String model;
  final DeviceKind kind;
  final String ip;
  final String fingerprint;
  final DeviceStatus status;
  final bool isFavorite;
  final bool supportsDelta;
  final bool supportsResume;
  final bool supportsManifest;
  final DateTime? lastSeen;
  final int port;
  final bool https;
  final String version;

  bool get isOnline => status != DeviceStatus.offline;

  bool get isCompatibleOnly => !supportsDelta;

  Set<DeviceCapability> get capabilities => {
        if (supportsResume) DeviceCapability.resume,
        if (supportsDelta) DeviceCapability.delta,
        if (supportsManifest) DeviceCapability.manifest,
        DeviceCapability.pin,
      };

  Device copyWith({
    String? name,
    String? model,
    DeviceKind? kind,
    String? ip,
    String? fingerprint,
    DeviceStatus? status,
    bool? isFavorite,
    bool? supportsDelta,
    bool? supportsResume,
    bool? supportsManifest,
    DateTime? lastSeen,
    int? port,
    bool? https,
    String? version,
  }) {
    return Device(
      id: id,
      name: name ?? this.name,
      model: model ?? this.model,
      kind: kind ?? this.kind,
      ip: ip ?? this.ip,
      fingerprint: fingerprint ?? this.fingerprint,
      status: status ?? this.status,
      isFavorite: isFavorite ?? this.isFavorite,
      supportsDelta: supportsDelta ?? this.supportsDelta,
      supportsResume: supportsResume ?? this.supportsResume,
      supportsManifest: supportsManifest ?? this.supportsManifest,
      lastSeen: lastSeen ?? this.lastSeen,
      port: port ?? this.port,
      https: https ?? this.https,
      version: version ?? this.version,
    );
  }
}
