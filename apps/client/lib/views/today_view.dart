import 'package:flutter/material.dart';

import '../utils.dart';
import 'store.dart';
import 'task_row.dart';

/// 今日视图：顶部一句"现在，做这件事"（报告 §5.4 关键界面）+ 分段列表。
class TodayView extends StatelessWidget {
  const TodayView({super.key, required this.store});

  final TaskStore store;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tasks = store.todayTasks;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Text(
          '今天',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          _todayLabel(),
          style: TextStyle(
            color: scheme.onSurface.withValues(alpha: .55),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 16),
        if (tasks.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.wb_sunny_outlined,
                    size: 40,
                    color: scheme.primary,
                  ),
                  const SizedBox(height: 12),
                  const Text('今天没有安排，去收件箱澄清一件事吧'),
                ],
              ),
            ),
          )
        else ...[
          _NowFocusCard(task: tasks.first),
          const SizedBox(height: 20),
          Text(
            '接下来',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: scheme.onSurface.withValues(alpha: .7),
            ),
          ),
          const SizedBox(height: 4),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (final t in tasks) ...[
                  TaskRow(task: t, store: store),
                  if (t != tasks.last) const Divider(indent: 52),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  static String _todayLabel() {
    final now = DateTime.now();
    const wd = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return '${now.month} 月 ${now.day} 日 · ${wd[now.weekday - 1]}';
  }
}

class _NowFocusCard extends StatelessWidget {
  const _NowFocusCard({required this.task});

  final TaskItem task;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.primary.withValues(alpha: .08),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.play_arrow_rounded, color: scheme.primary),
                const SizedBox(width: 6),
                Text(
                  '现在，做这件事',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                    color: scheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              task.title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            if (task.dueDay != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '截止 ${formatDueDay(task.dueDay!)}',
                  style: TextStyle(
                    fontSize: 13,
                    color: scheme.onSurface.withValues(alpha: .6),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
