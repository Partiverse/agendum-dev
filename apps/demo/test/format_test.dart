// 直接引入无 DOM 依赖的 format 模块（dart:js_interop 在 VM 测试环境不可用）。
import 'package:agendum_demo/src/format.dart';
import 'package:test/test.dart';

void main() {
  test('formatEpochDay 输出本地日历日与星期', () {
    final s = formatEpochDay(0); // 1970-01-01（周四）
    expect(s, startsWith('1970-01-01'));
    expect(s, endsWith('周四'));
  });

  test('formatHm 空安全与补零', () {
    expect(formatHm(null), '');
    final ms = DateTime(2026, 9, 23, 15, 0).millisecondsSinceEpoch;
    expect(formatHm(ms), '15:00');
    final ms2 = DateTime(2026, 9, 23, 9, 5).millisecondsSinceEpoch;
    expect(formatHm(ms2), '09:05');
  });

  test('epochDayFromInputValue 与 formatEpochDay 互逆', () {
    const v = '2026-09-23';
    final day = epochDayFromInputValue(v);
    expect(formatEpochDay(day), startsWith(v));
  });
}
