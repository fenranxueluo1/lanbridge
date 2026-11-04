import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../core/app_info.dart';
import '../core/platform/app_platform.dart';
import '../core/platform/background_transfer.dart';
import '../core/platform/harmony_downloads.dart';
import '../core/platform/storage_access.dart';
import '../core/utils/physics_device_name.dart';
import 'app_settings_store.dart';
import 'models/app_settings.dart';
import 'models/device.dart';
import 'models/transfer.dart';
import 'network/device_security.dart';
import 'network/lan_client.dart';
import 'network/lan_discovery.dart';
import 'network/lan_protocol.dart';
import 'network/lan_server.dart';

class IncomingTransfer {
  IncomingTransfer({
    required this.job,
    required this.request,
    required this.decision,
  });

  final TransferJob job;
  final LanIncomingRequest request;
  final Completer<bool> decision;
}

/// Real LAN engine state. It starts an HTTPS LocalSend-compatible server and
/// UDP discovery task, and drives the existing UI models from real events.
class AppController extends ChangeNotifier with WidgetsBindingObserver {
  AppController({this.enableEngine = true}) {
    WidgetsBinding.instance.addObserver(this);
    settings = AppSettings(
      deviceName: '我的设备 · ${AppPlatform.platformLabel}',
      savePath: _defaultSavePath(),
    );
    if (enableEngine) {
      unawaited(_initialize());
    }
  }

  final bool enableEngine;
  final _uuid = const Uuid();
  final Map<String, Device> _devices = {};
  final List<TransferJob> _jobs = [];
  final Set<String> _cancelled = {};
  final Map<String, String> _remoteSessionIds = {};
  final Map<String, void Function()> _sendAborts = {};
  final Set<String> _pendingRemoteCancels = {};
  final Map<String, LanPeer> _incomingPeers = {};
  final Map<String, LanPeer> _outgoingPeers = {};
  final Map<String, DateTime> _transferStartTimes = {};
  final List<TransferFile> _pendingSendFiles = [];
  int _pendingSendRevision = 0;

  late AppSettings settings;

  DeviceSecurity? _security;
  LanDeviceInfo? _info;
  LanServer? _server;
  LanDiscovery? _discovery;
  LanClient? _client;
  IncomingTransfer? _pendingIncoming;
  Timer? _pruneTimer;
  Timer? _settingsSaveTimer;
  Timer? _nameCollisionTimer;
  String? _transferTempRoot;
  String _localAddress = '';

  bool _scanning = false;
  bool _foreground = true;
  bool _disposed = false;
  bool _restarting = false;
  bool _backgroundTransferActive = false;
  DateTime? _lastNotify;
  String? _engineError;

  bool get isScanning => _scanning;
  bool get engineReady => _server?.isRunning == true && _info != null;
  String? get engineError => _engineError;
  int? get localPort => _server?.boundPort;
  String? get localFingerprint => _security?.certificateHash;
  IncomingTransfer? get pendingIncoming => _pendingIncoming;

  /// Files dropped onto the desktop window and waiting for the Send page.
  int get pendingSendRevision => _pendingSendRevision;

  void addPendingSendFiles(List<TransferFile> files) {
    if (files.isEmpty) return;
    _pendingSendFiles.addAll(files);
    _pendingSendRevision++;
    _safeNotify();
  }

  List<TransferFile> takePendingSendFiles() {
    if (_pendingSendFiles.isEmpty) return const [];
    final files = List<TransferFile>.of(_pendingSendFiles);
    _pendingSendFiles.clear();
    return files;
  }

  List<Device> get devices => List.unmodifiable(_devices.values);

  List<Device> get favoriteDevices =>
      devices.where((device) => device.isFavorite).toList();

  List<Device> get nearbyDevices =>
      devices.where((device) => !device.isFavorite).toList();

  int get onlineCount => devices.where((device) => device.isOnline).length;

  List<TransferJob> get activeJobs =>
      _jobs.where((job) => job.status.isActive).toList();

  List<TransferJob> get historyJobs =>
      _jobs.where((job) => job.status.isFinished).toList()
        ..sort((a, b) => b.startedAt.compareTo(a.startedAt));

  int get activeSpeedBytes =>
      activeJobs.fold(0.0, (sum, job) => sum + job.speed).round();

  int get savedBytes => _jobs.fold(0, (sum, job) => sum + job.savedBytes);

  Device? deviceById(String id) => _devices[id];

  TransferJob? jobById(String id) {
    for (final job in _jobs) {
      if (job.id == id) return job;
    }
    return null;
  }

  static String _defaultSavePath() {
    if (AppPlatform.isWindows) {
      return 'C:\\Users\\Public\\Downloads\\LANBridge';
    }
    if (AppPlatform.isAndroid) {
      return '/storage/emulated/0/Download/LANBridge';
    }
    if (AppPlatform.isIOS) {
      return 'LANBridge';
    }
    if (AppPlatform.isHarmony) {
      return 'LANBridge';
    }
    return '/home/downloads/LANBridge';
  }

  // Engine lifecycle ---------------------------------------------------------

  Future<void> _initialize() async {
    try {
      final loaded = await AppSettingsStore.load();
      if (loaded != null) {
        settings = loaded;
        _safeNotify();
      }
      if (settings.autoDeviceName) {
        settings.deviceName =
            PhysicsDeviceName.generate(avoid: {settings.deviceName});
        _safeNotify();
      }
      _security = await DeviceSecurity.loadOrCreate();
      await _ensureSavePath();
      if (AppPlatform.isHarmony && settings.saveToDownloads) {
        unawaited(_refreshDownloadsDir());
      }
      _localAddress = await _findLocalAddress();
      try {
        final support = await getApplicationSupportDirectory();
        _transferTempRoot = p.join(support.path, '.transfer_tmp');
      } catch (_) {
        _transferTempRoot = null;
      }
      if (AppPlatform.isAndroid &&
          settings.savePath.startsWith('/storage/')) {
        unawaited(StorageAccess.ensureManageStorage());
      }
      _scheduleSave();
      await _startEngine();
      _startPruneTimer();
    } catch (error) {
      _engineError = error.toString();
      _safeNotify();
    }
  }

  Future<void> _ensureSavePath() async {
    if (AppPlatform.isHarmony) {
      try {
        final directory = await getApplicationDocumentsDirectory();
        settings.savePath = p.join(directory.path, 'LANBridge');
      } catch (_) {
        // Keep the platform fallback.
      }
      return;
    }
    final current = settings.savePath.trim();
    if (current.isNotEmpty &&
        current != _defaultSavePath() &&
        p.isAbsolute(current)) {
      return;
    }
    try {
      Directory? directory;
      try {
        directory = await getDownloadsDirectory();
      } catch (_) {
        // Not supported on this platform.
      }
      directory ??= await getApplicationDocumentsDirectory();
      settings.savePath = p.join(directory.path, 'LANBridge');
    } catch (_) {
      // Keep the platform fallback.
    }
  }

  /// Keeps the stored downloads path in sync with the authorized folder.
  Future<void> _refreshDownloadsDir() async {
    final dir = await HarmonyDownloads.directory();
    if (dir != null && dir.isNotEmpty && dir != settings.downloadsDir) {
      settings.downloadsDir = dir;
      _scheduleSave();
      _safeNotify();
    }
  }

  void _scheduleSave() {
    _settingsSaveTimer?.cancel();
    _settingsSaveTimer = Timer(const Duration(milliseconds: 200), () {
      if (!_disposed) {
        unawaited(AppSettingsStore.save(settings));
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!AppPlatform.isMobile) return;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _foreground = false;
      _settingsSaveTimer?.cancel();
      unawaited(AppSettingsStore.save(settings));
      _pauseDiscovery();
      if (activeJobs.isEmpty) {
        _syncBackgroundMode();
        return;
      }
      if (AppPlatform.isAndroid || AppPlatform.isHarmony) {
        _syncBackgroundMode();
        return;
      }
      for (final job in activeJobs.toList()) {
        cancelJob(job.id);
      }
      return;
    }
    if (state == AppLifecycleState.resumed) {
      _foreground = true;
      _syncBackgroundMode();
      _resumeDiscovery();
    }
  }

  void _startPruneTimer() {
    if (!_foreground) return;
    _pruneTimer?.cancel();
    _pruneTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _pruneDevices();
      _maybeScanForStalePeers();
    });
  }

  void _pauseDiscovery() {
    _foreground = false;
    _pruneTimer?.cancel();
    _pruneTimer = null;
    final discovery = _discovery;
    _discovery = null;
    _scanning = false;
    if (discovery != null) {
      unawaited(discovery.stop());
    }
    _safeNotify();
  }

  void _resumeDiscovery() {
    if (_disposed) return;
    _startPruneTimer();
    if (!settings.discoveryEnabled || _discovery != null) return;
    if (_info == null || _server?.isRunning != true) return;
    unawaited(_startDiscovery());
  }

  void _syncBackgroundMode() {
    final active = activeJobs.isNotEmpty;
    if (active == _backgroundTransferActive) return;
    _backgroundTransferActive = active;
    if (active) {
      unawaited(BackgroundTransfer.start());
    } else {
      unawaited(BackgroundTransfer.stop());
    }
  }

  Future<String> _findLocalAddress() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
      );
      String? fallback;
      String? preferred;
      for (final interface in interfaces) {
        final name = interface.name.toLowerCase();
        if (name.contains('rmnet') ||
            name.contains('cellular') ||
            name.contains('wwan') ||
            name.contains('pdp') ||
            name.contains('clat')) {
          continue;
        }
        final isLanName = name.contains('wlan') ||
            name.contains('wifi') ||
            name.contains('ap') ||
            name.contains('eth') ||
            name.startsWith('en');
        for (final address in interface.addresses) {
          if (address.isLoopback) continue;
          final ip = address.address;
          if (ip.startsWith('169.254.')) continue;
          final parts = ip.split('.');
          if (parts.length != 4) continue;
          final first = int.tryParse(parts[0]);
          final second = int.tryParse(parts[1]);
          if (first == null || second == null) continue;
          final isPrivate = first == 10 ||
              (first == 192 && second == 168) ||
              (first == 172 && second >= 16 && second <= 31);
          if (!isPrivate) {
            fallback ??= ip;
            continue;
          }
          if (isLanName) {
            preferred ??= ip;
          } else {
            fallback ??= ip;
          }
        }
      }
      return preferred ?? fallback ?? '';
    } catch (_) {
      return '';
    }
  }

  Future<void> _startEngine() async {
    final security = _security;
    if (security == null) return;

    final basePort = settings.port;
    LanServer? startedServer;
    LanDeviceInfo? startedInfo;
    Object? lastError;

    for (var offset = 0; offset < 6; offset++) {
      final port = basePort + offset;
      final info = _buildInfo(security, port);
      final server = LanServer(
        info: info,
        security: security,
        saveRoot: () => _saveRoot,
        pin: settings.pinEnabled ? settings.pin : null,
        onPeer: _onPeer,
        onIncoming: _onIncoming,
        onProgress: _onProgress,
        onComplete: _onComplete,
        onRemoteCancel: _onRemoteCancel,
        tempRoot: () => _transferTempRoot ?? '',
      );
      try {
        await server.start();
        startedServer = server;
        startedInfo = info;
        break;
      } catch (error) {
        lastError = error;
      }
    }

    if (startedServer == null || startedInfo == null) {
      _engineError = '无法启动局域网服务：$lastError';
      _safeNotify();
      return;
    }

    _server = startedServer;
    _info = startedInfo;
    _engineError = null;
    _client = LanClient(self: startedInfo, security: security);

    if (settings.discoveryEnabled) {
      if (_foreground) await _startDiscovery();
    }
    _safeNotify();
  }

  Future<void> _startDiscovery() async {
    if (!_foreground) return;
    final info = _info;
    final client = _client;
    if (info == null || client == null) return;
    await _discovery?.stop();
    final discovery = LanDiscovery(
      self: info,
      client: client,
      onPeer: _onPeer,
      onScanningChanged: (scanning) {
        _scanning = scanning;
        _safeNotify();
      },
    );
    _discovery = discovery;
    await discovery.start();
    unawaited(Future<void>.delayed(const Duration(milliseconds: 600), () async {
      if (!_disposed && _devices.isEmpty) await discovery.scanSubnet();
    }));
  }

  Future<void> _restartEngine() async {
    if (_restarting || !enableEngine) return;
    _restarting = true;
    try {
      await _discovery?.stop();
      _discovery = null;
      await _server?.stop();
      _server = null;
      _info = null;
      await _startEngine();
    } finally {
      _restarting = false;
    }
  }

  LanDeviceInfo _buildInfo(DeviceSecurity security, int port) {
    return LanDeviceInfo(
      alias: settings.deviceName,
      deviceModel: AppPlatform.localModelLabel,
      deviceType: AppPlatform.isMobile ? 'mobile' : 'desktop',
      fingerprint: security.certificateHash,
      port: port,
      https: settings.httpsEnabled,
      ip: _localAddress,
    );
  }

  String get _saveRoot {
    final path = settings.savePath.trim();
    if (path.isEmpty) return Directory.systemTemp.path;
    return path;
  }

  String get saveRoot => _saveRoot;

  // Discovery ---------------------------------------------------------------

  Future<void> refreshDiscovery() async {
    if (!settings.discoveryEnabled) {
      _engineError = '设备发现已关闭';
      _safeNotify();
      return;
    }
    if (_discovery == null) {
      await _startDiscovery();
    }
    await _tryReconnectKnown();
    final discovery = _discovery;
    if (discovery != null) {
      unawaited(discovery.announce());
      await discovery.scanSubnet(force: true);
    }
  }

  void _maybeScanForStalePeers() {
    unawaited(_checkStalePeers());
  }

  Future<void> _checkStalePeers() async {
    final discovery = _discovery;
    if (discovery == null) return;
    final now = DateTime.now();
    final stale = _devices.isEmpty ||
        _devices.values.any((device) {
          final lastSeen = device.lastSeen;
          return lastSeen == null ||
              now.difference(lastSeen) > const Duration(seconds: 25);
        });
    if (!stale) return;

    final reconnected = await _tryReconnectKnown();
    if (!reconnected) {
      await discovery.scanSubnet();
    }
  }

  /// Fast path for peers that restarted on the same address but whose
  /// multicast announcement was lost. Probes known IPs before a subnet scan.
  Future<bool> _tryReconnectKnown() async {
    final client = _client;
    if (client == null) return false;
    final now = DateTime.now();
    final staleDevices = _devices.values.where((device) {
      final lastSeen = device.lastSeen;
      return lastSeen == null ||
          now.difference(lastSeen) > const Duration(seconds: 20);
    }).toList();
    if (staleDevices.isEmpty) return false;

    for (final device in staleDevices) {
      final base = _toPeer(device);
      final ports = <int>{
        device.port,
        for (var offset = 0; offset < 6; offset++) lanDefaultPort + offset,
      };
      for (final port in ports) {
        for (final https in {device.https, !device.https}) {
          final candidate = LanPeer(
            ip: base.ip,
            alias: base.alias,
            deviceModel: base.deviceModel,
            deviceType: base.deviceType,
            fingerprint: base.fingerprint,
            port: port,
            https: https,
            version: base.version,
          );
          final found = await client.probe(candidate);
          if (found == null) continue;
          _onPeer(found);
          try {
            final registered = await client.register(found);
            if (registered != null) _onPeer(registered);
          } catch (_) {}
          return true;
        }
      }
    }
    return false;
  }

  void _onPeer(LanPeer peer) {
    if (peer.fingerprint.isNotEmpty && peer.fingerprint == _info?.fingerprint) {
      return;
    }
    final key = peer.fingerprint.isNotEmpty ? peer.fingerprint : peer.ip;
    _devices.removeWhere(
      (id, device) => id != key && device.ip == peer.ip,
    );
    final existing = _devices[key];
    _devices[key] = peer.toDevice(favorite: existing?.isFavorite ?? false);
    _resolveNameConflict(peer);
    _safeNotify();
  }

  void _resolveNameConflict(LanPeer peer) {
    final info = _info;
    if (!settings.autoDeviceName || info == null) return;
    final peerAlias = peer.alias.trim();
    if (peerAlias.isEmpty || !_sameName(peerAlias, info.alias)) return;

    if (peer.fingerprint.isEmpty ||
        info.fingerprint.compareTo(peer.fingerprint) < 0) {
      _assignAutoName(additionalAvoid: {peerAlias});
      return;
    }

    _nameCollisionTimer?.cancel();
    _nameCollisionTimer = Timer(const Duration(milliseconds: 1600), () {
      _nameCollisionTimer = null;
      if (_disposed || !settings.autoDeviceName) return;
      final current = _info;
      if (current == null) return;
      final stillConflicting = _devices.values.any(
        (device) =>
            device.fingerprint != current.fingerprint &&
            _sameName(device.name, current.alias),
      );
      if (stillConflicting) _assignAutoName();
    });
  }

  void _assignAutoName({Set<String> additionalAvoid = const {}}) {
    _nameCollisionTimer?.cancel();
    _nameCollisionTimer = null;
    final avoid = <String>{
      settings.deviceName,
      if (_info != null) _info!.alias,
      for (final device in _devices.values) device.name,
      ...additionalAvoid,
    };
    final name = PhysicsDeviceName.generate(avoid: avoid);
    settings.deviceName = name;
    _info?.alias = name;
    _scheduleSave();
    _safeNotify();
    final discovery = _discovery;
    if (discovery != null) {
      unawaited(discovery.announce());
    }
  }

  bool _sameName(String first, String second) =>
      PhysicsDeviceName.normalize(first) ==
      PhysicsDeviceName.normalize(second);

  void _pruneDevices() {
    final cutoff = DateTime.now().subtract(const Duration(seconds: 75));
    final before = _devices.length;
    _devices.removeWhere(
      (_, device) =>
          device.lastSeen != null && device.lastSeen!.isBefore(cutoff),
    );
    if (_devices.length != before) _safeNotify();
  }

  Future<bool> connectManually(String host) async {
    final text = host.trim();
    if (text.isEmpty) return false;
    var ip = text;
    var port = settings.port;
    if (text.contains(':')) {
      final parts = text.split(':');
      ip = parts.first;
      port = int.tryParse(parts.last) ?? port;
    }
    final peer = LanPeer(
      ip: ip,
      alias: ip,
      deviceModel: 'Unknown device',
      deviceType: 'desktop',
      fingerprint: '',
      port: port,
      https: settings.httpsEnabled,
      version: lanProtocolVersion,
    );
    try {
      final registered = await _client?.register(peer);
      if (registered == null) return false;
      _onPeer(registered);
      return true;
    } catch (_) {
      return false;
    }
  }

  void toggleFavorite(String deviceId) {
    final device = _devices[deviceId];
    if (device == null) return;
    _devices[deviceId] = device.copyWith(isFavorite: !device.isFavorite);
    _safeNotify();
  }

  void forgetDevice(String deviceId) {
    _devices.remove(deviceId);
    _safeNotify();
  }

  // Sending -----------------------------------------------------------------

  Future<List<TransferJob>> startTransfers({
    required List<Device> targets,
    required List<TransferFile> files,
    required TransferMode mode,
  }) async {
    final usableFiles =
        files.where((file) => file.path != null && !file.isDirectory).toList();
    if (usableFiles.isEmpty) return const [];

    final created = <TransferJob>[];
    final now = DateTime.now();
    for (final target in targets) {
      if (!target.isOnline) continue;
      final known = _devices[target.id];
      if (known == null) continue;
      final lastSeen = known.lastSeen;
      if (lastSeen != null &&
          now.difference(lastSeen) > const Duration(seconds: 45)) {
        _devices.remove(target.id);
        continue;
      }
      final job = TransferJob(
        id: _uuid.v4(),
        peerId: target.id,
        peerName: target.name,
        peerKind: target.kind,
        direction: TransferDirection.send,
        files: usableFiles
            .map((file) => file.copyWith(transferred: 0))
            .toList(),
        mode: mode,
        status: TransferStatus.waiting,
        startedAt: DateTime.now(),
        peerIp: target.ip,
      );
      _jobs.insert(0, job);
      created.add(job);
      _outgoingPeers[job.id] = _toPeer(target);
      unawaited(_runSendJob(job, target));
    }
    _safeNotify();
    return created;
  }

  Future<void> _runSendJob(TransferJob job, Device target) async {
    final client = _client;
    if (client == null) {
      job.markFailed('传输引擎未就绪');
      _safeNotify();
      return;
    }

    job.status = TransferStatus.transferring;
    _safeNotify();
    final peer = _toPeer(target);
    final stopwatch = Stopwatch();

    final entries = <LanFileEntry>[];
    for (final file in job.files) {
      final path = file.path;
      if (path == null) continue;
      final entry = LanFileEntry(
        id: _uuid.v4(),
        fileName: file.name,
        size: file.size,
        mime: lookupMimeType(file.name) ?? 'application/octet-stream',
        sourcePath: path,
      );
      file.remoteId = entry.id;
      entries.add(entry);
    }

    HttpClient? uploadClient;
    try {
      final prepared = await client.prepareUpload(peer, entries);
      _remoteSessionIds[job.id] = prepared.sessionId;

      if (_pendingRemoteCancels.remove(prepared.sessionId) ||
          _cancelled.contains(job.id)) {
        await client.cancel(peer, prepared.sessionId);
        job.status = TransferStatus.cancelled;
        job.speed = 0;
        _safeNotify();
        return;
      }

      stopwatch.start();
      _transferStartTimes[job.id] = DateTime.now();

      for (final entry in entries) {
        if (_cancelled.contains(job.id)) {
          await client.cancel(peer, prepared.sessionId);
          job.status = TransferStatus.cancelled;
          job.speed = 0;
          _safeNotify();
          return;
        }
        final token = prepared.tokens[entry.id];
        if (token == null) continue;
        final file = job.files.firstWhere(
          (item) => item.remoteId == entry.id,
          orElse: () => TransferFile(name: entry.fileName, size: entry.size),
        );
        uploadClient = client.newClient(peer);
        _sendAborts[job.id] = () {
          uploadClient?.close(force: true);
        };
        try {
          await client.upload(
            peer,
            sessionId: prepared.sessionId,
            file: entry,
            token: token,
            sourcePath: entry.sourcePath!,
            httpClient: uploadClient,
            onProgress: (sent, total) {
              file.transferred = sent;
              final seconds = stopwatch.elapsedMilliseconds / 1000.0;
              if (seconds > 0.2) {
                job.speed = job.transferredBytes / seconds;
              }
              _throttledNotify();
            },
            isCancelled: () => _cancelled.contains(job.id),
          );
        } finally {
          uploadClient.close(force: true);
          uploadClient = null;
          _sendAborts.remove(job.id);
        }
        file.transferred = file.size;
        _safeNotify();
      }

      if (_cancelled.contains(job.id)) {
        job.status = TransferStatus.cancelled;
        job.speed = 0;
        _safeNotify();
        return;
      }
      job.markCompleted();
      _notifyTransferComplete(job, received: false);
      _safeNotify();
    } on LanHttpException catch (error) {
      if (_cancelled.contains(job.id) || error.statusCode == 499) {
        job.status = TransferStatus.cancelled;
        job.speed = 0;
      } else {
        job.markFailed(_sendErrorMessage(error));
        final remoteId = _remoteSessionIds[job.id];
        if (remoteId != null) {
          unawaited(client.cancel(peer, remoteId));
        }
      }
      _safeNotify();
    } catch (error) {
      if (_cancelled.contains(job.id)) {
        job.status = TransferStatus.cancelled;
        job.speed = 0;
      } else {
        job.markFailed(_sendNetworkMessage(error));
        final remoteId = _remoteSessionIds[job.id];
        if (remoteId != null) {
          unawaited(client.cancel(peer, remoteId));
        }
      }
      _safeNotify();
    } finally {
      uploadClient?.close(force: true);
      _sendAborts.remove(job.id);
      _remoteSessionIds.remove(job.id);
      _outgoingPeers.remove(job.id);
      _transferStartTimes.remove(job.id);
      _cancelled.remove(job.id);
    }
  }

  String _sendErrorMessage(LanHttpException error) {
    final body = error.body.trim();
    final detail = body.length > 160 ? '${body.substring(0, 160)}…' : body;
    return switch (error.statusCode) {
      401 => '对方设置了 PIN，需要输入 PIN',
      403 => '对方拒绝了传输',
      409 => error.body.toLowerCase().contains('self')
          ? '目标地址指向本机，请检查模拟器网络是否使用桥接'
          : '对方正忙，请稍后再试',
      429 => '尝试次数过多，请稍后再试',
      422 => '文件校验失败',
      500 => detail.isEmpty ? '传输失败（HTTP 500）' : '传输失败（HTTP 500）：$detail',
      _ => '传输失败（HTTP ${error.statusCode}）',
    };
  }

  String _sendNetworkMessage(Object error) {
    if (error is SocketException) {
      if (AppPlatform.isWindows) {
        return '目标设备不可达。若对方是同一台电脑上的 HarmonyOS 模拟器，模拟器通常使用 NAT，Windows 无法反向连接；请改用桥接网络，或先用 hdc 端口转发，再通过“手动连接”访问 127.0.0.1。';
      }
      return '目标设备不可达，请确认两台设备在同一局域网，并检查防火墙或热点隔离';
    }
    if (error is TimeoutException) {
      return '连接超时，请确认接收设备在线并处于同一局域网';
    }
    return error.toString();
  }

  LanPeer _toPeer(Device device) {
    return LanPeer(
      ip: device.ip,
      alias: device.name,
      deviceModel: device.model,
      deviceType: device.kind == DeviceKind.phone ||
              device.kind == DeviceKind.tablet
          ? 'mobile'
          : 'desktop',
      fingerprint: device.fingerprint,
      port: device.port,
      https: device.https,
      version: device.version,
    );
  }

  // Receiving ---------------------------------------------------------------

  Future<bool> _onIncoming(LanIncomingRequest request) async {
    if (!settings.receiveEnabled) return false;
    if (_pendingIncoming != null) return false;

    final sender = request.sender;
    final job = TransferJob(
      id: request.sessionId,
      peerId: sender.fingerprint,
      peerName: sender.alias,
      peerKind: kindFromDeviceType(sender.deviceType, sender.deviceModel),
      direction: TransferDirection.receive,
      files: [
        for (final file in request.files)
          TransferFile(
            name: file.fileName,
            size: file.size,
            remoteId: file.id,
          ),
      ],
      mode: TransferMode.standard,
      status: TransferStatus.waiting,
      startedAt: DateTime.now(),
      peerIp: sender.ip,
    );
    _jobs.insert(0, job);
    _incomingPeers[job.id] = sender;

    final favorite = _devices.values.any(
      (device) =>
          device.isFavorite &&
          device.fingerprint.isNotEmpty &&
          device.fingerprint == sender.fingerprint,
    );
    if (settings.autoAcceptFavorites && favorite) {
      job.status = TransferStatus.transferring;
      _safeNotify();
      return true;
    }

    final pending = IncomingTransfer(
      job: job,
      request: request,
      decision: Completer<bool>(),
    );
    _pendingIncoming = pending;
    _safeNotify();

    final accepted = await pending.decision.future;
    if (accepted) {
      job.status = TransferStatus.transferring;
    } else {
      job.status = TransferStatus.cancelled;
      _incomingPeers.remove(job.id);
    }
    _safeNotify();
    return accepted;
  }

  void acceptIncoming(TransferJob job) {
    final pending = _pendingIncoming;
    if (pending == null || pending.job.id != job.id) return;
    _pendingIncoming = null;
    if (!pending.decision.isCompleted) pending.decision.complete(true);
    _safeNotify();
  }

  void declineIncoming(TransferJob job) {
    final pending = _pendingIncoming;
    if (pending == null || pending.job.id != job.id) return;
    _pendingIncoming = null;
    if (!pending.decision.isCompleted) pending.decision.complete(false);
    _incomingPeers.remove(job.id);
    job.status = TransferStatus.cancelled;
    _safeNotify();
  }

  void _onProgress(LanProgress progress) {
    final job = jobById(progress.sessionId);
    if (job == null) return;
    for (final file in job.files) {
      if (file.remoteId == progress.fileId) {
        file.transferred = progress.received;
        break;
      }
    }
    final started = _transferStartTimes.putIfAbsent(
      job.id,
      () => DateTime.now(),
    );
    final elapsed = DateTime.now().difference(started).inMilliseconds;
    if (elapsed > 500) {
      job.speed = job.transferredBytes / (elapsed / 1000);
    }
    _throttledNotify();
  }

  void _onComplete(LanCompletion completion) {
    final job = jobById(completion.sessionId);
    if (job == null) return;
    _incomingPeers.remove(completion.sessionId);
    _transferStartTimes.remove(completion.sessionId);
    if (completion.cancelled) {
      if (!job.status.isFinished) {
        job.status = TransferStatus.cancelled;
        job.speed = 0;
        _safeNotify();
      }
      return;
    }
    if (job.status == TransferStatus.cancelled) return;
    job.savedFiles = List.of(completion.savedFiles);
    if (completion.success) {
      job.markCompleted();
      _notifyTransferComplete(job, received: true);
      if (AppPlatform.isHarmony && settings.saveToDownloads) {
        unawaited(_exportReceivedToDownloads(job));
      }
    } else {
      job.markFailed('接收失败');
    }
    _safeNotify();
  }

  /// Moves freshly received sandbox files into the public downloads folder
  /// (HarmonyOS). Files that fail to export simply stay in the sandbox, so
  /// nothing is ever lost.
  Future<void> _exportReceivedToDownloads(TransferJob job) async {
    final dir = settings.downloadsDir;
    if (dir.isEmpty || job.savedFiles.isEmpty) return;
    final sources = List<String>.of(job.savedFiles);
    final results = await HarmonyDownloads.exportFiles(dir, sources);
    if (_disposed || results.length != sources.length) return;
    final finalPaths = <String>[];
    var moved = false;
    for (var index = 0; index < results.length; index++) {
      final destination = results[index];
      if (destination != null) {
        finalPaths.add(destination);
        moved = true;
      } else {
        finalPaths.add(sources[index]);
      }
    }
    if (moved) {
      job.savedFiles = finalPaths;
      _safeNotify();
    }
  }

  void _notifyTransferComplete(
    TransferJob job, {
    required bool received,
  }) {
    if (!AppPlatform.isMobile) return;
    final zh = settings.locale.languageCode != 'en';
    final count = job.files.length;
    final title = zh ? '传输完成' : 'Transfer complete';
    final body = received
        ? (zh ? '已接收 $count 个文件' : 'Received $count file(s)')
        : (zh ? '已发送 $count 个文件' : 'Sent $count file(s)');
    unawaited(BackgroundTransfer.notifyComplete(title: title, body: body));
  }

  void _onRemoteCancel(String remoteSessionId) {
    String? jobId;
    for (final entry in _remoteSessionIds.entries) {
      if (entry.value == remoteSessionId) {
        jobId = entry.key;
        break;
      }
    }
    if (jobId == null) {
      if (_pendingRemoteCancels.length < 64) {
        _pendingRemoteCancels.add(remoteSessionId);
      }
      return;
    }
    final job = jobById(jobId);
    if (job == null || job.status.isFinished) return;
    _cancelled.add(jobId);
    _sendAborts[jobId]?.call();
    job.status = TransferStatus.cancelled;
    job.speed = 0;
    _safeNotify();
  }

  // Job controls ------------------------------------------------------------

  void pauseJob(String id) {
    // LocalSend v2 has no pause/resume; the UI does not expose it.
  }

  void resumeJob(String id) {
    // LocalSend v2 has no pause/resume; the UI does not expose it.
  }

  void cancelJob(String id) {
    final job = jobById(id);
    if (job == null || job.status.isFinished) return;
    if (job.direction == TransferDirection.receive) {
      final device = deviceById(job.peerId);
      final sender = _incomingPeers.remove(id) ??
          (device != null ? _toPeer(device) : null);
      _server?.cancelSession(id);
      if (sender != null) {
        unawaited(_client?.cancel(sender, id) ?? Future<void>.value());
      }
      job.status = TransferStatus.cancelled;
    } else {
      _cancelled.add(id);
      _sendAborts[id]?.call();
      final remoteId = _remoteSessionIds[id];
      final device = deviceById(job.peerId);
      final peer = _outgoingPeers[id] ??
          (device != null ? _toPeer(device) : null);
      if (peer != null && remoteId != null) {
        unawaited(_client?.cancel(peer, remoteId) ?? Future<void>.value());
      }
      job.status = TransferStatus.cancelled;
    }
    final pending = _pendingIncoming;
    if (pending != null && pending.job.id == id) {
      _pendingIncoming = null;
      if (!pending.decision.isCompleted) pending.decision.complete(false);
    }
    _transferStartTimes.remove(id);
    job.speed = 0;
    _safeNotify();
  }

  void retryJob(String id) {
    final job = jobById(id);
    if (job == null || !job.status.isFinished) return;
    if (job.direction != TransferDirection.send) return;
    final target = deviceById(job.peerId);
    if (target == null) return;
    final files = job.files
        .where((file) => file.path != null)
        .map((file) => file.copyWith(transferred: 0))
        .toList();
    if (files.isEmpty) return;
    unawaited(startTransfers(
      targets: [target],
      files: files,
      mode: job.mode,
    ));
  }

  void clearHistory() {
    _jobs.removeWhere((job) => job.status.isFinished);
    _safeNotify();
  }

  // Settings ----------------------------------------------------------------

  void setDeviceName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    settings.deviceName = trimmed;
    settings.autoDeviceName = false;
    _nameCollisionTimer?.cancel();
    _nameCollisionTimer = null;
    _scheduleSave();
    _safeNotify();
    unawaited(_restartEngine());
  }

  void setAutoDeviceName(bool value) {
    settings.autoDeviceName = value;
    if (value) {
      _assignAutoName();
    } else {
      _nameCollisionTimer?.cancel();
      _nameCollisionTimer = null;
      _scheduleSave();
      _safeNotify();
    }
  }

  void setSavePath(String value) {
    settings.savePath = value;
    _settingsSaveTimer?.cancel();
    unawaited(AppSettingsStore.save(settings));
    if (AppPlatform.isAndroid && value.startsWith('/storage/')) {
      unawaited(StorageAccess.ensureManageStorage());
    }
    _safeNotify();
  }

  /// HarmonyOS: switches the destination of received files between the app
  /// sandbox and the public downloads folder. Returns false when the public
  /// folder could not be authorized (the previous choice is kept).
  Future<bool> setSaveToDownloads(bool value) async {
    if (value) {
      var dir = await HarmonyDownloads.directory();
      dir ??= await HarmonyDownloads.authorize();
      if (dir == null || dir.isEmpty) {
        return false;
      }
      settings.downloadsDir = dir;
    }
    settings.saveToDownloads = value;
    _scheduleSave();
    _safeNotify();
    return true;
  }

  void setThemeMode(ThemeMode mode) {
    settings.themeMode = mode;
    _scheduleSave();
    _safeNotify();
  }

  void setLocale(Locale locale) {
    settings.locale = locale;
    _scheduleSave();
    _safeNotify();
  }

  void setPort(int port) {
    settings.port = port;
    _scheduleSave();
    _safeNotify();
    unawaited(_restartEngine());
  }

  void setHttpsEnabled(bool value) {
    settings.httpsEnabled = value;
    _scheduleSave();
    _safeNotify();
    unawaited(_restartEngine());
  }

  void setDiscoveryEnabled(bool value) {
    settings.discoveryEnabled = value;
    _scheduleSave();
    _safeNotify();
    unawaited(() async {
      if (value) {
        await _startDiscovery();
      } else {
        await _discovery?.stop();
        _discovery = null;
        _scanning = false;
        _safeNotify();
      }
    }());
  }

  void setReceiveEnabled(bool value) {
    settings.receiveEnabled = value;
    _scheduleSave();
    _safeNotify();
  }

  void setPinEnabled(bool value) {
    settings.pinEnabled = value;
    _scheduleSave();
    _safeNotify();
    unawaited(_restartEngine());
  }

  void setAutoAcceptFavorites(bool value) {
    settings.autoAcceptFavorites = value;
    _scheduleSave();
    _safeNotify();
  }

  void setWebShareEnabled(bool value) {
    settings.webShareEnabled = value;
    _scheduleSave();
    _safeNotify();
  }

  // Housekeeping ------------------------------------------------------------

  void _safeNotify() {
    if (!_disposed) {
      _syncBackgroundMode();
      notifyListeners();
    }
  }

  void _throttledNotify() {
    final now = DateTime.now();
    if (_lastNotify != null &&
        now.difference(_lastNotify!) < const Duration(milliseconds: 200)) {
      return;
    }
    _lastNotify = now;
    _safeNotify();
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _settingsSaveTimer?.cancel();
    _nameCollisionTimer?.cancel();
    unawaited(AppSettingsStore.save(settings));
    unawaited(BackgroundTransfer.stop());
    _pruneTimer?.cancel();
    _pendingRemoteCancels.clear();
    _transferStartTimes.clear();
    _discovery?.stop();
    _server?.stop();
    super.dispose();
  }

  String get version => AppInfo.version;
}
