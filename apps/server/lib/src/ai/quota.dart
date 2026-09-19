/// AI 额度账本（04 文档 §5.2/§8）。
///
/// 额度按"设备/用户 × 自然月"记账；BYOK 请求在路由层绕过额度
/// （04 文档 §8：BYOK 不因额度受限），生产实现将持久化到 Postgres。
library;

/// 数据分级（04 文档 §1 最小化取数）：L1 默认可发云端，L2/L3 需 BYOK 或本地模型。
enum DataLevel {
  l1('L1'),
  l2('L2'),
  l3('L3');

  const DataLevel(this.value);

  final String value;

  static DataLevel fromValue(String v) => DataLevel.values.firstWhere(
    (l) => l.value == v,
    orElse: () => throw ArgumentError.value(v, 'level', '须为 L1/L2/L3'),
  );
}

class QuotaState {
  const QuotaState({required this.used, required this.limit});

  final int used;
  final int limit;

  int get remaining => (limit - used).clamp(0, limit);
  bool get exhausted => used >= limit;

  Map<String, Object?> toJson() => {
    'used': used,
    'limit': limit,
    'remaining': remaining,
  };
}

abstract interface class QuotaLedger {
  QuotaState usage(String subject);

  /// 记一次消耗；返回消耗后的状态。
  QuotaState consume(String subject);
}

final class MemoryQuotaLedger implements QuotaLedger {
  MemoryQuotaLedger({required this.monthlyLimit, DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final int monthlyLimit;
  final DateTime Function() _now;
  final Map<String, int> _usage = {};

  static String _key(String subject, DateTime at) =>
      '$subject@${at.year}-${at.month}';

  @override
  QuotaState usage(String subject) =>
      QuotaState(used: _usage[_key(subject, _now())] ?? 0, limit: monthlyLimit);

  @override
  QuotaState consume(String subject) {
    final k = _key(subject, _now());
    _usage[k] = (_usage[k] ?? 0) + 1;
    return QuotaState(used: _usage[k]!, limit: monthlyLimit);
  }
}
