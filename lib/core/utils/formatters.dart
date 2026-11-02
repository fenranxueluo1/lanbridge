import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

class Formatters {
  const Formatters._();

  static const _units = ['B', 'KB', 'MB', 'GB', 'TB', 'PB'];

  static String bytes(int bytes, {int? decimals}) {
    if (bytes <= 0) return '0 B';
    var value = bytes.toDouble();
    var unit = 0;
    while (value >= 1024 && unit < _units.length - 1) {
      value /= 1024;
      unit++;
    }
    final digits = decimals ?? (unit == 0 ? 0 : (value >= 100 ? 1 : 2));
    final text = value.toStringAsFixed(digits);
    return '$text ${_units[unit]}';
  }

  static String speed(double bytesPerSecond) {
    if (bytesPerSecond <= 0) return '—';
    return '${bytes(bytesPerSecond.round())}/s';
  }

  static String duration(Duration? duration, AppLocalizations l10n) {
    if (duration == null || duration.inSeconds <= 0) return '—';
    final seconds = duration.inSeconds;
    if (seconds < 60) return l10n.etaSeconds(seconds);
    final minutes = seconds ~/ 60;
    if (minutes < 60) {
      final rest = seconds % 60;
      return rest == 0
          ? l10n.etaMinutes(minutes)
          : l10n.etaMinutesSeconds(minutes, rest);
    }
    final hours = minutes ~/ 60;
    final restMinutes = minutes % 60;
    return l10n.etaHours(hours, restMinutes);
  }

  static String clock(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  static String relative(DateTime time, AppLocalizations l10n) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return l10n.justNow;
    if (diff.inMinutes < 60) return l10n.minutesAgo(diff.inMinutes);
    if (now.year == time.year &&
        now.month == time.month &&
        now.day == time.day) {
      return l10n.todayAt(clock(time));
    }
    if (now.subtract(const Duration(days: 1)).day == time.day &&
        now.month == time.month &&
        now.year == time.year) {
      return l10n.yesterdayAt(clock(time));
    }
    return l10n.dateAt(time.month, time.day, clock(time));
  }

  static String shortenPath(String path, {int max = 42}) {
    if (path.length <= max) return path;
    return '…${path.substring(path.length - max + 1)}';
  }

  static String fingerprint(String value) {
    final cleaned = value.replaceAll(':', '').toUpperCase();
    if (cleaned.length <= 16) return cleaned;
    return '${cleaned.substring(0, 8)} ${cleaned.substring(cleaned.length - 8)}';
  }

  static String initials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed.substring(0, 1).toUpperCase();
  }

  static IconData iconForFile(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.heic') ||
        lower.endsWith('.webp')) {
      return Icons.image_rounded;
    }
    if (lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.mkv') ||
        lower.endsWith('.avi')) {
      return Icons.movie_rounded;
    }
    if (lower.endsWith('.pdf')) return Icons.picture_as_pdf_rounded;
    if (lower.endsWith('.zip') || lower.endsWith('.7z')) {
      return Icons.folder_zip_rounded;
    }
    if (lower.endsWith('.txt') || lower.endsWith('.md')) {
      return Icons.description_rounded;
    }
    return Icons.insert_drive_file_rounded;
  }
}
