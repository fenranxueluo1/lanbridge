import 'device.dart';

enum TransferDirection { send, receive }

enum TransferStatus {
  waiting,
  preparing,
  transferring,
  verifying,
  paused,
  completed,
  failed,
  cancelled,
}

enum TransferMode { standard, smart }

extension TransferStatusX on TransferStatus {
  bool get isRunning =>
      this == TransferStatus.transferring ||
      this == TransferStatus.preparing ||
      this == TransferStatus.waiting ||
      this == TransferStatus.verifying;

  bool get isActive => isRunning || this == TransferStatus.paused;

  bool get isFinished => !isActive;
}

class TransferFile {
  TransferFile({
    required this.name,
    required this.size,
    this.transferred = 0,
    this.isDirectory = false,
    this.path,
    this.remoteId,
  });

  final String name;
  final int size;
  int transferred;
  final bool isDirectory;
  final String? path;
  String? remoteId;

  bool get isComplete => transferred >= size;

  double get progress {
    if (size <= 0) return isComplete ? 1 : 0;
    return (transferred / size).clamp(0.0, 1.0);
  }

  TransferFile copyWith({int? transferred}) => TransferFile(
        name: name,
        size: size,
        transferred: transferred ?? this.transferred,
        isDirectory: isDirectory,
        path: path,
        remoteId: remoteId,
      );
}

class TransferJob {
  TransferJob({
    required this.id,
    required this.peerId,
    required this.peerName,
    required this.peerKind,
    required this.direction,
    required this.files,
    required this.mode,
    this.status = TransferStatus.transferring,
    DateTime? startedAt,
    this.speed = 0,
    this.savedBytes = 0,
    this.error,
    this.requiredPin,
    this.isResumed = false,
    this.peerIp,
  }) : startedAt = startedAt ?? DateTime.now();

  final String id;
  final String peerId;
  final String peerName;
  final DeviceKind peerKind;
  final TransferDirection direction;
  final List<TransferFile> files;
  final TransferMode mode;
  final DateTime startedAt;
  final String? requiredPin;
  final bool isResumed;
  final String? peerIp;

  TransferStatus status;
  double speed;
  int savedBytes;
  String? error;
  List<String> savedFiles = [];

  int get totalBytes => files.fold(0, (sum, file) => sum + file.size);

  int get transferredBytes =>
      files.fold(0, (sum, file) => sum + file.transferred.clamp(0, file.size));

  int get remainingBytes => (totalBytes - transferredBytes).clamp(0, totalBytes);

  double get progress {
    if (totalBytes <= 0) {
      return status == TransferStatus.completed ? 1 : 0;
    }
    return (transferredBytes / totalBytes).clamp(0.0, 1.0);
  }

  Duration? get eta {
    if (speed <= 0 || remainingBytes <= 0) return null;
    return Duration(seconds: (remainingBytes / speed).ceil());
  }

  bool get isSmart => mode == TransferMode.smart;

  String get displayName => switch (direction) {
        TransferDirection.send => peerName,
        TransferDirection.receive => peerName,
      };

  void markCompleted() {
    for (final file in files) {
      file.transferred = file.size;
    }
    status = TransferStatus.completed;
    speed = 0;
  }

  void markFailed(String message) {
    status = TransferStatus.failed;
    error = message;
    speed = 0;
  }

  void resetProgress() {
    for (final file in files) {
      file.transferred = 0;
    }
    status = TransferStatus.transferring;
    speed = 0;
    error = null;
  }
}
