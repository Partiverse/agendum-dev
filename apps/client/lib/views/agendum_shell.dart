import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'misc_views.dart';
import 'store.dart';
import 'task_row.dart';
import 'capture_bar.dart';
import 'today_view.dart';

/// 应用外壳:收件箱 / 今日 / 计划 / 随时 / 项目 / 回顾 / 日志 ——
/// Things 同构的信息架构(报告 §5.4),S06 扩为七视图骨架。
/// 宽屏 NavigationRail,窄屏 NavigationBar。
/// 键盘流 v1:⌘N 聚焦捕获条;任务行内 ⏎ 完成、⌫ 入收件箱。
class AgendumShell extends StatefulWidget {
  const AgendumShell({super.key, required this.store});

  final TaskStore store;

  @override
  State<AgendumShell> createState() => _AgendumShellState();
}

class _AgendumShellState extends State<AgendumShell> {
  // 0=收件箱 1=今日 2=计划 3=随时 4=项目 5=回顾 6=日志
  var _tab = 0;
  final _captureFocus = FocusNode();

  static const _titles = ['收件箱', '今日', '计划', '随时', '项目', '回顾', '日志'];
  static const _icons = [
    Icons.inbox_outlined,
    Icons.wb_sunny_outlined,
    Icons.event_outlined,
    Icons.all_inclusive,
    Icons.folder_outlined,
    Icons.rate_review_outlined,
    Icons.history_edu_outlined,
  ];
  static const _selectedIcons = [
    Icons.inbox,
    Icons.wb_sunny,
    Icons.event,
    Icons.all_inclusive,
    Icons.folder,
    Icons.rate_review,
    Icons.history_edu,
  ];

  @override
  void dispose() {
    _captureFocus.dispose();
    super.dispose();
  }

  void _newTask() {
    setState(() => _tab = 0);
    // IndexedStack 切页后收件箱子树才脱离 Offstage,焦点须在帧后再请求。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _captureFocus.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyN, meta: true): _newTask,
      },
      child: Focus(
        autofocus: true,
        child: AnimatedBuilder(
          animation: widget.store,
          builder: (context, _) {
            final inbox = widget.store.inboxTasks;
            return Scaffold(
              body: LayoutBuilder(
                builder: (context, c) {
                  final wide = c.maxWidth >= 720;
                  final body = IndexedStack(
                    index: _tab,
                    children: [
                      _InboxPane(
                        store: widget.store,
                        captureFocus: _captureFocus,
                      ),
                      TodayView(store: widget.store),
                      PlanView(store: widget.store),
                      AnytimeView(store: widget.store),
                      ProjectsView(store: widget.store),
                      ReviewView(store: widget.store),
                      LogView(store: widget.store),
                    ],
                  );
                  if (wide) {
                    return Row(
                      children: [
                        NavigationRail(
                          selectedIndex: _tab,
                          onDestinationSelected: (i) =>
                              setState(() => _tab = i),
                          labelType: NavigationRailLabelType.all,
                          leading: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Icon(
                              Icons.menu_book_outlined,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          destinations: [
                            for (var i = 0; i < _titles.length; i++)
                              NavigationRailDestination(
                                icon: i == 0
                                    ? _badge(
                                        _icons[i],
                                        inbox.length,
                                        selected: _tab == 0,
                                      )
                                    : Icon(
                                        i == _tab
                                            ? _selectedIcons[i]
                                            : _icons[i],
                                      ),
                                selectedIcon: i == 0
                                    ? _badge(
                                        _selectedIcons[i],
                                        inbox.length,
                                        selected: true,
                                      )
                                    : Icon(_selectedIcons[i]),
                                label: Text(_titles[i]),
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
                        for (var i = 0; i < _titles.length; i++)
                          NavigationDestination(
                            icon: i == 0
                                ? _badge(_icons[i], inbox.length)
                                : Icon(_icons[i]),
                            label: _titles[i],
                          ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
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
  const _InboxPane({required this.store, required this.captureFocus});

  final TaskStore store;
  final FocusNode captureFocus;

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
        CaptureBar(store: store, focusNode: captureFocus),
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
            child: ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              itemCount: tasks.length,
              onReorderItem: (oldIndex, newIndex) {
                // onReorderItem 的 newIndex 已按"移除后"修正,直接搬移即可。
                final next = [...tasks];
                final moved = next.removeAt(oldIndex);
                next.insert(newIndex, moved);
                store.reorderTasks([for (final t in next) t.id]);
              },
              itemBuilder: (context, i) {
                final t = tasks[i];
                return Column(
                  key: ValueKey('reorder-${t.id}'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ReorderableDelayedDragStartListener(
                      index: i,
                      child: TaskRow(task: t, store: store),
                    ),
                    if (i != tasks.length - 1) const Divider(indent: 52),
                  ],
                );
              },
            ),
          ),
      ],
    );
  }
}
