import 'package:agendum_domain/agendum_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils.dart';
import 'store.dart';
import 'task_detail.dart';

/// Things 风格任务行：圆形勾选 + 标题 + 元信息行（日期/时长/精力）。
/// 交互(S07)：点勾选完成/恢复;点行打开任务详情。
/// 键盘流 v1(S06)：行聚焦后 ⏎ 完成/恢复、⌫ 回收进收件箱。
class TaskRow extends StatefulWidget {
  const TaskRow({super.key, required this.task, required this.store});

  final TaskItem task;
  final TaskStore store;

  @override
  State<TaskRow> createState() => _TaskRowState();
}

class _TaskRowState extends State<TaskRow> {
  final _focus = FocusNode();

  TaskItem get task => widget.task;

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final meta = <String>[
      if (task.dueDay != null) formatDueDay(task.dueDay!),
      if (task.estimateMinutes != null) '${task.estimateMinutes} 分钟',
      if (task.energy == 'high') '🔥 高精力',
      if (task.energy == 'low') '🌙 低精力',
    ];
    return Focus(
      key: ValueKey('row-focus-${task.id}'),
      focusNode: _focus,
      onKeyEvent: _onKey,
      child: Builder(
        builder: (context) {
          final focused = Focus.of(context).hasFocus;
          return InkWell(
            onTap: () => showTaskDetail(context, widget.store, task.id),
            child: Container(
              decoration: BoxDecoration(
                color: focused
                    ? scheme.primary.withValues(alpha: .06)
                    : Colors.transparent,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    key: ValueKey('check-${task.id}'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () => widget.store.toggleDone(task.id),
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: _CircleCheckbox(done: task.isDone),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            decoration: task.isDone
                                ? TextDecoration.lineThrough
                                : null,
                            color: task.isDone
                                ? scheme.onSurface.withValues(alpha: .4)
                                : scheme.onSurface,
                          ),
                        ),
                        if (meta.isNotEmpty || task.tags.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                for (final m in meta) _MetaText(text: m),
                                if (meta.isNotEmpty && task.tags.isNotEmpty)
                                  _Dot(scheme: scheme),
                                for (final tag in task.tags) _TagChip(tag: tag),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter ||
        key == LogicalKeyboardKey.select) {
      widget.store.toggleDone(task.id);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.backspace ||
        key == LogicalKeyboardKey.delete) {
      widget.store.moveToInbox(task.id);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }
}

class _MetaText extends StatelessWidget {
  const _MetaText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      fontSize: 12,
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .55),
    ),
  );
}

class _Dot extends StatelessWidget {
  const _Dot({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) => Text(
    '·',
    style: TextStyle(
      fontSize: 12,
      color: scheme.onSurface.withValues(alpha: .35),
    ),
  );
}

/// 行内标签 chip:自由标签用中性色,互斥组标签用主色调(枚举维度可辨识)。
class _TagChip extends StatelessWidget {
  const _TagChip({required this.tag});

  final TagDescriptor tag;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final grouped = tag.groupId != null;
    final color = grouped ? scheme.primary : scheme.onSurface;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        tag.name,
        style: TextStyle(fontSize: 11, color: color.withValues(alpha: .85)),
      ),
    );
  }
}

class _CircleCheckbox extends StatelessWidget {
  const _CircleCheckbox({required this.done});

  final bool done;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done ? scheme.primary : Colors.transparent,
        border: Border.all(color: scheme.primary, width: 2),
      ),
      child: done
          ? const Icon(Icons.check, size: 14, color: Colors.white)
          : null,
    );
  }
}
