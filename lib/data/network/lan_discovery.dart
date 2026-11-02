import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

import 'lan_client.dart';
import 'lan_protocol.dart';

/// UDP multicast discovery compatible with LocalSend v2.
class LanDiscovery {
  LanDiscovery({
    required this.self,
    required this.client,
    required this.onPeer,
    this.onScanningChanged,
  });

  final LanDeviceInfo self;
  final LanClient client;
  final LanPeerHandler onPeer;
  final void Function(bool scanning)? onScanningChanged;

  final List<RawDatagramSocket> _listeners = [];
  final List<NetworkInterface> _interfaces = [];
  Timer? _announceTimer;
  bool _running = false;
  bool _announcing = false;
  bool _scanningSubnet = false;
  DateTime? _lastSubnetScan;
  bool _multicastLock = false;
  static const _channel = MethodChannel('lanbridge/network');
  static const discoveryPort = 53317;

  Future<void> start() async {
    if (_running) return;
    _running = true;
    await _acquireMulticastLock();

    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
      );
      _interfaces
        ..clear()
        ..addAll(interfaces.where((i) => i.addresses.isNotEmpty));
    } catch (_) {
      _interfaces.clear();
    }

    for (final interface in _interfaces) {
      try {
        final socket = await RawDatagramSocket.bind(
          InternetAddress.anyIPv4,
          discoveryPort,
          reuseAddress: true,
        );
        socket.multicastLoopback = true;
        socket.broadcastEnabled = true;
        try {
          socket.joinMulticast(InternetAddress(lanMulticastGroup), interface);
        } catch (_) {}
        socket.listen(
          (event) {
            if (event == RawSocketEvent.read) {
              final datagram = socket.receive();
              if (datagram != null) _handleDatagram(datagram);
            }
          },
          onError: (_) {},
        );
        _listeners.add(socket);
      } catch (_) {
        // Some interfaces / Windows configurations reject SO_REUSEADDR.
      }
    }

    unawaited(announce());
    _announceTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => unawaited(announce()),
    );
  }

  Future<void> stop() async {
    _running = false;
    _scanningSubnet = false;
    _announceTimer?.cancel();
    _announceTimer = null;
    client.cancelScan();
    for (final socket in _listeners) {
      socket.close();
    }
    _listeners.clear();
    onScanningChanged?.call(false);
    await _releaseMulticastLock();
  }

  Future<void> announce() async {
    if (!_running || _announcing) return;
    _announcing = true;
    onScanningChanged?.call(true);
    try {
      final payload = utf8.encode(jsonEncode(self.toMulticastJson()));
      final targets = <InternetAddress>{
        InternetAddress(lanMulticastGroup),
        InternetAddress('255.255.255.255'),
      };
      for (final interface in _interfaces) {
        if (_isCellular(interface.name)) continue;
        for (final address in interface.addresses) {
          final broadcast = _subnetBroadcast(address.address);
          if (broadcast != null) targets.add(InternetAddress(broadcast));
        }
      }

      List<RawDatagramSocket> sockets = List.of(_listeners);
      final created = <RawDatagramSocket>[];
      if (sockets.isEmpty) {
        try {
          final socket = await RawDatagramSocket.bind(
            InternetAddress.anyIPv4,
            0,
          );
          socket.broadcastEnabled = true;
          socket.multicastLoopback = true;
          sockets = [socket];
          created.add(socket);
        } catch (_) {
          return;
        }
      }

      for (var attempt = 0; attempt < 3; attempt++) {
        if (attempt > 0) {
          await Future<void>.delayed(
            Duration(milliseconds: attempt == 1 ? 400 : 1500),
          );
        }
        for (final socket in sockets) {
          for (final target in targets) {
            try {
              socket.send(payload, target, discoveryPort);
            } catch (_) {}
          }
        }
      }
      for (final socket in created) {
        socket.close();
      }
    } finally {
      _announcing = false;
      onScanningChanged?.call(false);
    }
  }

  void _handleDatagram(Datagram datagram) {
    try {
      final decoded = jsonDecode(utf8.decode(datagram.data));
      if (decoded is! Map<String, dynamic>) return;
      final fingerprint = decoded['fingerprint'];
      if (fingerprint == self.fingerprint) return;

      final peer = LanPeer.fromMap(
        decoded,
        ip: _normalizeIp(datagram.address),
        fallbackPort: discoveryPort,
        fallbackHttps: self.https,
      );
      onPeer(peer);

      final isAnnouncement =
          decoded['announcement'] == true || decoded['announce'] == true;
      if (isAnnouncement) {
        unawaited(_answer(peer));
      }
    } catch (_) {
      // Ignore malformed datagrams.
    }
  }

  /// Scans the local /24 subnets for LocalSend servers. This is the reliable
  /// fallback when multicast is blocked or a peer restarted.
  Future<void> scanSubnet({bool force = false}) async {
    if (_scanningSubnet) return;
    if (!_running) return;
    final now = DateTime.now();
    if (!force &&
        _lastSubnetScan != null &&
        now.difference(_lastSubnetScan!) < const Duration(seconds: 25)) {
      return;
    }
    _scanningSubnet = true;
    _lastSubnetScan = now;
    onScanningChanged?.call(true);
    try {
      final hosts = await _localSubnetHosts();
      if (hosts.isEmpty) return;
      var found = await _probeSubnet(
        hosts: hosts,
        ports: const [discoveryPort],
        https: self.https,
      );
      if (!found) {
        found = await _probeSubnet(
          hosts: hosts,
          ports: const [53318, 53319, 53320],
          https: self.https,
        );
      }
      if (!found) {
        await _probeSubnet(
          hosts: hosts,
          ports: const [53317, 53318, 53319, 53320],
          https: !self.https,
        );
      }
    } finally {
      _scanningSubnet = false;
      onScanningChanged?.call(false);
    }
  }

  Future<Set<String>> _localSubnetHosts() async {
    var interfaces = _interfaces;
    if (interfaces.isEmpty) {
      try {
        interfaces = await NetworkInterface.list(
          type: InternetAddressType.IPv4,
        );
      } catch (_) {
        return {};
      }
    }
    final hosts = <String>{};
    for (final interface in interfaces) {
      if (_isCellular(interface.name)) continue;
      for (final address in interface.addresses) {
        if (address.isLoopback) continue;
        final parts = address.address.split('.');
        if (parts.length != 4) continue;
        final prefix = '${parts[0]}.${parts[1]}.${parts[2]}';
        for (var host = 1; host < 255; host++) {
          final ip = '$prefix.$host';
          if (ip != address.address) hosts.add(ip);
        }
      }
    }
    return hosts;
  }

  Future<bool> _probeSubnet({
    required Set<String> hosts,
    required List<int> ports,
    required bool https,
  }) async {
    final targets = <LanPeer>[
      for (final ip in hosts)
        for (final port in ports)
          LanPeer(
            ip: ip,
            alias: '',
            deviceModel: '',
            deviceType: 'desktop',
            fingerprint: '',
            port: port,
            https: https,
            version: lanProtocolVersion,
          ),
    ];
    if (targets.isEmpty) return false;

    var found = false;
    var index = 0;
    final seen = <String>{};
    Future<void> worker() async {
      while (index < targets.length) {
        if (!_running) return;
        final target = targets[index++];
        final peer = await client.probe(target);
        if (peer == null) continue;
        final key = peer.fingerprint.isNotEmpty ? peer.fingerprint : peer.ip;
        if (!seen.add(key)) continue;
        found = true;
        onPeer(peer);
        try {
          final registered = await client.register(peer);
          if (registered != null) onPeer(registered);
        } catch (_) {}
      }
    }

    await Future.wait(List.generate(96, (_) => worker()));
    return found;
  }

  Future<void> _answer(LanPeer peer) async {
    try {
      final updated = await client.register(peer);
      if (updated != null) onPeer(updated);
    } catch (_) {
      // The peer may be in a different protocol mode; discovery will retry.
    }
  }

  String _normalizeIp(InternetAddress address) {
    final ip = address.address;
    return ip == '::1' ? '127.0.0.1' : ip;
  }

  static bool _isCellular(String name) {
    final lower = name.toLowerCase();
    return lower.contains('rmnet') ||
        lower.contains('cellular') ||
        lower.contains('wwan') ||
        lower.contains('pdp') ||
        lower.contains('clat');
  }

  static String? _subnetBroadcast(String ip) {
    final parts = ip.split('.');
    if (parts.length != 4) return null;
    if (parts[0] == '127' || parts[0] == '0') return null;
    return '${parts[0]}.${parts[1]}.${parts[2]}.255';
  }

  Future<void> _acquireMulticastLock() async {
    if (_multicastLock) return;
    try {
      await _channel.invokeMethod<void>('acquireMulticastLock');
      _multicastLock = true;
    } on MissingPluginException {
      // Not Android.
    } catch (_) {}
  }

  Future<void> _releaseMulticastLock() async {
    if (!_multicastLock) return;
    _multicastLock = false;
    try {
      await _channel.invokeMethod<void>('releaseMulticastLock');
    } catch (_) {}
  }
}
