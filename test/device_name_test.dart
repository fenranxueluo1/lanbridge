import 'package:flutter_test/flutter_test.dart';
import 'package:lanbridge/core/utils/physics_device_name.dart';
import 'package:lanbridge/data/models/app_settings.dart';

void main() {
  test('generates unique physics aliases when asked to avoid them', () {
    final used = <String>{};
    for (var index = 0; index < 80; index++) {
      final name = PhysicsDeviceName.generate(avoid: used);
      final normalized = PhysicsDeviceName.normalize(name);
      expect(name, isNotEmpty);
      expect(used.contains(normalized), isFalse);
      used.add(normalized);
    }
  });

  test('legacy default device name enables auto naming', () {
    final settings = AppSettings.fromJson({
      'deviceName': '我的设备 · Windows',
    });
    expect(settings.autoDeviceName, isTrue);
  });

  test('legacy custom device name stays manual', () {
    final settings = AppSettings.fromJson({'deviceName': 'My PC'});
    expect(settings.autoDeviceName, isFalse);
  });

  test('auto device name flag roundtrips through settings json', () {
    final settings = AppSettings(
      deviceName: '量子光子',
      autoDeviceName: false,
    );
    final restored = AppSettings.fromJson(settings.toJson());
    expect(restored.deviceName, '量子光子');
    expect(restored.autoDeviceName, isFalse);
  });
}
