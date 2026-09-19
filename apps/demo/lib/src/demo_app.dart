/// 演示页 UI：四个 tab 分别驱动真实引擎代码
/// （nlp 捕获解析 / sync 字段级 LWW / domain RRULE / domain 状态机）。
library;

import 'dart:js_interop';

import 'package:agendum_domain/agendum_domain.dart';
import 'package:agendum_nlp/agendum_nlp.dart';
import 'package:agendum_protocol/agendum_protocol.dart';
import 'package:agendum_sync/agendum_sync.dart';
import 'package:web/web.dart' as web;

import 'cloud.dart';
import 'format.dart';

web.HTMLElement _el(String tag, [String? cls, String? text]) {
  final e = web.document.createElement(tag) as web.HTMLElement;
  if (cls != null && cls.isNotEmpty) e.className = cls;
  if (text != null) e.textContent = text;
  return e;
}

web.HTMLInputElement _input({required String placeholder, String? value}) {
  final e = web.HTMLInputElement();
  e.placeholder = placeholder;
  if (value != null) e.value = value;
  return e;
}

void _on(web.Element target, String type, void Function() handler) {
  target.addEventListener(type, ((web.Event _) => handler()).toJS);
}

void _clear(web.HTMLElement container) => container.textContent = '';

void _onClick(web.HTMLElement target, void Function() handler) =>
    _on(target, 'click', handler);

void _onInput(web.HTMLElement target, void Function() handler) =>
    _on(target, 'input', handler);

/// 占位回调（延迟绑定前给闭包一个 void Function() 类型的初值）。
void _noop() {}

/// 演示页装配入口（index.html 骨架已存在，只填充 nav 与 main）。
void runDemo() {
  final nav = web.document.querySelector('#tabs')!;
  final main = web.document.querySelector('#content')!;

  final tabs = <String, String>{
    'capture': '① 智能捕获',
    'sync': '② 同步冲突裁决',
    'recurrence': '③ 重复规则展开',
    'status': '④ GTD 状态机',
  };
  web.HTMLElement? activeBtn;
  final panes = <String, web.HTMLElement>{};
  final keys = tabs.keys.toList();

  void show(String key) {
    for (final e in panes.values) {
      e.style.display = 'none';
    }
    panes[key]!.style.display = 'block';
    if (activeBtn != null) activeBtn!.classList.remove('active');
    activeBtn = nav.children.item(keys.indexOf(key)) as web.HTMLElement;
    activeBtn!.classList.add('active');
  }

  tabs.forEach((key, label) {
    final btn = _el('button', 'tab-btn', label);
    _onClick(btn, () => show(key));
    nav.append(btn);
    final pane = _el('section', 'pane');
    main.append(pane);
    panes[key] = pane;
    switch (key) {
      case 'capture':
        buildCapture(pane);
      case 'sync':
        buildSync(pane);
      case 'recurrence':
        buildRecurrence(pane);
      case 'status':
        buildStatus(pane);
    }
  });
  show('capture');
}

// --------------------------------------------------------------- ① 智能捕获

void buildCapture(web.HTMLElement pane) {
  final parser = CaptureParser();
  const presets = [
    '下周三下午3点前给司机发合同 30min !高精力',
    '明天上午10点开团队会',
    '#采购 打印纸 2小时',
    '@程簿 写周报',
    '周五或周六看电影',
    '下午4点半取快递',
    'tomorrow 2pm standup',
    'review PR 30min !low',
    '买牛奶',
  ];

  pane.append(
    _el(
      'p',
      'pane-desc',
      '输入自然语言，端上规则引擎实时解析（packages/nlp 真实代码，浏览器内运行）。'
          '这正是报告 §5.3 引擎 1 的端上第一层——免费、离线、确定性。',
    ),
  );
  final chipRow = _el('div', 'chip-row');
  final input = _input(placeholder: '试试：下周三下午3点前给司机发合同 30min !高精力')
    ..className = 'capture-input';
  final out = _el('div');

  void reparse() {
    _clear(out);
    if (input.value.trim().isEmpty) {
      out.append(_el('div', 'hint', '↑ 输入任意中文/英文任务，或点击上方示例'));
      return;
    }
    out.append(_renderCapture(parser.parse(input.value)));
  }

  for (final p in presets) {
    final chip = _el('button', 'chip', p);
    _onClick(chip, () {
      input.value = p;
      reparse();
    });
    chipRow.append(chip);
  }

  _onInput(input, reparse);
  pane.append(chipRow);
  pane.append(input);
  pane.append(out);

  // 云端回落演示：同一输入经真实服务端 /v1/ai/parse（分级 + 额度 + 适配器）。
  final cloudRow = _el('div', 'chip-row');
  final cloudBtn = _el('button', 'chip accent', '☁ 发送到云端网关（L1）');
  final cloudNote = _el(
    'span',
    'hint',
    '端上置信度不足时的回落路径——请求发往 localhost:8090 的真实服务端。',
  );
  final cloudOut = _el('div');
  _onClick(cloudBtn, () async {
    _clear(cloudOut);
    if (input.value.trim().isEmpty) {
      cloudOut.append(_el('div', 'hint', '先在上方输入内容'));
      return;
    }
    cloudOut.append(_el('div', 'hint', '请求中…'));
    try {
      final r = await callCloudParse(input.value);
      _clear(cloudOut);
      cloudOut.append(_renderCloudResponse(r));
    } catch (_) {
      _clear(cloudOut);
      cloudOut.append(
        _el(
          'div',
          'amb-item',
          '✗ 无法连接服务端（启动方式：make up 后 '
              'DATABASE_URL=… dart run apps/server/bin/server.dart）',
        ),
      );
    }
  });
  cloudRow.append(cloudBtn);
  cloudRow.append(cloudNote);
  pane.append(cloudRow);
  pane.append(cloudOut);
  reparse();
}

web.HTMLElement _renderCloudResponse(Map<String, Object?> r) {
  final wrap = _el('div', 'capture-result');
  final head = _el('div', 'card');
  head.append(
    _el(
      'div',
      'card-label',
      '服务端响应 · adapter=${r['adapter']} · prompt=${r['prompt_version']}',
    ),
  );
  final q = r['quota'] as Map? ?? {};
  head.append(
    _el(
      'div',
      'card-value',
      '本月额度 ${q['used']}/${q['limit']}（剩 ${q['remaining']}）',
    ),
  );
  wrap.append(head);

  final grid = _el('div', 'card-grid');
  void field(String label, Object? value) {
    if (value == null || value.toString().isEmpty) return;
    final c = _el('div', 'card');
    c.append(_el('div', 'card-label', label));
    c.append(_el('div', 'card-value', value.toString()));
    grid.append(c);
  }

  final result = r['result'] as Map? ?? {};
  field('标题', result['title']);
  final dueDay = result['due_day'];
  if (dueDay is int) field('截止日', formatEpochDay(dueDay));
  field('预计时长（分钟）', result['estimate_minutes']);
  field(
    '精力',
    result['energy'] == 'high'
        ? '!高精力'
        : result['energy'] == 'low'
        ? '!低精力'
        : null,
  );
  final tags = result['tags'];
  if (tags is List && tags.isNotEmpty) {
    field('标签', tags.map((t) => '#$t').join('  '));
  }
  field('置信度', result['confidence']);
  wrap.append(grid);
  return wrap;
}

web.HTMLElement _renderCapture(ParsedCapture r) {
  final wrap = _el('div', 'capture-result');

  final titleCard = _el('div', 'card title-card');
  titleCard.append(_el('div', 'card-label', '标题（剩余文本）'));
  titleCard.append(_el('div', 'card-value big', r.title));
  wrap.append(titleCard);

  final grid = _el('div', 'card-grid');
  void field(String label, String? value) {
    if (value == null || value.isEmpty) return;
    final c = _el('div', 'card');
    c.append(_el('div', 'card-label', label));
    c.append(_el('div', 'card-value', value));
    grid.append(c);
  }

  if (r.dueDay != null) field('截止日', formatEpochDay(r.dueDay!));
  if (r.dueAtMs != null) field('截止时刻', formatHm(r.dueAtMs));
  if (r.reminderAtMs != null && r.dueAtMs != r.reminderAtMs) {
    field('提醒', formatHm(r.reminderAtMs));
  }
  if (r.estimateMinutes != null) field('预计时长', '${r.estimateMinutes} 分钟');
  if (r.energy != null) {
    field('精力', r.energy == 'high' ? '!高精力' : '!低精力');
  }
  if (r.tags.isNotEmpty) field('标签', r.tags.map((t) => '#$t').join('  '));
  if (r.projectHint != null) field('项目路由', '@${r.projectHint}');
  if (r.isDeadline) field('语义标记', '含"…前" → 截止（deadline）');
  wrap.append(grid);

  final confRow = _el('div', 'conf-row');
  confRow.append(_el('span', 'card-label', '置信度'));
  final track = _el('div', 'conf-track');
  final fill = _el('div', 'conf-fill');
  final pct = (r.confidence * 100).toStringAsFixed(0);
  fill.style.width = '$pct%';
  fill.classList.add(
    r.confidence >= 0.7 ? 'good' : (r.confidence >= 0.45 ? 'mid' : 'low'),
  );
  track.append(fill);
  confRow.append(track);
  confRow.append(_el('span', 'conf-num', '$pct%'));
  wrap.append(confRow);

  if (r.ambiguities.isNotEmpty) {
    final amb = _el('div', 'amb-box');
    for (final a in r.ambiguities) {
      amb.append(_el('div', 'amb-item', '⚠ $a'));
    }
    wrap.append(amb);
  }
  return wrap;
}

// ---------------------------------------------------------- ② 同步冲突裁决

final class _DeviceSim {
  _DeviceSim(this.id);

  final String id;
  final clock = LamportClock();
  final ops = <SyncOp>[];
  final state = EntitySyncState();
  final seen = <String>{};

  static String _key(SyncOp op) => '${op.deviceId}#${op.lamport}#${op.field}';

  SyncOp write(String? value) {
    final lamport = clock.tick();
    final op = SyncOp(
      deviceId: id,
      lamport: lamport,
      entity: SyncEntities.task,
      entityId: 'demo-task-1',
      field: 'title',
      type: value == null ? SyncOpType.del : SyncOpType.set,
      value: value == null ? null : OpValue(OpValueTypes.str, value),
    );
    ops.add(op);
    seen.add(_key(op));
    state.apply(op);
    return op;
  }

  /// 收对端全部未见过的 op（模拟 pull + 合并，幂等重放不重复计数）。
  int receiveFrom(_DeviceSim other) {
    var n = 0;
    for (final op in other.ops) {
      if (seen.add(_key(op))) {
        clock.observe(op.lamport);
        state.apply(op);
        n++;
      }
    }
    return n;
  }

  void resetAll() {
    clock.reset();
    ops.clear();
    seen.clear();
    state.reset();
  }

  FieldEntry? get title => state.field('title');
}

void buildSync(web.HTMLElement pane) {
  final deviceA = _DeviceSim('设备A');
  final deviceB = _DeviceSim('设备B');
  final globalLog = <SyncOp>[];
  final refreshers = <void Function()>[];
  // 先绑定占位，panelOf 中的闭包捕获变量本身，稍后重新赋值即可。
  var refreshAll = _noop;

  pane.append(
    _el(
      'p',
      'pane-desc',
      '两个设备并发编辑同一条任务（真实 packages/protocol + packages/sync 代码）。'
          '裁决规则：lamport 大者胜 → 等时钟并发改/删时删除胜 → origin 设备 ID 破平。'
          '墙钟永不参与（混沌场景 4）。',
    ),
  );

  final row = _el('div', 'sync-row');
  final syncNote = _el('div', 'hint sync-note');
  final logBox = _el('div', 'sync-log');

  web.HTMLElement panelOf(_DeviceSim d) {
    final panel = _el('div', 'sync-panel');
    final head = _el('div', 'sync-head');
    head.append(_el('span', 'dev-name', d.id));
    final lam = _el('span', 'dev-lamport');
    head.append(lam);
    panel.append(head);

    final status = _el('div', 'dev-status');
    panel.append(status);

    final input = _input(placeholder: '新的任务标题…')..className = 'capture-input';
    final btnRow = _el('div', 'chip-row');
    final writeBtn = _el('button', 'chip accent', '写入 title');
    _onClick(writeBtn, () {
      if (input.value.trim().isEmpty) return;
      globalLog.add(d.write(input.value.trim()));
      input.value = '';
      refreshAll();
    });
    final delBtn = _el('button', 'chip danger', '删除任务');
    _onClick(delBtn, () {
      globalLog.add(d.write(null));
      refreshAll();
    });
    btnRow.append(writeBtn);
    btnRow.append(delBtn);
    panel.append(input);
    panel.append(btnRow);

    void refresh() {
      lam.textContent = 'lamport=${d.clock.value}';
      _clear(status);
      final t = d.title;
      if (t == null) {
        status.append(_el('div', 'dev-title muted', '（title 从未写入）'));
      } else if (t.isTombstone) {
        status.append(_el('div', 'dev-title tomb', '🗑 已删除（墓碑）'));
      } else {
        status.append(_el('div', 'dev-title', '"${t.value!.value}"'));
      }
      status.append(
        _el(
          'div',
          'dev-version',
          t == null
              ? ''
              : '生效版本 v(lamport=${t.version.lamport}, ${t.version.origin})',
        ),
      );
    }

    refreshers.add(refresh);
    return panel;
  }

  void renderLog() {
    _clear(logBox);
    logBox.append(_el('div', 'card-label', 'oplog（全局推送顺序）'));
    if (globalLog.isEmpty) {
      logBox.append(_el('div', 'hint', '尚无变更。在两侧设备写入或删除，再点"⇄ 双向同步"。'));
      return;
    }
    for (final op in globalLog) {
      final line = _el('div', 'log-line');
      final action = op.type == SyncOpType.del ? '删除' : '写入';
      final v = op.type == SyncOpType.del ? '' : ' = "${op.value!.value}"';
      line.append(
        _el(
          'span',
          'log-mono',
          '[${op.deviceId}] lamport=${op.lamport} → title $action$v',
        ),
      );
      logBox.append(line);
    }
  }

  void realRefreshAll() {
    for (final f in refreshers) {
      f();
    }
    renderLog();
  }

  refreshAll = realRefreshAll;

  final btnRow = _el('div', 'chip-row center');
  final syncBtn = _el('button', 'chip accent big-chip', '⇄ 双向同步');
  final resetBtn = _el('button', 'chip', '重置演示');
  _onClick(syncBtn, () {
    final aGot = deviceA.receiveFrom(deviceB);
    final bGot = deviceB.receiveFrom(deviceA);
    syncNote.textContent = '同步完成：设备A 收到 $aGot 条，设备B 收到 $bGot 条';
    refreshAll();
  });
  _onClick(resetBtn, () {
    deviceA.resetAll();
    deviceB.resetAll();
    globalLog.clear();
    syncNote.textContent = '已重置';
    refreshAll();
  });
  btnRow.append(syncBtn);
  btnRow.append(resetBtn);

  row.append(panelOf(deviceA));
  row.append(panelOf(deviceB));
  pane.append(row);
  pane.append(btnRow);
  pane.append(syncNote);
  pane.append(logBox);
  refreshAll();
}

// ---------------------------------------------------------- ③ 重复规则展开

void buildRecurrence(web.HTMLElement pane) {
  const presets = [
    'FREQ=WEEKLY;BYDAY=MO,WE',
    'FREQ=DAILY;INTERVAL=3;COUNT=6',
    'FREQ=MONTHLY;BYMONTHDAY=15',
    'FREQ=WEEKLY;INTERVAL=2;BYDAY=TU,TH;COUNT=8',
  ];
  pane.append(
    _el(
      'p',
      'pane-desc',
      'RFC 5545 RRULE 受控子集（ADR-012）。完成后自动展开下一次——重复任务的领域核心。',
    ),
  );
  final chipRow = _el('div', 'chip-row');
  final input = _input(placeholder: 'FREQ=WEEKLY;BYDAY=MO,WE')
    ..className = 'capture-input mono';
  final dateLabel = _el('label', 'card-label', '开始日（start 本身是第一次出现）');
  final dateInput = web.HTMLInputElement();
  dateInput.type = 'date';
  final today = DateTime.now();
  dateInput.value =
      '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
  final out = _el('div');

  void expand() {
    _clear(out);
    final ruleText = input.value.trim();
    if (ruleText.isEmpty) return;
    final RecurrenceRule rule;
    try {
      rule = RecurrenceRule.parse(ruleText);
    } on FormatException catch (e) {
      out.append(_el('div', 'amb-item', '✗ 解析失败：${e.message}'));
      return;
    } on ArgumentError catch (e) {
      out.append(_el('div', 'amb-item', '✗ ${e.message}'));
      return;
    }
    out.append(_el('div', 'hint', '规范化 → $rule'));
    final list = _el('div', 'occ-list');
    final startDay = epochDayFromInputValue(dateInput.value);
    var after = startDay - 1;
    for (var i = 0; i < 8; i++) {
      final n = rule.nextAfter(startDay: startDay, afterDay: after);
      if (n == null) break;
      final line = _el('div', 'occ-line');
      line.append(_el('span', 'occ-idx', '#${i + 1}'));
      line.append(_el('span', '', formatEpochDay(n)));
      list.append(line);
      after = n;
    }
    out.append(list);
  }

  for (final p in presets) {
    final chip = _el('button', 'chip mono', p);
    _onClick(chip, () {
      input.value = p;
      expand();
    });
    chipRow.append(chip);
  }
  _onInput(input, expand);
  _on(dateInput, 'change', expand);
  pane.append(chipRow);
  pane.append(input);
  pane.append(dateLabel);
  pane.append(dateInput);
  pane.append(out);
  expand();
}

// ---------------------------------------------------------- ④ GTD 状态机

void buildStatus(web.HTMLElement pane) {
  var current = TaskStatus.inbox;
  const zhName = {
    TaskStatus.inbox: '收件箱',
    TaskStatus.next: '下一步',
    TaskStatus.waiting: '等待中',
    TaskStatus.someday: '将来/也许',
    TaskStatus.done: '已完成',
    TaskStatus.trashed: '废纸篓',
  };

  pane.append(
    _el(
      'p',
      'pane-desc',
      'packages/domain 状态机是领域红线：任何写路径必须经 transition() 校验。'
          '点击按钮体验合法/非法流转。',
    ),
  );

  final pill = _el('div', 'status-pill');
  final grid = _el('div', 'card-grid');
  final note = _el('div', 'hint');
  var render = _noop;

  web.HTMLElement statusBtn(TaskStatus s) {
    final b = _el('button', 'chip status-btn', '${zhName[s]} (${s.value})');
    _onClick(b, () {
      if (canTransition(current, s)) {
        note.textContent = '✓ ${zhName[current]} → ${zhName[s]}（合法流转）';
        note.classList.add('ok');
        note.classList.remove('bad');
        current = s;
      } else {
        note.textContent =
            '✗ ${zhName[current]} → ${zhName[s]} 不被允许（废纸篓只能恢复到收件箱）';
        note.classList.add('bad');
        note.classList.remove('ok');
      }
      render();
    });
    return b;
  }

  void realRender() {
    pill.textContent = '当前状态：${zhName[current]} · ${current.value}';
    pill.classList.toggle('terminal', current.isTerminal);
    _clear(grid);
    for (final s in TaskStatus.values) {
      final b = statusBtn(s);
      if (s == current) b.classList.add('active');
      grid.append(b);
    }
  }

  render = realRender;

  pane.append(pill);
  pane.append(grid);
  pane.append(note);
  render();
}
