import 'package:agendum_domain/agendum_domain.dart';
import 'package:test/test.dart';

void main() {
  group('TaskStatus', () {
    test('value 与数据库枚举一致（03 文档 DDL）', () {
      expect(TaskStatus.values.map((s) => s.value), [
        'inbox',
        'next',
        'waiting',
        'someday',
        'done',
        'trashed',
      ]);
    });

    test('fromValue 双向可逆', () {
      for (final s in TaskStatus.values) {
        expect(TaskStatus.fromValue(s.value), s);
      }
      expect(() => TaskStatus.fromValue('archived'), throwsArgumentError);
    });

    test('终态与可执行标记', () {
      expect(TaskStatus.done.isTerminal, isTrue);
      expect(TaskStatus.trashed.isTerminal, isTrue);
      expect(TaskStatus.waiting.isTerminal, isFalse);
      expect(TaskStatus.inbox.isActionable, isTrue);
      expect(TaskStatus.next.isActionable, isTrue);
      expect(TaskStatus.waiting.isActionable, isFalse);
    });
  });

  group('状态机', () {
    test('常用正向流转', () {
      expect(transition(TaskStatus.inbox, TaskStatus.next), TaskStatus.next);
      expect(transition(TaskStatus.next, TaskStatus.done), TaskStatus.done);
      expect(
        transition(TaskStatus.next, TaskStatus.waiting),
        TaskStatus.waiting,
      );
      expect(
        transition(TaskStatus.inbox, TaskStatus.someday),
        TaskStatus.someday,
      );
    });

    test('回退路径：重新打开与废纸篓恢复', () {
      expect(transition(TaskStatus.done, TaskStatus.next), TaskStatus.next);
      expect(
        transition(TaskStatus.trashed, TaskStatus.inbox),
        TaskStatus.inbox,
      );
      // waiting → inbox 不允许（须先回 next，保持 GTD 澄清纪律）。
      expect(
        () => transition(TaskStatus.waiting, TaskStatus.inbox),
        throwsA(isA<IllegalTransitionError>()),
      );
      expect(
        () => transition(TaskStatus.trashed, TaskStatus.next),
        throwsA(isA<IllegalTransitionError>()),
      );
    });

    test('同状态流转幂等', () {
      expect(canTransition(TaskStatus.next, TaskStatus.next), isTrue);
    });

    test('非法流转抛出并携带两端状态', () {
      try {
        transition(TaskStatus.trashed, TaskStatus.someday);
        fail('应抛出');
      } on IllegalTransitionError catch (e) {
        expect(e.toString(), contains('trashed'));
        expect(e.toString(), contains('someday'));
      }
    });
  });
}
