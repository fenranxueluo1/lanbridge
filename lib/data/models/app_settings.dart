import 'package:flutter/material.dart';

class AppSettings {
  AppSettings({
    required this.deviceName,
    this.savePath = '',
    this.discoveryEnabled = true,
    this.receiveEnabled = true,
    this.pinEnabled = false,
    this.pin = '428913',
    this.port = 53317,
    this.httpsEnabled = true,
    this.themeMode = ThemeMode.system,
    this.locale = const Locale('zh'),
    this.autoAcceptFavorites = false,
    this.webShareEnabled = false,
    this.autoDeviceName = true,
  });

  String deviceName;
  bool autoDeviceName;
  String savePath;
  bool discoveryEnabled;
  bool receiveEnabled;
  bool pinEnabled;
  String pin;
  int port;
  bool httpsEnabled;
  ThemeMode themeMode;
  Locale locale;
  bool autoAcceptFavorites;
  bool webShareEnabled;

  Map<String, dynamic> toJson() => {
        'deviceName': deviceName,
        'autoDeviceName': autoDeviceName,
        'savePath': savePath,
        'discoveryEnabled': discoveryEnabled,
        'receiveEnabled': receiveEnabled,
        'pinEnabled': pinEnabled,
        'pin': pin,
        'port': port,
        'httpsEnabled': httpsEnabled,
        'themeMode': themeMode.name,
        'locale': locale.languageCode,
        'autoAcceptFavorites': autoAcceptFavorites,
        'webShareEnabled': webShareEnabled,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final deviceName = (json['deviceName'] as String?)?.trim();
    final rawTheme = json['themeMode'];
    final rawLocale = json['locale'];
    final rawAutoName = json['autoDeviceName'];
    final legacyDefault = deviceName == null ||
        deviceName.isEmpty ||
        deviceName == 'LANBridge' ||
        deviceName.startsWith('我的设备');
    return AppSettings(
      deviceName: deviceName == null || deviceName.isEmpty
          ? 'LANBridge'
          : deviceName,
      autoDeviceName:
          rawAutoName is bool ? rawAutoName : legacyDefault,
      savePath: (json['savePath'] as String?) ?? '',
      discoveryEnabled: (json['discoveryEnabled'] as bool?) ?? true,
      receiveEnabled: (json['receiveEnabled'] as bool?) ?? true,
      pinEnabled: (json['pinEnabled'] as bool?) ?? false,
      pin: (json['pin'] as String?) ?? '428913',
      port: (json['port'] as num?)?.toInt() ?? 53317,
      httpsEnabled: (json['httpsEnabled'] as bool?) ?? true,
      themeMode: ThemeMode.values.firstWhere(
        (mode) => mode.name == rawTheme,
        orElse: () => ThemeMode.system,
      ),
      locale: Locale(
        rawLocale is String && rawLocale.isNotEmpty ? rawLocale : 'zh',
      ),
      autoAcceptFavorites:
          (json['autoAcceptFavorites'] as bool?) ?? false,
      webShareEnabled: (json['webShareEnabled'] as bool?) ?? false,
    );
  }
}
