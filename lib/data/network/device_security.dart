import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:basic_utils/basic_utils.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Long-lived LocalSend-compatible identity (self-signed certificate + key).
class DeviceSecurity {
  const DeviceSecurity({
    required this.privateKey,
    required this.publicKey,
    required this.certificate,
    required this.certificateHash,
  });

  final String privateKey;
  final String publicKey;
  final String certificate;
  final String certificateHash;

  static DeviceSecurity generate({String commonName = 'LANBridge User'}) {
    final keyPair = CryptoUtils.generateRSAKeyPair();
    final privateKey = keyPair.privateKey as RSAPrivateKey;
    final publicKey = keyPair.publicKey as RSAPublicKey;
    final dn = {
      'CN': commonName,
      'O': '',
      'OU': '',
      'L': '',
      'S': '',
      'C': '',
    };
    final csr = X509Utils.generateRsaCsrPem(dn, privateKey, publicKey);
    final certificate =
        X509Utils.generateSelfSignedCertificate(keyPair.privateKey, csr, 3650);
    return DeviceSecurity(
      privateKey: CryptoUtils.encodeRSAPrivateKeyToPemPkcs1(privateKey),
      publicKey: CryptoUtils.encodeRSAPublicKeyToPemPkcs1(publicKey),
      certificate: certificate,
      certificateHash: hashOfPem(certificate),
    );
  }

  static String hashOfPem(String certificate) {
    final content = certificate
        .replaceAll('\r\n', '\n')
        .split('\n')
        .where((line) => line.isNotEmpty && !line.startsWith('---'))
        .join();
    return hashOfDer(base64Decode(content));
  }

  static String hashOfDer(Uint8List der) =>
      sha256.convert(der).toString().toUpperCase();

  SecurityContext buildSecurityContext() {
    return SecurityContext()
      ..useCertificateChainBytes(utf8.encode(certificate))
      ..usePrivateKeyBytes(utf8.encode(privateKey));
  }

  Map<String, dynamic> toJson() => {
        'privateKey': privateKey,
        'publicKey': publicKey,
        'certificate': certificate,
        'certificateHash': certificateHash,
      };

  factory DeviceSecurity.fromJson(Map<String, dynamic> json) => DeviceSecurity(
        privateKey: json['privateKey'] as String,
        publicKey: json['publicKey'] as String,
        certificate: json['certificate'] as String,
        certificateHash: json['certificateHash'] as String,
      );

  static Future<DeviceSecurity> loadOrCreate({Directory? directory}) async {
    Directory dir;
    if (directory != null) {
      dir = directory;
    } else {
      try {
        dir = await getApplicationSupportDirectory();
      } catch (_) {
        return generate();
      }
    }
    final file = File(p.join(dir.path, 'lanbridge_identity.json'));
    try {
      if (await file.exists()) {
        final decoded = jsonDecode(await file.readAsString());
        if (decoded is Map<String, dynamic>) {
          return DeviceSecurity.fromJson(decoded);
        }
      }
    } catch (_) {
      // Regenerate a broken identity below.
    }
    final security = generate();
    try {
      await file.parent.create(recursive: true);
      await file.writeAsString(jsonEncode(security.toJson()));
    } catch (_) {
      // In-memory identity is still usable for this session.
    }
    return security;
  }
}
