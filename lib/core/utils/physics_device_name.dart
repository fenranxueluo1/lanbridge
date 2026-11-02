import 'dart:math';

/// Generates friendly, LocalSend-style aliases from physics terms.
class PhysicsDeviceName {
  PhysicsDeviceName._();

  static final Random _random = Random();

  static const _prefixes = [
    '量子',
    '纠缠',
    '隧穿',
    '超导',
    '反物质',
    '冷却',
    '加速',
    '旋转',
    '偏振',
    '坍缩',
    '逃逸',
    '悬浮',
    '高温',
    '宇宙',
    '星际',
    '相对论',
    '电磁',
    '热力学',
    '引力',
    '暗',
  ];

  static const _suffixes = [
    '光子',
    '电子',
    '质子',
    '中子',
    '中微子',
    '夸克',
    '胶子',
    '玻色子',
    '费米子',
    '希格斯玻色子',
    '缪子',
    '引力子',
    '脉冲星',
    '黑洞',
    '白矮星',
    '中子星',
    '类星体',
    '星云',
    '奇点',
    '宇宙弦',
    '磁单极子',
    '波函数',
    '量子态',
    '事件视界',
    '超新星',
    '红巨星',
    '引力波',
    '暗物质',
    '暗能量',
    '物质',
    '能量',
    '射线',
  ];

  static String generate({Iterable<String> avoid = const []}) {
    final used = {for (final name in avoid) normalize(name)};
    for (var attempt = 0; attempt < 64; attempt++) {
      final prefix = _prefixes[_random.nextInt(_prefixes.length)];
      final suffix = _suffixes[_random.nextInt(_suffixes.length)];
      if (suffix.startsWith(prefix) || prefix.endsWith(suffix)) continue;
      final candidate = '$prefix$suffix';
      if (!used.contains(normalize(candidate))) return candidate;
    }

    final prefix = _prefixes[_random.nextInt(_prefixes.length)];
    final suffix = _suffixes[_random.nextInt(_suffixes.length)];
    final base = '$prefix$suffix';
    for (var index = 2; index < 1000; index++) {
      final candidate = '$base·$index';
      if (!used.contains(normalize(candidate))) return candidate;
    }
    return '$base·${DateTime.now().microsecondsSinceEpoch % 10000}';
  }

  static String normalize(String value) => value.trim().toLowerCase();
}
