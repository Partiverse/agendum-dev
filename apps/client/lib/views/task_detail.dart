import 'package:flutter/material.dart';

import 'package:agendum_domain/agendum_domain.dart';

import '../utils.dart';
import 'store.dart';

/// 任务详情(S07 UI 行):点任务行打开,即改即存。
/// 字段:标题/备注、截止与计划日期、精力、挂项目、状态 chips。
/// 所有编辑走 store.editTask/setTaskStatus —— 唯一写路径(oplog)。
Future<void> showTaskDetail(
  BuildContext context,
  TaskStore store,
  String taskId,
) => showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
    child: TaskDetailSheet(store: store, taskId: taskId),
  ),
);

class TaskDetailSheet extends StatelessWidget {
  const TaskDetailSheet({super.key, required this.store, required this.taskId});

  final TaskStore store;
  final String taskId;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final task = store.byId(taskId);
        return SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _TitleField(task: task, store: store),
                  _NoteField(task: task, store: store),
                  const SizedBox(height: 8),
                  _DateRow(
                    icon: Icons.event_outlined,
                    label: '截止',
                    value: task.dueDay,
                    onPick: (day) => store.editTask(task.id, {'due_date': day}),
                    onClear: () => store.editTask(task.id, {'due_date': null}),
                  ),
                  _DateRow(
                    icon: Icons.calendar_today_outlined,
                    label: '计划做',
                    value: task.plannedDay,
                    onPick: (day) =>
                        store.editTask(task.id, {'planned_date': day}),
                    onClear: () =>
                        store.editTask(task.id, {'planned_date': null}),
                  ),
                  const SizedBox(height: 8),
                  _EnergyRow(task: task, store: store),
                  _ProjectRow(task: task, store: store),
                  const Divider(height: 24),
                  _TagSection(task: task, store: store),
                  const Divider(height: 24),
                  _StatusChips(task: task, store: store),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TitleField extends StatefulWidget {
  const _TitleField({required this.task, required this.store});

  final TaskItem task;
  final TaskStore store;

  @override
  State<_TitleField> createState() => _TitleFieldState();
}

class _TitleFieldState extends State<_TitleField> {
  late final _controller = TextEditingController(text: widget.task.title);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      textInputAction: TextInputAction.done,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      decoration: const InputDecoration(
        hintText: '标题',
        border: InputBorder.none,
      ),
      onSubmitted: (v) {
        final title = v.trim();
        if (title.isNotEmpty && title != widget.task.title) {
          widget.store.editTask(widget.task.id, {'title': title});
        }
        FocusScope.of(context).unfocus();
      },
    );
  }
}

class _NoteField extends StatefulWidget {
  const _NoteField({required this.task, required this.store});

  final TaskItem task;
  final TaskStore store;

  @override
  State<_NoteField> createState() => _NoteFieldState();
}

class _NoteFieldState extends State<_NoteField> {
  late final _controller = TextEditingController(text: widget.task.note);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      maxLines: 2,
      textInputAction: TextInputAction.done,
      style: const TextStyle(fontSize: 14),
      decoration: const InputDecoration(
        hintText: '备注…',
        border: InputBorder.none,
      ),
      onSubmitted: (v) {
        final note = v.trim();
        if (note != (widget.task.note ?? '')) {
          widget.store.editTask(widget.task.id, {
            'note': note.isEmpty ? null : note,
          });
        }
        FocusScope.of(context).unfocus();
      },
    );
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onPick,
    required this.onClear,
  });

  final IconData icon;
  final String label;
  final int? value;
  final ValueChanged<int> onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: scheme.onSurface.withValues(alpha: .5)),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 14)),
        const Spacer(),
        TextButton(
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: value == null
                  ? DateTime.now()
                  : dateFromEpochDay(value!),
              firstDate: DateTime.now().add(const Duration(days: -365)),
              lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
            );
            if (picked != null) onPick(epochDayOf(picked));
          },
          child: Text(
            value == null ? '设置' : formatDueDay(value!),
            style: TextStyle(
              fontSize: 13,
              color: value == null
                  ? scheme.primary
                  : scheme.onSurface.withValues(alpha: .8),
            ),
          ),
        ),
        if (value != null)
          IconButton(
            tooltip: '清除',
            icon: const Icon(Icons.close, size: 16),
            onPressed: onClear,
          ),
      ],
    );
  }
}

class _EnergyRow extends StatelessWidget {
  const _EnergyRow({required this.task, required this.store});

  final TaskItem task;
  final TaskStore store;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('精力', style: TextStyle(fontSize: 14)),
        const Spacer(),
        SegmentedButton<String>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(
              value: '',
              label: Text('无', style: TextStyle(fontSize: 13)),
            ),
            ButtonSegment(
              value: 'high',
              label: Text('高', style: TextStyle(fontSize: 13)),
            ),
            ButtonSegment(
              value: 'low',
              label: Text('低', style: TextStyle(fontSize: 13)),
            ),
          ],
          selected: {task.energy ?? ''},
          onSelectionChanged: (s) => store.editTask(task.id, {
            'energy': s.first.isEmpty ? null : s.first,
          }),
        ),
      ],
    );
  }
}

class _ProjectRow extends StatelessWidget {
  const _ProjectRow({required this.task, required this.store});

  final TaskItem task;
  final TaskStore store;

  @override
  Widget build(BuildContext context) {
    final projects = store.projectList;
    final current = task.projectId;
    final valid = projects.any((p) => p.id == current) ? current : null;
    return Row(
      children: [
        const Text('项目', style: TextStyle(fontSize: 14)),
        const Spacer(),
        DropdownButton<String>(
          value: valid,
          underline: const SizedBox.shrink(),
          hint: const Text('无项目', style: TextStyle(fontSize: 13)),
          items: [
            for (final p in projects)
              DropdownMenuItem(
                value: p.id,
                child: Text(p.name, style: const TextStyle(fontSize: 13)),
              ),
          ],
          onChanged: (v) => store.setTaskProject(task.id, v),
        ),
      ],
    );
  }
}

/// 标签区:已挂标签(点 ✕ 摘除)+ 候选标签(互斥冲突置灰禁点)+ 内联建标签。
/// 互斥校验在仓库层(TagRepository.assignTag),此处只做前置置灰与错误提示,
/// 避免用户点了才知道不合法;但红线仍在领域层,UI 不做唯一裁决。
class _TagSection extends StatefulWidget {
  const _TagSection({required this.task, required this.store});

  final TaskItem task;
  final TaskStore store;

  @override
  State<_TagSection> createState() => _TagSectionState();
}

class _TagSectionState extends State<_TagSection> {
  final _newTag = TextEditingController();
  var _creating = false;

  @override
  void dispose() {
    _newTag.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() op) async {
    try {
      await op();
    } on ExclusiveTagGroupError catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '「${e.existing.groupName ?? '互斥组'}」已含「${e.existing.name}」，'
              '不能再加「${e.candidate.name}」',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final task = widget.task;
    final store = widget.store;
    final assigned = task.tags;
    final assignedIds = {for (final t in assigned) t.id};
    final candidates = [
      for (final t in store.tagCatalog)
        if (!assignedIds.contains(t.id)) t,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.sell_outlined,
              size: 18,
              color: scheme.onSurface.withValues(alpha: .5),
            ),
            const SizedBox(width: 8),
            const Text('标签', style: TextStyle(fontSize: 14)),
            const Spacer(),
            if (!_creating)
              TextButton.icon(
                onPressed: () => setState(() => _creating = true),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('新建', style: TextStyle(fontSize: 13)),
              ),
          ],
        ),
        if (assigned.isEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 26, top: 2),
            child: Text(
              '暂无标签',
              style: TextStyle(
                fontSize: 13,
                color: scheme.onSurface.withValues(alpha: .45),
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(left: 26, top: 4),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final t in assigned)
                  InputChip(
                    label: Text(t.name, style: const TextStyle(fontSize: 12)),
                    avatar: t.groupId == null
                        ? null
                        : Icon(
                            Icons.label_outline,
                            size: 14,
                            color: scheme.primary,
                          ),
                    onDeleted: () =>
                        _run(() => store.unassignTag(task.id, t.id)),
                    deleteIcon: const Icon(Icons.close, size: 14),
                  ),
              ],
            ),
          ),
        if (_creating)
          Padding(
            padding: const EdgeInsets.only(left: 26, top: 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const ValueKey('new-tag-field'),
                    controller: _newTag,
                    autofocus: true,
                    style: const TextStyle(fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: '新标签名,回车创建',
                      isDense: true,
                    ),
                    onSubmitted: (v) async {
                      final name = v.trim();
                      if (name.isNotEmpty) {
                        final tag = await store.createTag(name);
                        await _run(() => store.assignTag(task.id, tag.id));
                      }
                      _newTag.clear();
                      if (mounted) setState(() => _creating = false);
                    },
                  ),
                ),
              ],
            ),
          ),
        if (candidates.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 26, top: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final t in candidates)
                  _CandidateChip(
                    tag: t,
                    blocked: _blocked(t, assigned),
                    onTap: () => _run(() => store.assignTag(task.id, t.id)),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  /// 互斥组已有同组标签 → 前置置灰(仍以领域红线为最终裁决)。
  bool _blocked(TagDescriptor candidate, List<TagDescriptor> assigned) {
    if (!candidate.groupExclusive) return false;
    return assigned.any(
      (t) => t.groupId != null && t.groupId == candidate.groupId,
    );
  }
}

class _CandidateChip extends StatelessWidget {
  const _CandidateChip({
    required this.tag,
    required this.blocked,
    required this.onTap,
  });

  final TagDescriptor tag;
  final bool blocked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: blocked ? '同组「${tag.groupName}」已有标签' : '点击挂上',
      child: ActionChip(
        label: Text(tag.name, style: const TextStyle(fontSize: 12)),
        onPressed: blocked ? null : onTap,
        side: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: blocked ? .3 : 1),
        ),
      ),
    );
  }
}

class _StatusChips extends StatelessWidget {
  const _StatusChips({required this.task, required this.store});

  final TaskItem task;
  final TaskStore store;

  static const _options = [
    (TaskStatus.inbox, '收件箱'),
    (TaskStatus.next, '下一步'),
    (TaskStatus.waiting, '等待'),
    (TaskStatus.someday, '随时'),
    (TaskStatus.done, '完成'),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        for (final (status, label) in _options)
          ChoiceChip(
            label: Text(label, style: const TextStyle(fontSize: 13)),
            selected: task.status == status,
            onSelected: (_) async {
              try {
                await store.setTaskStatus(task.id, status);
              } on Error {
                // 领域红线(IllegalTransitionError):提示而不崩。
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '「${task.status.value} → ${status.value}」不在允许的流转内',
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
          ),
      ],
    );
  }
}
