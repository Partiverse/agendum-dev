import 'package:flutter/material.dart';

import '../utils.dart';
import 'store.dart';

/// Things 风格任务行：圆形勾选 + 标题 + 元信息行（日期/时长/精力）。
class TaskRow extends StatelessWidget {
  const TaskRow({super.key, required this.task, required this.store});

  final TaskItem task;
  final TaskStore store;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final meta = <String>[
      if (task.dueDay != null) formatDueDay(task.dueDay!),
      if (task.estimateMinutes != null) '${task.estimateMinutes} 分钟',
      if (task.energy == 'high') '🔥 高精力',
      if (task.energy == 'low') '🌙 低精力',
    ];
    return InkWell(
      onTap: () => store.toggleDone(task.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            _CircleCheckbox(done: task.isDone),
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
                  if (meta.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Row(
                        children: [
                          for (final m in meta) ...[
                            Text(
                              m,
                              style: TextStyle(
                                fontSize: 12,
                                color: scheme.onSurface.withValues(alpha: .55),
                              ),
                            ),
                            if (m != meta.last)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                ),
                                child: Text(
                                  '·',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: scheme.onSurface.withValues(
                                      alpha: .35,
                                    ),
                                  ),
                                ),
                              ),
                          ],
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
