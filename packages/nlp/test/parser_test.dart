import 'package:agendum_domain/agendum_domain.dart';
import 'package:agendum_nlp/agendum_nlp.dart';
import 'package:test/test.dart';

// 固定时基：2026-09-19（周六）09:00 与 2026-09-16（周三）09:00。
final sat = DateTime(2026, 9, 19, 9, 0);
final wed = DateTime(2026, 9, 16, 9, 0);

int d(int y, int m, int day) => epochDayOf(DateTime(y, m, day));
int ms(int y, int m, int day, int h, int min) =>
    DateTime(y, m, day, h, min).millisecondsSinceEpoch;

void main() {
  final parser = CaptureParser(now: () => sat);
  final parserWed = CaptureParser(now: () => wed);

  group('报告 §5.3 示例与核心字段', () {
    test('智能捕获验收样例：日期+时刻+时长+精力', () {
      final r = parser.parse('下周三下午3点前给司机发合同 30min !高精力');
      expect(r.dueDay, d(2026, 9, 23), reason: '下周三 = 2026-09-23');
      expect(r.dueAtMs, ms(2026, 9, 23, 15, 0));
      expect(r.reminderAtMs, r.dueAtMs);
      expect(r.estimateMinutes, 30);
      expect(r.energy, 'high');
      expect(r.isDeadline, isTrue);
      expect(r.title, '给司机发合同');
      expect(r.ambiguities, isEmpty);
      expect(r.confidence, greaterThan(0.8));
    });

    test('日期+时刻', () {
      final r = parser.parse('明天上午10点开团队会');
      expect(r.dueDay, d(2026, 9, 20));
      expect(r.dueAtMs, ms(2026, 9, 20, 10, 0));
      expect(r.title, '开团队会');
    });

    test('纯文本：零识别、标题完整、低置信度', () {
      final r = parser.parse('买牛奶');
      expect(r.title, '买牛奶');
      expect(r.hasDue, isFalse);
      expect(r.confidence, lessThan(0.5));
      expect(r.ambiguities, isEmpty);
    });

    test('时长与标签', () {
      final r = parser.parse('#采购 打印纸 2小时');
      expect(r.tags, ['采购']);
      expect(r.estimateMinutes, 120);
      expect(r.title, contains('打印纸'));
    });

    test('项目路由', () {
      final r = parser.parse('@程簿 写周报');
      expect(r.projectHint, '程簿');
      expect(r.title, '写周报');
    });
  });

  group('中文日期短语', () {
    test('后天', () {
      expect(parser.parse('后天交房租').dueDay, d(2026, 9, 21));
    });
    test('今晚（相对日 0）', () {
      expect(parser.parse('今晚写周报').dueDay, d(2026, 9, 19));
    });
    test('裸周几：从今天起向后找（含今天）', () {
      expect(parserWed.parse('周三 跑步').dueDay, d(2026, 9, 16));
      expect(parserWed.parse('周五 拜访客户').dueDay, d(2026, 9, 18));
      // 周六在周三视角 = 3 天后
      expect(parserWed.parse('周六 搬家').dueDay, d(2026, 9, 19));
    });
    test('下周X 与 下下周X（周一锚）', () {
      expect(parser.parse('下周一晨会').dueDay, d(2026, 9, 21));
      expect(parser.parse('下下周五 提交季度报告').dueDay, d(2026, 10, 2));
    });
    test('X月X日', () {
      expect(parser.parse('9月25日交保险').dueDay, d(2026, 9, 25));
      expect(parser.parse('10月1日放假安排').dueDay, d(2026, 10, 1));
    });
    test('过去日期滚动到明年并记歧义', () {
      final r = parser.parse('8月1日团建');
      expect(r.dueDay, d(2027, 8, 1));
      expect(r.ambiguities, isNotEmpty);
    });
    test('N天后', () {
      expect(parser.parse('3天后回访客户').dueDay, d(2026, 9, 22));
    });
    test('下个月X号', () {
      expect(parser.parse('下个月5号交物业费').dueDay, d(2026, 10, 5));
    });
    test('多日期取首个并记歧义', () {
      final r = parser.parse('周五或周六看电影');
      expect(r.dueDay, d(2026, 9, 25));
      expect(r.ambiguities.length, 1);
      expect(r.title, contains('看电影'));
      expect(r.confidence, lessThan(0.85), reason: '歧义扣减');
    });
  });

  group('时刻语义', () {
    test('下午与半小时', () {
      final r = parser.parse('下午4点半取快递');
      expect(r.dueDay, isNull);
      expect(r.dueAtMs, isNull);
      expect(r.reminderAtMs, ms(2026, 9, 19, 16, 30));
      expect(r.ambiguities, isNotEmpty, reason: '孤立时刻按今日提醒');
      expect(r.title, '取快递');
    });
    test('凌晨与晚上', () {
      expect(parser.parse('凌晨1点写周报').reminderAtMs, ms(2026, 9, 19, 1, 0));
      expect(parser.parse('晚上9点健身').reminderAtMs, ms(2026, 9, 19, 21, 0));
    });
    test('24 小时制（冒号）', () {
      final r = parser.parse('12:30 午休');
      expect(r.reminderAtMs, ms(2026, 9, 19, 12, 30));
    });
  });

  group('英文表达', () {
    test('tomorrow + pm', () {
      final r = parser.parse('tomorrow 2pm standup');
      expect(r.dueDay, d(2026, 9, 20));
      expect(r.dueAtMs, ms(2026, 9, 20, 14, 0));
      expect(r.title, 'standup');
    });
    test('next monday + 时长', () {
      final r = parser.parse('next monday sync with team 1h');
      expect(r.dueDay, d(2026, 9, 21));
      expect(r.estimateMinutes, 60);
    });
    test('普通英文单词不误判为星期', () {
      final r = parser.parse('watch the sunset today');
      expect(r.dueDay, d(2026, 9, 19));
      expect(r.title, 'watch the sunset');
    });
  });

  group('时长表达', () {
    test('分钟/小时/半小时/小数小时', () {
      expect(parser.parse('45分钟 整理发票').estimateMinutes, 45);
      expect(parser.parse('1.5小时 深度工作').estimateMinutes, 90);
      expect(parser.parse('半小时 邮件批处理').estimateMinutes, 30);
    });
    test('英文精力', () {
      final r = parser.parse('review PR 30min !low');
      expect(r.energy, 'low');
      expect(r.estimateMinutes, 30);
      expect(r.title, 'review PR');
    });
  });
}
