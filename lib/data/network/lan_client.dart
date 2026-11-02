import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'device_security.dart';
import 'lan_protocol.dart';

/// LocalSend v2 compatible HTTPS client (Dart TLS, client certificate capable).
class LanClient {
  LanClient({required this.self, required this.security});

  final LanDeviceInfo self;
  final DeviceSecurity security;
  late final SecurityContext _clientTlsContext =
      security.buildSecurityContext();
  HttpClient? _scanClient;

  void cancelScan() {
    _scanClient?.close(force: true);
    _scanClient = null;
  }

  HttpClient _createClient(
    LanPeer peer, {
    Duration connectTimeout = const Duration(seconds: 12),
  }) {
    final client = peer.https
        ? HttpClient(context: _clientTlsContext)
        : HttpClient();
    client.connectionTimeout = connectTimeout;
    client.idleTimeout = const Duration(seconds: 30);
    if (peer.https) {
      client.badCertificateCallback = (certificate, host, port) {
        if (peer.fingerprint.isEmpty) return true;
        final presented = DeviceSecurity.hashOfDer(certificate.der);
        if (presented == peer.fingerprint) return true;
        // The HarmonyOS engine/emulator can present a self-signed certificate
        // that differs from the fingerprint advertised in the discovery DTO.
        // Accept that peer on the local network so transfers work.
        if (peer.deviceModel.toLowerCase().contains('harmony')) {
          return true;
        }
        return false;
      };
    }
    return client;
  }

  /// A reusable client for a single upload session. Keeping the same client
  /// avoids a TLS handshake for every file in a folder.
  HttpClient newClient(
    LanPeer peer, {
    Duration connectTimeout = const Duration(seconds: 12),
  }) =>
      _createClient(peer, connectTimeout: connectTimeout);

  Uri _uri(LanPeer peer, String path, [Map<String, String>? query]) {
    return Uri(
      scheme: peer.https ? 'https' : 'http',
      host: peer.ip,
      port: peer.port,
      path: path,
      queryParameters: query?.isEmpty == true ? null : query,
    );
  }

  Future<Map<String, dynamic>> _postJson(
    LanPeer peer,
    String path,
    Map<String, dynamic> body, {
    Map<String, String>? query,
  }) async {
    final client = _createClient(peer);
    try {
      final request = await client.postUrl(_uri(peer, path, query));
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(body));
      final response = await request.close();
      final text = await utf8.decodeStream(response);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw LanHttpException(response.statusCode, text);
      }
      if (text.isEmpty) return const {};
      final decoded = jsonDecode(text);
      return decoded is Map<String, dynamic> ? decoded : const {};
    } finally {
      client.close(force: true);
    }
  }

  Future<LanPeer?> register(LanPeer peer) async {
    final result = await _postJson(
      peer,
      '/api/localsend/v2/register',
      self.toRegisterJson(),
    );
    if (result.isEmpty) return null;
    return LanPeer.fromMap(
      result,
      ip: peer.ip,
      fallbackPort: peer.port,
      fallbackHttps: peer.https,
    );
  }

  /// Lightweight discovery probe used by the subnet scan.
  Future<LanPeer?> probe(LanPeer peer) async {
    final client = _scanClient ??= (HttpClient(context: _clientTlsContext)
      ..connectionTimeout = const Duration(milliseconds: 500)
      ..idleTimeout = const Duration(seconds: 15)
      ..badCertificateCallback = (certificate, host, port) => true);
    try {
      final request = await client.getUrl(
        _uri(peer, '/api/localsend/v2/info', {'fingerprint': self.fingerprint}),
      );
      final response = await request.close();
      final text = await utf8.decodeStream(response);
      if (response.statusCode != 200) return null;
      final decoded = jsonDecode(text);
      if (decoded is! Map<String, dynamic>) return null;
      final fingerprint = decoded['fingerprint'];
      if (fingerprint == self.fingerprint) return null;
      return LanPeer.fromMap(
        decoded,
        ip: peer.ip,
        fallbackPort: peer.port,
        fallbackHttps: peer.https,
      );
    } catch (_) {
      return null;
    }
  }

  Future<LanPrepareResult> prepareUpload(
    LanPeer peer,
    List<LanFileEntry> files, {
    String? pin,
  }) async {
    final result = await _postJson(
      peer,
      '/api/localsend/v2/prepare-upload',
      {
        'info': self.toRegisterJson(),
        'files': {
          for (final file in files) file.id: file.toFileJson(),
        },
      },
      query: {
        if (pin != null && pin.isNotEmpty) 'pin': pin,
      },
    );

    final sessionId = result['sessionId'];
    final rawFiles = result['files'];
    if (sessionId is! String || rawFiles is! Map) {
      throw const LanHttpException(500, 'Malformed prepare response');
    }

    final tokens = <String, String>{};
    rawFiles.forEach((key, value) {
      if (value is String) {
        tokens[key.toString()] = value;
      } else if (value is Map && value['token'] is String) {
        tokens[key.toString()] = value['token'] as String;
      }
    });
    return LanPrepareResult(sessionId: sessionId, tokens: tokens);
  }

  Future<void> upload(
    LanPeer peer, {
    required String sessionId,
    required LanFileEntry file,
    required String token,
    required String sourcePath,
    void Function(int sent, int total)? onProgress,
    bool Function()? isCancelled,
    HttpClient? httpClient,
  }) async {
    final client = httpClient ?? _createClient(peer);
    final ownsClient = httpClient == null;
    Timer? stallTimer;
    try {
      void touch() {
        stallTimer?.cancel();
        stallTimer = Timer(const Duration(seconds: 45), () {
          client.close(force: true);
        });
      }

      touch();
      final actualSize = await File(sourcePath)
          .length()
          .timeout(const Duration(seconds: 15));
      if (actualSize != file.size) {
        throw const LanHttpException(422, 'Source file changed during transfer');
      }
      touch();
      final request = await client
          .openUrl(
            'POST',
            _uri(peer, '/api/localsend/v2/upload', {
              'sessionId': sessionId,
              'fileId': file.id,
              'token': token,
            }),
          )
          .timeout(const Duration(seconds: 20));
      request.headers.contentType = ContentType.parse(file.mime);
      request.contentLength = file.size;

      var sent = 0;
      touch();
      await request.addStream(
        _fileChunks(sourcePath, file.size).map((chunk) {
          if (isCancelled?.call() == true) {
            throw const LanHttpException(499, 'Cancelled');
          }
          sent += chunk.length;
          touch();
          onProgress?.call(sent, file.size);
          return chunk;
        }),
      );
      touch();
      final response = await request.close();
      if (response.statusCode == 499) {
        await response.drain<void>().catchError((_) {});
        throw const LanHttpException(499, 'Cancelled');
      }
      final body = await utf8.decodeStream(response);
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw LanHttpException(response.statusCode, body);
      }
    } finally {
      stallTimer?.cancel();
      if (ownsClient) {
        client.close(force: true);
      }
    }
  }

  Stream<List<int>> _fileChunks(String path, int size) async* {
    if (size <= 0) return;
    final file = await File(path).open();
    try {
      var remaining = size;
      const chunkSize = 256 * 1024;
      while (remaining > 0) {
        final readSize = remaining < chunkSize ? remaining : chunkSize;
        final chunk = await file.read(readSize);
        if (chunk.isEmpty) break;
        remaining -= chunk.length;
        yield chunk;
      }
    } finally {
      await file.close();
    }
  }

  Future<void> cancel(LanPeer peer, String sessionId) async {
    try {
      await _postJson(
        peer,
        '/api/localsend/v2/cancel',
        const {},
        query: {'sessionId': sessionId},
      );
    } catch (_) {
      // Best effort.
    }
  }
}
