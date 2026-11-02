import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lanbridge/data/network/device_security.dart';
import 'package:lanbridge/data/network/lan_client.dart';
import 'package:lanbridge/data/network/lan_protocol.dart';
import 'package:lanbridge/data/network/lan_server.dart';
import 'package:mime/mime.dart';

void main() {
  test('HTTPS LocalSend core transfers a file with certificate pinning',
      () async {
    final temp = await Directory.systemTemp.createTemp('lanbridge_engine_');
    addTearDown(() async {
      if (await temp.exists()) await temp.delete(recursive: true);
    });

    final serverSecurity = DeviceSecurity.generate();
    final clientSecurity = DeviceSecurity.generate();

    final serverInfo = LanDeviceInfo(
      alias: 'Receiver',
      deviceModel: 'Windows',
      deviceType: 'desktop',
      fingerprint: serverSecurity.certificateHash,
      port: 0,
      https: true,
    );
    final clientInfo = LanDeviceInfo(
      alias: 'Sender',
      deviceModel: 'Windows',
      deviceType: 'desktop',
      fingerprint: clientSecurity.certificateHash,
      port: 53400,
      https: true,
    );

    final completion = Completer<LanCompletion>();
    final receiver = LanServer(
      info: serverInfo,
      security: serverSecurity,
      saveRoot: () => temp.path,
      onIncoming: (_) async => true,
      onComplete: (event) {
        if (!completion.isCompleted) completion.complete(event);
      },
    );
    await receiver.start();
    final port = receiver.boundPort!;

    final client = LanClient(self: clientInfo, security: clientSecurity);
    final peer = LanPeer(
      ip: '127.0.0.1',
      alias: serverInfo.alias,
      deviceModel: serverInfo.deviceModel,
      deviceType: serverInfo.deviceType,
      fingerprint: serverInfo.fingerprint,
      port: port,
      https: true,
      version: lanProtocolVersion,
    );

    final bytes = Uint8List.fromList(List<int>.generate(64 * 1024, (i) => i % 251));
    final source = File('${temp.path}/source.bin');
    await source.writeAsBytes(bytes, flush: true);

    final entry = LanFileEntry(
      id: 'f1',
      fileName: 'nested/photo.bin',
      size: bytes.length,
      mime: lookupMimeType('photo.bin') ?? 'application/octet-stream',
      sourcePath: source.path,
    );

    final prepared = await client.prepareUpload(peer, [entry]);
    final token = prepared.tokens[entry.id];
    expect(token, isNotNull);

    await client.upload(
      peer,
      sessionId: prepared.sessionId,
      file: entry,
      token: token!,
      sourcePath: source.path,
    );

    final result = await completion.future.timeout(const Duration(seconds: 15));
    expect(result.success, isTrue);

    final received = File('${temp.path}/nested/photo.bin');
    expect(await received.exists(), isTrue);
    expect(await received.length(), bytes.length);
    expect(await received.readAsBytes(), bytes);

    await receiver.stop();
  });

  test('Path traversal names are rejected', () async {
    final temp = await Directory.systemTemp.createTemp('lanbridge_engine_');
    addTearDown(() async {
      if (await temp.exists()) await temp.delete(recursive: true);
    });

    final serverSecurity = DeviceSecurity.generate();
    final clientSecurity = DeviceSecurity.generate();
    final serverInfo = LanDeviceInfo(
      alias: 'Receiver',
      deviceModel: 'Windows',
      deviceType: 'desktop',
      fingerprint: serverSecurity.certificateHash,
      port: 0,
      https: true,
    );
    final clientInfo = LanDeviceInfo(
      alias: 'Sender',
      deviceModel: 'Windows',
      deviceType: 'desktop',
      fingerprint: clientSecurity.certificateHash,
      port: 53400,
      https: true,
    );

    final receiver = LanServer(
      info: serverInfo,
      security: serverSecurity,
      saveRoot: () => temp.path,
      onIncoming: (_) async => true,
    );
    await receiver.start();
    final client = LanClient(self: clientInfo, security: clientSecurity);
    final peer = LanPeer(
      ip: '127.0.0.1',
      alias: serverInfo.alias,
      deviceModel: serverInfo.deviceModel,
      deviceType: serverInfo.deviceType,
      fingerprint: serverInfo.fingerprint,
      port: receiver.boundPort!,
      https: true,
      version: lanProtocolVersion,
    );

    final bytes = Uint8List.fromList([1, 2, 3, 4]);
    final source = File('${temp.path}/source2.bin');
    await source.writeAsBytes(bytes, flush: true);
    final entry = LanFileEntry(
      id: 'f1',
      fileName: '../escape.txt',
      size: bytes.length,
      mime: 'application/octet-stream',
      sourcePath: source.path,
    );

    final prepared = await client.prepareUpload(peer, [entry]);
    await expectLater(
      client.upload(
        peer,
        sessionId: prepared.sessionId,
        file: entry,
        token: prepared.tokens[entry.id]!,
        sourcePath: source.path,
      ),
      throwsA(isA<LanHttpException>()),
    );
    expect(await File('${temp.path}/../escape.txt').exists(), isFalse);

    await receiver.stop();
  });

  test('Receiver cancel closes the session and reports cancellation', () async {
    final temp = await Directory.systemTemp.createTemp('lanbridge_cancel_');
    addTearDown(() async {
      if (await temp.exists()) await temp.delete(recursive: true);
    });

    final serverSecurity = DeviceSecurity.generate();
    final clientSecurity = DeviceSecurity.generate();
    final serverInfo = LanDeviceInfo(
      alias: 'Receiver',
      deviceModel: 'Windows',
      deviceType: 'desktop',
      fingerprint: serverSecurity.certificateHash,
      port: 0,
      https: true,
    );
    final clientInfo = LanDeviceInfo(
      alias: 'Sender',
      deviceModel: 'Windows',
      deviceType: 'desktop',
      fingerprint: clientSecurity.certificateHash,
      port: 53400,
      https: true,
    );

    final completion = Completer<LanCompletion>();
    final receiver = LanServer(
      info: serverInfo,
      security: serverSecurity,
      saveRoot: () => temp.path,
      onIncoming: (_) async => true,
      onComplete: (event) {
        if (!completion.isCompleted) completion.complete(event);
      },
    );
    await receiver.start();
    final client = LanClient(self: clientInfo, security: clientSecurity);
    final peer = LanPeer(
      ip: '127.0.0.1',
      alias: serverInfo.alias,
      deviceModel: serverInfo.deviceModel,
      deviceType: serverInfo.deviceType,
      fingerprint: serverInfo.fingerprint,
      port: receiver.boundPort!,
      https: true,
      version: lanProtocolVersion,
    );

    final bytes = Uint8List.fromList(List<int>.filled(4096, 7));
    final source = File('${temp.path}/cancel.bin');
    await source.writeAsBytes(bytes, flush: true);
    final entry = LanFileEntry(
      id: 'f1',
      fileName: 'cancel.bin',
      size: bytes.length,
      mime: 'application/octet-stream',
      sourcePath: source.path,
    );

    final prepared = await client.prepareUpload(peer, [entry]);
    await client.cancel(peer, prepared.sessionId);
    final event = await completion.future.timeout(const Duration(seconds: 5));
    expect(event.cancelled, isTrue);

    await expectLater(
      client.upload(
        peer,
        sessionId: prepared.sessionId,
        file: entry,
        token: prepared.tokens[entry.id]!,
        sourcePath: source.path,
      ),
      throwsA(isA<LanHttpException>()),
    );

    await receiver.stop();
  });

  test('Large file transfers without stalling', () async {
    final temp = await Directory.systemTemp.createTemp('lanbridge_large_');
    addTearDown(() async {
      if (await temp.exists()) await temp.delete(recursive: true);
    });

    final serverSecurity = DeviceSecurity.generate();
    final clientSecurity = DeviceSecurity.generate();
    final serverInfo = LanDeviceInfo(
      alias: 'Receiver',
      deviceModel: 'Windows',
      deviceType: 'desktop',
      fingerprint: serverSecurity.certificateHash,
      port: 0,
      https: true,
    );
    final clientInfo = LanDeviceInfo(
      alias: 'Sender',
      deviceModel: 'Windows',
      deviceType: 'desktop',
      fingerprint: clientSecurity.certificateHash,
      port: 53400,
      https: true,
    );

    final completion = Completer<LanCompletion>();
    final receiver = LanServer(
      info: serverInfo,
      security: serverSecurity,
      saveRoot: () => temp.path,
      onIncoming: (_) async => true,
      onComplete: (event) {
        if (!completion.isCompleted) completion.complete(event);
      },
    );
    await receiver.start();
    final client = LanClient(self: clientInfo, security: clientSecurity);
    final peer = LanPeer(
      ip: '127.0.0.1',
      alias: serverInfo.alias,
      deviceModel: serverInfo.deviceModel,
      deviceType: serverInfo.deviceType,
      fingerprint: serverInfo.fingerprint,
      port: receiver.boundPort!,
      https: true,
      version: lanProtocolVersion,
    );

    const size = 8 * 1024 * 1024;
    final bytes = Uint8List(size);
    for (var i = 0; i < size; i++) {
      bytes[i] = i % 251;
    }
    final source = File('${temp.path}/large.bin');
    await source.writeAsBytes(bytes, flush: true);
    final entry = LanFileEntry(
      id: 'f1',
      fileName: 'large.bin',
      size: size,
      mime: 'application/octet-stream',
      sourcePath: source.path,
    );

    final stopwatch = Stopwatch()..start();
    final prepared = await client.prepareUpload(peer, [entry]);
    await client.upload(
      peer,
      sessionId: prepared.sessionId,
      file: entry,
      token: prepared.tokens[entry.id]!,
      sourcePath: source.path,
    );
    final result = await completion.future.timeout(const Duration(seconds: 30));
    stopwatch.stop();
    expect(result.success, isTrue);
    final received = File('${temp.path}/large.bin');
    expect(await received.exists(), isTrue);
    expect(await received.length(), size);
    expect(stopwatch.elapsed, lessThan(const Duration(seconds: 30)));

    await receiver.stop();
  });

  test('Multiple files transfer with per-file clients', () async {
    final temp = await Directory.systemTemp.createTemp('lanbridge_multi_');
    addTearDown(() async {
      if (await temp.exists()) await temp.delete(recursive: true);
    });

    final serverSecurity = DeviceSecurity.generate();
    final clientSecurity = DeviceSecurity.generate();
    final serverInfo = LanDeviceInfo(
      alias: 'Receiver',
      deviceModel: 'Windows',
      deviceType: 'desktop',
      fingerprint: serverSecurity.certificateHash,
      port: 0,
      https: true,
    );
    final clientInfo = LanDeviceInfo(
      alias: 'Sender',
      deviceModel: 'Windows',
      deviceType: 'desktop',
      fingerprint: clientSecurity.certificateHash,
      port: 53400,
      https: true,
    );

    final completion = Completer<LanCompletion>();
    final receiver = LanServer(
      info: serverInfo,
      security: serverSecurity,
      saveRoot: () => temp.path,
      onIncoming: (_) async => true,
      onComplete: (event) {
        if (!completion.isCompleted) completion.complete(event);
      },
    );
    await receiver.start();
    final client = LanClient(self: clientInfo, security: clientSecurity);
    final peer = LanPeer(
      ip: '127.0.0.1',
      alias: serverInfo.alias,
      deviceModel: serverInfo.deviceModel,
      deviceType: serverInfo.deviceType,
      fingerprint: serverInfo.fingerprint,
      port: receiver.boundPort!,
      https: true,
      version: lanProtocolVersion,
    );

    final entries = <LanFileEntry>[];
    for (var i = 0; i < 3; i++) {
      final bytes = Uint8List.fromList(
        List<int>.generate(128 * 1024, (index) => (index + i) % 251),
      );
      final source = File('${temp.path}/part_$i.bin');
      await source.writeAsBytes(bytes, flush: true);
      entries.add(
        LanFileEntry(
          id: 'file-$i',
          fileName: 'part_$i.bin',
          size: bytes.length,
          mime: 'application/octet-stream',
          sourcePath: source.path,
        ),
      );
    }

    final prepared = await client.prepareUpload(peer, entries);
    for (final entry in entries) {
      final fileClient = client.newClient(peer);
      try {
        await client.upload(
          peer,
          sessionId: prepared.sessionId,
          file: entry,
          token: prepared.tokens[entry.id]!,
          sourcePath: entry.sourcePath!,
          httpClient: fileClient,
        );
      } finally {
        fileClient.close(force: true);
      }
    }

    final result = await completion.future.timeout(const Duration(seconds: 20));
    expect(result.success, isTrue);
    for (var i = 0; i < 3; i++) {
      final received = File('${temp.path}/part_$i.bin');
      expect(await received.exists(), isTrue);
      expect(await received.length(), 128 * 1024);
    }

    await receiver.stop();
  });

  test('Unknown cancel is forwarded to the remote cancel handler', () async {
    final serverSecurity = DeviceSecurity.generate();
    final clientSecurity = DeviceSecurity.generate();
    final serverInfo = LanDeviceInfo(
      alias: 'Sender',
      deviceModel: 'Windows',
      deviceType: 'desktop',
      fingerprint: serverSecurity.certificateHash,
      port: 0,
      https: true,
    );
    final clientInfo = LanDeviceInfo(
      alias: 'Receiver',
      deviceModel: 'Windows',
      deviceType: 'desktop',
      fingerprint: clientSecurity.certificateHash,
      port: 53400,
      https: true,
    );

    final remoteCancel = Completer<String>();
    final server = LanServer(
      info: serverInfo,
      security: serverSecurity,
      saveRoot: () => Directory.systemTemp.path,
      onRemoteCancel: (sessionId) {
        if (!remoteCancel.isCompleted) remoteCancel.complete(sessionId);
      },
    );
    await server.start();
    final client = LanClient(self: clientInfo, security: clientSecurity);
    final peer = LanPeer(
      ip: '127.0.0.1',
      alias: serverInfo.alias,
      deviceModel: serverInfo.deviceModel,
      deviceType: serverInfo.deviceType,
      fingerprint: serverInfo.fingerprint,
      port: server.boundPort!,
      https: true,
      version: lanProtocolVersion,
    );

    const sessionId = 'outgoing-session-id';
    await client.cancel(peer, sessionId);
    expect(
      await remoteCancel.future.timeout(const Duration(seconds: 5)),
      sessionId,
    );

    await server.stop();
  });
}
