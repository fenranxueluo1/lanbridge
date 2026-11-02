import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lanbridge/app.dart';
import 'package:lanbridge/core/theme/app_theme.dart';
import 'package:lanbridge/data/app_controller.dart';
import 'package:lanbridge/data/models/device.dart';
import 'package:lanbridge/data/models/transfer.dart';
import 'package:lanbridge/ui/sheets/incoming_sheet.dart';
import 'package:lanbridge/ui/sheets/send_sheet.dart';

void main() {
  testWidgets('desktop shell renders LANBridge navigation', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 820));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const LanBridgeApp(enableEngine: false));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('邻传'), findsWidgets);
    expect(find.text('附近'), findsWidgets);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('mobile shell renders without overflow at 390x844',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const LanBridgeApp(enableEngine: false));
    await tester.pump(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);
    expect(find.text('附近'), findsWidgets);
    expect(find.text('设置'), findsWidgets);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('incoming request sheet fits a small phone', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = AppController(enableEngine: false);
    final job = TransferJob(
      id: 'session',
      peerId: 'AABBCCDDEEFF0011',
      peerName: 'Test phone',
      peerKind: DeviceKind.phone,
      direction: TransferDirection.receive,
      files: [TransferFile(name: 'photo.jpg', size: 1024)],
      mode: TransferMode.standard,
      status: TransferStatus.waiting,
      peerIp: '127.0.0.1',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: TextButton(
                onPressed: () {
                  showIncomingSheet(context, controller, job);
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('接收请求'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 500));
    controller.dispose();
  });

  testWidgets('send sheet fits a small phone', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final device = Device(
      id: 'peer',
      name: 'Test PC',
      model: 'Windows 11',
      kind: DeviceKind.laptop,
      ip: '127.0.0.1',
      fingerprint: '',
      status: DeviceStatus.online,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: TextButton(
                onPressed: () => showSendSheet(
                  context,
                  files: [
                    TransferFile(name: 'photo.jpg', size: 1024),
                  ],
                  targets: [device],
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('确认发送'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 500));
  });
}
