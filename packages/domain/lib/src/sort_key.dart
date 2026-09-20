/// 手动排序键：分数索引（fractional indexing，ADR-014）。
///
/// 拖拽排序只改单字段 `sort_key`，天然兼容字段级 LWW 同步（03 文档 §5）。
/// 字典序基于 base62 字符码单调（数字 < 大写 < 小写），与 [base62Chars] 索引一致。
/// 键长超过 32 位时应触发重排压缩（重排策略在 S07 拖拽排序落地时一并实现）。
library;

const String base62Chars =
    '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';

const int maxSortKeyLength = 32;

int _indexOf(String c) {
  final i = base62Chars.indexOf(c);
  if (i < 0) throw ArgumentError.value(c, 'char', '非 base62 字符');
  return i;
}

/// 列表首项的初始键。
String firstSortKey() => 'V';

/// 返回严格介于 before 与 after 之间的键（字典序）。
/// before/after 传 null 表示该端无界；两者皆 null 返回 [firstSortKey]。
/// 要求：before < after（若均非 null），否则抛 ArgumentError。
String midpointSortKey(String? before, String? after) {
  if (before == null && after == null) return firstSortKey();
  if (before != null && after != null && before.compareTo(after) >= 0) {
    throw ArgumentError('要求 before < after：$before !< $after');
  }
  final a = before ?? '';
  final b = after ?? '';
  final sb = StringBuffer();
  var i = 0;
  while (true) {
    final va = i < a.length ? _indexOf(a[i]) : -1; // a 侧耗尽 = 负无穷位
    final vb = i < b.length ? _indexOf(b[i]) : 62; // b 侧耗尽 = 正无穷位
    if (va == -1 && vb == 62) {
      // a、b 在此深度完全同串：在尾部续中间位即可严格区分。
      sb.write(base62Chars[31]);
      return sb.toString();
    }
    if (va == -1 && vb == 0) {
      // 只能落在 b 当前位上再深入：取 '0' 使键成为 b 的真前缀 → 严格小于 b。
      sb.write(base62Chars[0]);
      return sb.toString();
    }
    if (vb - va >= 2) {
      sb.write(base62Chars[(va + vb) ~/ 2]);
      return sb.toString();
    }
    // va == vb 或相邻：复制 a 的位后向更深一层推进。
    if (va >= 0) sb.write(base62Chars[va]);
    i++;
    if (sb.length > maxSortKeyLength) {
      throw StateError('sort_key 超长（>$maxSortKeyLength），应触发重排压缩');
    }
  }
}

/// 追加到列表末尾：以无界右端取中点。
String appendSortKey(String? last) => midpointSortKey(last, null);

/// 追加到列表开头。
String prependSortKey(String? first) => midpointSortKey(null, first);

/// 全量均匀重排的 n 个新键（重排压缩，S07 拖拽排序配套）。
///
/// 键超长时对整个列表一次性重写：固定宽度 base62 等距分布，
/// 键 i = ⌊(62^w−1)·(i+1)/(n+1)⌋ 的定宽编码，字典序 = 序。
/// 宽度 w 取使 62^w > n+1 的最小值（保证首尾项与两端留有间隙）。
List<String> rebalancedSortKeys(int count) {
  if (count < 0) throw ArgumentError.value(count, 'count', '须 ≥ 0');
  if (count == 0) return const [];
  var space = 1;
  var w = 0;
  while (space <= count + 1) {
    space *= base62Chars.length;
    w++;
  }
  final gap = (space - 1) ~/ (count + 1);
  return [for (var i = 1; i <= count; i++) _encodeFixedWidth(i * gap, w)];
}

String _encodeFixedWidth(int v, int width) {
  final chars = List.filled(width, base62Chars[0]);
  for (var i = width - 1; i >= 0 && v > 0; i--) {
    chars[i] = base62Chars[v % base62Chars.length];
    v ~/= base62Chars.length;
  }
  return chars.join();
}
