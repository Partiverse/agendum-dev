/// Lamport 逻辑时钟（03 文档 §3）。
///
/// 同步裁决只看 lamport 与设备 ID，**永不使用墙钟**——客户端时钟回拨/快进
/// 不影响收敛（02 文档 §7.2 混沌场景 4）。
library;

class LamportClock {
  LamportClock({int value = 0}) : _value = value;

  int _value;

  int get value => _value;

  /// 本地写操作：递增并返回。
  int tick() => ++_value;

  /// 观察远端时钟：`local = max(local, remote) + 1`，返回推进后的值。
  int observe(int remote) {
    if (remote > _value) {
      _value = remote;
    }
    return ++_value;
  }
}
