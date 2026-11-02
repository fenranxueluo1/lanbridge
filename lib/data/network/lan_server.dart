import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import 'device_security.dart';
import 'lan_protocol.dart';

typedef LanIncomingHandler = Future<bool> Function(LanIncomingRequest request);
typedef LanProgressHandler = void Function(LanProgress progress);
typedef LanCompletionHandler = void Function(LanCompletion completion);

class _ServerSession {
  _ServerSession({
    required this.sessionId,
    required this.sender,
    required this.files,
    required this.tokens,
    required this.saveRoot,
  });

  final String sessionId;
  final LanPeer sender;
  final List<LanFileEntry> files;
  final Map<String, String> tokens;
  final String saveRoot;
  final Set<String> completedFileIds = {};
  final List<String> savedFiles = [];
  bool cancelled = false;
  bool waitingForAcceptance = true;
  DateTime lastActivity = DateTime.now();
  Future<void> Function()? abort;
}

/// LocalSend v2 compatible HTTPS receiver.
class LanServer {
  LanServer({
    required this.info,
    required this.security,
    required this.saveRoot,
    this.pin,
    this.onPeer,
    this.onIncoming,
    this.onProgress,
    this.onComplete,
    this.onRemoteCancel,
    this.tempRoot,
  });

  final LanDeviceInfo info;
  final DeviceSecurity security;
  final String Function() saveRoot;
  final String? pin;
  final LanPeerHandler? onPeer;
  final LanIncomingHandler? onIncoming;
  final LanProgressHandler? onProgress;
  final LanCompletionHandler? onComplete;
  final void Function(String sessionId)? onRemoteCancel;
  final String Function()? tempRoot;

  final _uuid = const Uuid();
  final Map<String, _ServerSession> _sessions = {};
  HttpServer? _server;
  Timer? _sessionWatchdog;
  bool _stopping = false;

  bool get isRunning => _server != null;

  int? get boundPort => _server?.port;

  Future<void> start() async {
    if (_server != null) return;
    final securityContext = security.buildSecurityContext();
    final HttpServer server;
    if (info.https) {
      server = await HttpServer.bindSecure(
        InternetAddress.anyIPv4,
        info.port,
        securityContext,
      );
    } else {
      server = await HttpServer.bind(InternetAddress.anyIPv4, info.port);
    }
    _server = server;
    _stopping = false;
    _sessionWatchdog?.cancel();
    _sessionWatchdog = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _pruneIdleSessions(),
    );
    server.listen((request) {
      unawaited(_handle(request));
    });
  }

  Future<void> stop() async {
    _stopping = true;
    _sessionWatchdog?.cancel();
    _sessionWatchdog = null;
    _sessions.clear();
    await _server?.close(force: true);
    _server = null;
  }

  void _pruneIdleSessions() {
    if (_sessions.isEmpty) return;
    final cutoff = DateTime.now().subtract(const Duration(seconds: 90));
    for (final session in _sessions.values.toList()) {
      if (session.waitingForAcceptance) continue;
      if (session.lastActivity.isAfter(cutoff)) continue;
      _sessions.remove(session.sessionId);
      session.cancelled = true;
      unawaited(session.abort?.call() ?? Future<void>.value());
      onComplete?.call(LanCompletion(
        sessionId: session.sessionId,
        success: false,
      ));
    }
  }

  Future<void> _handle(HttpRequest request) async {
    try {
      final path = request.uri.path;
      if (request.method == 'GET' && path == '/api/localsend/v2/info') {
        await _handleInfo(request);
        return;
      }
      if (request.method == 'POST' && path == '/api/localsend/v2/register') {
        await _handleRegister(request);
        return;
      }
      if (request.method == 'POST' &&
          path == '/api/localsend/v2/prepare-upload') {
        await _handlePrepareUpload(request);
        return;
      }
      if (request.method == 'POST' && path == '/api/localsend/v2/upload') {
        await _handleUpload(request);
        return;
      }
      if (request.method == 'POST' && path == '/api/localsend/v2/cancel') {
        await _handleCancel(request);
        return;
      }
      await _respondJson(request, 404, {'message': 'Not found'});
    } catch (error) {
      try {
        await _respondJson(request, 500, {'message': error.toString()});
      } catch (_) {
        // The response may already be closed.
      }
    }
  }

  Future<void> _handleInfo(HttpRequest request) async {
    final fingerprint = request.uri.queryParameters['fingerprint'];
    if (fingerprint == info.fingerprint) {
      await _respondJson(request, 412, {'message': 'Self-discovered'});
      return;
    }
    await _respondJson(request, 200, info.toInfoJson());
  }

  Future<void> _handleRegister(HttpRequest request) async {
    final payload = jsonDecode(await utf8.decodeStream(request));
    if (payload is! Map<String, dynamic>) {
      await _respondJson(request, 400, {'message': 'Malformed body'});
      return;
    }
    final peer = LanPeer.fromRegister(
      payload,
      ip: _remoteIp(request),
      fallbackPort: lanDefaultPort,
      fallbackHttps: info.https,
    );
    if (peer.fingerprint.isNotEmpty && peer.fingerprint == info.fingerprint) {
      await _respondJson(request, 412, {'message': 'Self-discovered'});
      return;
    }
    onPeer?.call(peer);
    await _respondJson(request, 200, info.toInfoJson());
  }

  Future<void> _handlePrepareUpload(HttpRequest request) async {
    if (_sessions.isNotEmpty) {
      await _respondJson(request, 409, {'message': 'Another session is active'});
      return;
    }

    final expectedPin = pin;
    if (expectedPin != null && expectedPin.isNotEmpty) {
      if (request.uri.queryParameters['pin'] != expectedPin) {
        await _respondJson(request, 401, {'message': 'Invalid PIN'});
        return;
      }
    }

    final payload = jsonDecode(await utf8.decodeStream(request));
    if (payload is! Map<String, dynamic>) {
      await _respondJson(request, 400, {'message': 'Malformed body'});
      return;
    }

    final infoJson = payload['info'];
    final filesJson = payload['files'];
    if (infoJson is! Map<String, dynamic> ||
        filesJson is! Map<String, dynamic>) {
      await _respondJson(request, 400, {'message': 'Missing info or files'});
      return;
    }

    final entries = <LanFileEntry>[];
    for (final value in filesJson.values) {
      if (value is Map<String, dynamic>) {
        try {
          entries.add(LanFileEntry.fromJson(value));
        } catch (_) {
          // Ignore malformed entries.
        }
      }
    }
    if (entries.isEmpty) {
      await _respondJson(request, 400, {'message': 'No files'});
      return;
    }

    final sender = LanPeer.fromMap(
      infoJson,
      ip: _remoteIp(request),
      fallbackPort: lanDefaultPort,
      fallbackHttps: info.https,
    );
    if (sender.fingerprint.isNotEmpty && sender.fingerprint == info.fingerprint) {
      await _respondJson(request, 409, {'message': 'Self transfer rejected'});
      return;
    }
    onPeer?.call(sender);

    final sessionId = _uuid.v4();
    final tokens = {for (final file in entries) file.id: _uuid.v4()};

    // A new session blocks other prepare-upload requests. Temporary directory
    // is created on each upload so this step is cheap.
    final session = _ServerSession(
      sessionId: sessionId,
      sender: sender,
      files: entries,
      tokens: tokens,
      saveRoot: saveRoot(),
    );
    _sessions[sessionId] = session;

    final bool accepted;
    try {
      accepted = await (onIncoming?.call(LanIncomingRequest(
            sessionId: sessionId,
            sender: sender,
            files: entries,
          )) ??
          Future<bool>.value(true));
    } catch (error) {
      _sessions.remove(sessionId);
      await _respondJson(request, 500, {'message': error.toString()});
      return;
    }

    if (!accepted) {
      _sessions.remove(sessionId);
      await _respondJson(request, 403, {'message': 'Declined'});
      return;
    }

    session.waitingForAcceptance = false;
    session.lastActivity = DateTime.now();
    try {
      await _respondJson(request, 200, {
        'sessionId': sessionId,
        'files': tokens,
      });
    } catch (_) {
      _sessions.remove(sessionId);
      onComplete?.call(LanCompletion(
        sessionId: sessionId,
        success: false,
      ));
    }
  }

  Future<void> _handleUpload(HttpRequest request) async {
    final query = request.uri.queryParameters;
    final session = _sessions[query['sessionId']];
    final fileId = query['fileId'];
    final token = query['token'];
    if (session == null) {
      await _respondJson(request, 404, {'message': 'Unknown session'});
      return;
    }
    if (fileId == null || token == null || session.tokens[fileId] != token) {
      await _failSession(session, request, 403, 'Invalid token');
      return;
    }

    LanFileEntry? entry;
    for (final file in session.files) {
      if (file.id == fileId) {
        entry = file;
        break;
      }
    }
    if (entry == null) {
      await _failSession(session, request, 404, 'Unknown file');
      return;
    }

    final target = safeResolvePath(session.saveRoot, entry.fileName);
    if (target == null) {
      await _failSession(session, request, 400, 'Invalid file name');
      return;
    }

    session.abort = () async {
      try {
        request.response.statusCode = 499;
        await request.response.close();
      } catch (_) {}
    };
    session.lastActivity = DateTime.now();

    final shortId = entry.id.length > 8 ? entry.id.substring(0, 8) : entry.id;
    final baseTemp = tempRoot?.call() ?? '';
    Directory tempParent = Directory(p.dirname(target));
    if (baseTemp.isNotEmpty) {
      try {
        final dir = Directory(baseTemp);
        await dir.create(recursive: true).timeout(const Duration(seconds: 10));
        tempParent = dir;
      } catch (_) {
        // Fall back to the destination directory.
      }
    }
    final temp = File(p.join(tempParent.path, '.lb-$shortId.part'));
    int received = 0;
    IOSink? sink;
    try {
      await temp.parent.create(recursive: true).timeout(const Duration(seconds: 15));
      sink = temp.openWrite();
      await for (final chunk in request.timeout(const Duration(seconds: 45))) {
        if (session.cancelled) {
          throw const LanHttpException(499, 'Cancelled');
        }
        sink.add(chunk);
        received += chunk.length;
        session.lastActivity = DateTime.now();
        onProgress?.call(LanProgress(
          sessionId: session.sessionId,
          fileId: entry.id,
          fileName: entry.fileName,
          received: received,
          total: entry.size,
        ));
      }
      if (session.cancelled) {
        throw const LanHttpException(499, 'Cancelled');
      }
      await sink.flush();
      await sink.close();
      sink = null;
      if (session.cancelled) {
        throw const LanHttpException(499, 'Cancelled');
      }

      if (received != entry.size) {
        await _failSession(
          session,
          request,
          422,
          'Size mismatch: expected ${entry.size}, got $received',
        );
        try {
          if (await temp.exists()) await temp.delete();
        } catch (_) {}
        return;
      }

      final destination = uniqueFile(target);
      await destination.parent
          .create(recursive: true)
          .timeout(const Duration(seconds: 15));
      try {
        await temp.rename(destination.path).timeout(
              const Duration(seconds: 30),
            );
      } on FileSystemException {
        await temp.copy(destination.path).timeout(
              const Duration(seconds: 60),
            );
        await temp.delete();
      }
      session.completedFileIds.add(entry.id);
      session.savedFiles.add(destination.path);
      session.lastActivity = DateTime.now();

      if (session.completedFileIds.length == session.files.length) {
        _sessions.remove(session.sessionId);
        onComplete?.call(LanCompletion(
          sessionId: session.sessionId,
          success: true,
          savedFiles: List.unmodifiable(session.savedFiles),
        ));
      }

      request.response.statusCode = HttpStatus.noContent;
      await request.response.close();
    } catch (error) {
      final cancelled = session.cancelled;
      try {
        await sink?.close();
      } catch (_) {}
      sink = null;
      try {
        if (await temp.exists()) await temp.delete();
      } catch (_) {}
      _sessions.remove(session.sessionId);
      if (cancelled) {
        try {
          request.response.statusCode = 499;
          await request.response.close();
        } catch (_) {}
      } else {
        onComplete?.call(LanCompletion(
          sessionId: session.sessionId,
          success: false,
        ));
        if (!_stopping) {
          try {
            await _respondJson(request, 500, {'message': error.toString()});
          } catch (_) {}
        }
      }
    } finally {
      session.abort = null;
    }
  }

  Future<void> _failSession(
    _ServerSession session,
    HttpRequest request,
    int statusCode,
    String message,
  ) async {
    _sessions.remove(session.sessionId);
    onComplete?.call(LanCompletion(
      sessionId: session.sessionId,
      success: false,
    ));
    try {
      await _respondJson(request, statusCode, {'message': message});
    } catch (_) {}
  }

  Future<void> _handleCancel(HttpRequest request) async {
    final sessionId = request.uri.queryParameters['sessionId'];
    if (sessionId != null) {
      final session = _sessions.remove(sessionId);
      if (session != null) {
        session.cancelled = true;
        unawaited(session.abort?.call() ?? Future<void>.value());
        onComplete?.call(LanCompletion(
          sessionId: sessionId,
          success: false,
          cancelled: true,
        ));
      } else {
        onRemoteCancel?.call(sessionId);
      }
    }
    await _respondJson(request, 200, {});
  }

  void cancelSession(String sessionId) {
    final session = _sessions.remove(sessionId);
    if (session == null) return;
    session.cancelled = true;
    unawaited(session.abort?.call() ?? Future<void>.value());
  }

  String _remoteIp(HttpRequest request) {
    final address = request.connectionInfo?.remoteAddress;
    if (address == null) return '127.0.0.1';
    final ip = address.address;
    return ip == '::1' ? '127.0.0.1' : ip;
  }

  Future<void> _respondJson(
    HttpRequest request,
    int statusCode,
    Map<String, dynamic> body,
  ) async {
    request.response
      ..statusCode = statusCode
      ..headers.contentType = ContentType.json
      ..write(jsonEncode(body));
    await request.response.close();
  }
}
