# 捕获解析黄金评估集

> 依据：04 文档 §6（黄金评估集）、05 文档 §2（W1–2 构建规范）。评估集变更走 PR 评审；
> 线上 bad case 先进评估集再修提示词/规则，防止按例修例过拟合。

## 现状（2026-09-20，W1–2 交付）

- **规模**：265 例（zh 140 + en 125），超出 Phase 0 v1 门槛 ≥200；S09 目标 300 条续补。
- **当前基线**：本地规则引擎 `local-rules-v0` 用例级通过 235/265（88.7%）；
  CI 门槛 `--min 0.75`（`make eval`）。S02（W3–4）目标把规则层迭代至 ≥90%。
- **对抗样例**：41 例（15.5%），覆盖错别字、双日期/双时刻冲突、方言口语、无动词短语、噪音符号。
- **已知规则层缺口**（rule_solvable 但 v0 未解，S02 优先补规则而非调提示词）：
  `明早/今晚` 时段词表缺口（zh-037、zh-039）、日期后"…前"截止语义（zh-048）、
  标签尾随标点并入（zh-132）、双项目歧义未记录（zh-064）。

## 用例格式

```yaml
id: zh-001
now: "2026-09-19T09:00:00"   # 固定时钟，期望值确定性推导（周六）
input: "下周三下午3点前给司机发合同 30min !高精力"
expect:
  due_date: "2026-09-23"     # YYYY-MM-DD
  due_time: "15:00"
  reminder_time: "15:00"
  estimate_minutes: 30
  energy: high
  tags: [采购]
  project_hint: 程簿
  title_contains: "给司机发合同"
  title_exact: "给司机发合同"
  ambiguities_min: 1
  is_deadline: true
  due_date: null             # 负期望：该字段应留空（防过度填充）
tags: [zh, date, easy, rule_solvable]
```

## 标签词表

| 维度 | 取值 | 说明 |
| --- | --- | --- |
| 语言 | `zh` / `en` | |
| 字段 | `date` `time` `duration` `energy` `tag` `project` `plain` | 一例可覆盖多字段 |
| 难度 | `easy` / `colloquial` / `ambiguous` | 直白 / 口语 / 歧义（05 文档 §2 矩阵） |
| 分层 | `rule_solvable` / `needs_system_model` / `needs_cloud` | 该例**应当**由哪一层解决；回归时分层报准确率，规则层低则优先补规则（04 文档 §4） |
| 对抗 | `对抗` | 错别字/冲突/方言/无动词/噪音，占比须 ≥15% |
| 专项 | `negative` `deadline` `noise` `typo` `dialect` `conflict` `no-verb` | 检索用 |

## 覆盖矩阵现状（语言 × 字段 × 难度，目标每格 ≥8）

| | zh easy | zh colloq | zh amb | en easy | en colloq | en amb |
| --- | --- | --- | --- | --- | --- | --- |
| date | 28 | 15 | 10 | 30 | 10 | 7 |
| time | 19 | 9 | 4 | 20 | 9 | 7 |
| duration | 14 | 5 | 3 | 11 | 6 | 4 |
| energy | 9 | 2 | 1 | 8 | 2 | 1 |
| tag | 8 | 3 | 1 | 8 | 2 | 2 |
| project | 8 | 2 | 2 | 7 | 3 | 1 |
| plain | 2 | 0 | 6 | 7 | 1 | 3 |

缺口格子（energy/tag/project 的口语与歧义列）为 S02 补齐项：优先从访谈与候补名单
用户授权的真实表述中收集（05 文档 §3 产出 → 05 文档 §2 数据来源边界），其次人工补例。

## 运行

```sh
make eval                                        # CI 同款：replay/本地适配器，--min 0.75
dart run tools/eval/bin/eval.dart run --engine parse   # 不带门槛，看全量分层报告
```

输出含：用例级通过率、字段命中率、分层通过率（`rule_solvable` /
`needs_system_model` / `needs_cloud`）、对抗样例占比。live 模式（云端模型 +
record/replay）待网关接入后启用（04 文档 §6.2），适配器接口见 `tools/eval/lib/src/adapter.dart`。
