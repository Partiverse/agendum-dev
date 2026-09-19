import 'package:flutter/material.dart';

import 'store.dart';
import 'task_row.dart';

/// 七视图骨架(S06)的通用任务列表页:大标题 + 空状态 + 任务行卡片。
class TaskListPane extends StatelessWidget {
  const TaskListPane({
    super.key,
    required this.store,
    required this.title,
    required this.tasks,
    required this.emptyText,
    this.subtitle,
  });

  final TaskStore store;
  final String title;
  final List<TaskItem> tasks;
  final String emptyText;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        if (subtitle case final sub?)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              sub,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: .55),
              ),
            ),
          ),
        const SizedBox(height: 16),
        if (tasks.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 40,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 12),
                Text(emptyText),
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

/// 计划视图:带 planned/due 日期的活跃任务,按日期排序。
class PlanView extends StatelessWidget {
  const PlanView({super.key, required this.store});

  final TaskStore store;

  @override
  Widget build(BuildContext context) {
    return TaskListPane(
      store: store,
      title: '计划',
      tasks: store.planTasks,
      emptyText: '近期没有带日期的任务',
    );
  }
}

/// 随时视图:someday + 无日期的 next。
class AnytimeView extends StatelessWidget {
  const AnytimeView({super.key, required this.store});

  final TaskStore store;

  @override
  Widget build(BuildContext context) {
    return TaskListPane(
      store: store,
      title: '随时',
      tasks: store.anytimeTasks,
      emptyText: '随时可做的事都清空了',
    );
  }
}

/// 回顾视图:近 7 天完成(GTD 周回顾的素材面)。
class ReviewView extends StatelessWidget {
  const ReviewView({super.key, required this.store});

  final TaskStore store;

  @override
  Widget build(BuildContext context) {
    return TaskListPane(
      store: store,
      title: '回顾',
      subtitle: '近 7 天完成 ${store.reviewTasks.length} 件',
      tasks: store.reviewTasks,
      emptyText: '这周还没有完成记录',
    );
  }
}

/// 日志簿:全部已完成,按完成时间倒序。
class LogView extends StatelessWidget {
  const LogView({super.key, required this.store});

  final TaskStore store;

  @override
  Widget build(BuildContext context) {
    return TaskListPane(
      store: store,
      title: '日志簿',
      tasks: store.logTasks,
      emptyText: '日志簿还是空的',
    );
  }
}

/// 项目视图:内联新建 + 项目列表(未完成任务数)+ 展开看项目内任务。
class ProjectsView extends StatefulWidget {
  const ProjectsView({super.key, required this.store});

  final TaskStore store;

  @override
  State<ProjectsView> createState() => _ProjectsViewState();
}

class _ProjectsViewState extends State<ProjectsView> {
  final _newProject = TextEditingController();

  @override
  void dispose() {
    _newProject.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final projects = widget.store.projectList;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Text(
          '项目',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _newProject,
                onSubmitted: _create,
                decoration: const InputDecoration(
                  hintText: '新项目名称,回车创建',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            IconButton(
              tooltip: '创建项目',
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => _create(_newProject.text),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (projects.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(
                  Icons.folder_outlined,
                  size: 40,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 12),
                const Text('还没有项目。多步任务就该有个项目。'),
              ],
            ),
          )
        else
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (final p in projects) ...[
                  _ProjectTile(store: widget.store, project: p),
                  if (p != projects.last) const Divider(indent: 52),
                ],
              ],
            ),
          ),
      ],
    );
  }

  void _create(String name) {
    widget.store.addProject(name);
    _newProject.clear();
  }
}

class _ProjectTile extends StatelessWidget {
  const _ProjectTile({required this.store, required this.project});

  final TaskStore store;
  final ({String id, String name, int openCount, bool done}) project;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
      title: Text(
        project.name,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          decoration: project.done ? TextDecoration.lineThrough : null,
          color: project.done
              ? scheme.onSurface.withValues(alpha: .4)
              : scheme.onSurface,
        ),
      ),
      trailing: Text(
        '${project.openCount}',
        style: TextStyle(
          fontSize: 13,
          color: scheme.onSurface.withValues(alpha: .55),
        ),
      ),
      children: [
        FutureBuilder<List<TaskItem>>(
          future: store.tasksInProject(project.id),
          builder: (context, snap) {
            final tasks = snap.data ?? const <TaskItem>[];
            if (tasks.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Text('项目内还没有任务'),
              );
            }
            return Column(
              children: [
                for (final t in tasks) ...[
                  TaskRow(task: t, store: store),
                  if (t != tasks.last) const Divider(indent: 52),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}
