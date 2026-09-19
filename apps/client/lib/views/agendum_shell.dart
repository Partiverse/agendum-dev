import 'package:flutter/material.dart';

import 'store.dart';
import 'task_row.dart';
import 'capture_bar.dart';
import 'today_view.dart';

/// 应用外壳：收件箱 / 今日 —— Things 同构的信息架构（报告 §5.4）。
/// 宽屏 NavigationRail，窄屏 NavigationBar。
class AgendumShell extends StatefulWidget {
  const AgendumShell({super.key, required this.store});

  final TaskStore store;

  @override
  State<AgendumShell> createState() => _AgendumShellState();
}

class _AgendumShellState extends State<AgendumShell> {
  var _tab = 0; // 0 = 收件箱, 1 = 今日

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.store,
      builder: (context, _) {
        final inbox = widget.store.inboxTasks;
        return Scaffold(
          floatingActionButton: FloatingActionButton(
            tooltip: '新建（捕获条在收件箱顶部常驻）',
            onPressed: () => setState(() => _tab = 0),
            child: const Icon(Icons.add),
          ),
          body: LayoutBuilder(
            builder: (context, c) {
              final wide = c.maxWidth >= 720;
              final body = IndexedStack(
                index: _tab,
                children: [
                  _InboxPane(store: widget.store),
                  TodayView(store: widget.store),
                ],
              );
              if (wide) {
                return Row(
                  children: [
                    NavigationRail(
                      selectedIndex: _tab,
                      onDestinationSelected: (i) => setState(() => _tab = i),
                      labelType: NavigationRailLabelType.all,
                      leading: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Icon(
                          Icons.menu_book_outlined,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      destinations: [
                        NavigationRailDestination(
                          icon: _badge(
                            Icons.inbox_outlined,
                            inbox.length,
                            selected: _tab == 0,
                          ),
                          selectedIcon: _badge(
                            Icons.inbox,
                            inbox.length,
                            selected: true,
                          ),
                          label: const Text('收件箱'),
                        ),
                        const NavigationRailDestination(
                          icon: Icon(Icons.wb_sunny_outlined),
                          selectedIcon: Icon(Icons.wb_sunny),
                          label: Text('今日'),
                        ),
                      ],
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(child: body),
                  ],
                );
              }
              return Scaffold(
                body: body,
                bottomNavigationBar: NavigationBar(
                  selectedIndex: _tab,
                  onDestinationSelected: (i) => setState(() => _tab = i),
                  destinations: [
                    NavigationDestination(
                      icon: _badge(Icons.inbox_outlined, inbox.length),
                      label: '收件箱',
                    ),
                    const NavigationDestination(
                      icon: Icon(Icons.wb_sunny_outlined),
                      label: '今日',
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _badge(IconData icon, int count, {bool selected = false}) {
    if (count == 0) return Icon(icon);
    return Badge(
      label: Text('$count'),
      isLabelVisible: !selected,
      child: Icon(icon),
    );
  }
}

class _InboxPane extends StatelessWidget {
  const _InboxPane({required this.store});

  final TaskStore store;

  @override
  Widget build(BuildContext context) {
    final tasks = store.inboxTasks;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Text(
          '收件箱',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        CaptureBar(store: store),
        const SizedBox(height: 16),
        if (tasks.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 40,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 12),
                const Text('收件箱已清空 🎉'),
              ],
            ),
          )
        else
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
    );
  }
}
