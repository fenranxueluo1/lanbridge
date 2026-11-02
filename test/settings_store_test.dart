import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lanbridge/data/app_settings_store.dart';
import 'package:lanbridge/data/models/app_settings.dart';

void main() {
  test('settings persist save path and appearance across reloads', () async {
    final directory = await Directory.systemTemp.createTemp('lanbridge_settings_');
    addTearDown(() async {
      if (await directory.exists()) await directory.delete(recursive: true);
    });

    final original = AppSettings(
      deviceName: 'Persisted device',
      savePath: 'D:/Custom/LANBridge',
      discoveryEnabled: false,
      receiveEnabled: false,
      pinEnabled: true,
      pin: '123456',
      port: 54000,
      httpsEnabled: false,
      themeMode: ThemeMode.dark,
      locale: const Locale('en'),
      autoAcceptFavorites: true,
      webShareEnabled: true,
    );

    await AppSettingsStore.save(original, directory: directory);
    final loaded = await AppSettingsStore.load(directory: directory);

    expect(loaded, isNotNull);
    expect(loaded!.deviceName, original.deviceName);
    expect(loaded.savePath, original.savePath);
    expect(loaded.discoveryEnabled, isFalse);
    expect(loaded.receiveEnabled, isFalse);
    expect(loaded.pinEnabled, isTrue);
    expect(loaded.pin, '123456');
    expect(loaded.port, 54000);
    expect(loaded.httpsEnabled, isFalse);
    expect(loaded.themeMode, ThemeMode.dark);
    expect(loaded.locale.languageCode, 'en');
    expect(loaded.autoAcceptFavorites, isTrue);
    expect(loaded.webShareEnabled, isTrue);
  });
}
