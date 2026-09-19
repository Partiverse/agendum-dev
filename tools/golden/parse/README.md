# 捕获解析黄金评估集

> 依据：04 文档 §6（黄金评估集）、05 文档 §2（W1–2 构建规范）。评估集变更走 PR 评审；
> 线上 bad case 先进评估集再修提示词/规则，防止按例修例过拟合。

## 现状（2026-09-20，S06 交付）

- **规模**：300 例（zh 158 + en 142），达成 S06 目标 ≥300；后续随私测 bad case 续补。
- **当前基线**：本地规则引擎 `local-rules-v1` 用例级通过 276/300（92.0%），
  **rule_solvable 层 242/242（100%）**；CI 门槛 `--min 0.75`（`make eval`）。
  失败集中于 needs_system_model / needs_cloud 分层（设计内，待系统检测器与云回落接线）。
- **对抗样例**：46 例（15.3%），覆盖错别字、双日期/双时刻冲突、方言口语、无动词短语、噪音符号。
- **v1 规则引擎已补**（原 v0 缺口）：`今晚/今早/明早/明晚` 口语时段词（紧跟时刻时按
  上午/下午解析）、日期后"…前"截止语义、标签边界尾随标点、双项目路由记歧义、`明儿`归一化。

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
| date | 31 | 20 | 12 | 36 | 12 | 8 |
| time | 21 | 13 | 6 | 24 | 11 | 9 |
| duration | 15 | 6 | 5 | 13 | 6 | 6 |
| energy | 9 | 2 | 1 | 8 | 2 | 1 |
| tag | 8 | 4 | 2 | 9 | 2 | 3 |
| project | 9 | 2 | 3 | 8 | 3 | 2 |
| plain | 2 | 0 | 5 | 7 | 1 | 3 |

缺口格子（energy/tag/project 的口语与歧义列）为后续补齐项：优先从访谈与候补名单
用户授权的真实表述中收集（05 文档 §3 产出 → 05 文档 §2 数据来源边界），其次人工补例。

## 运行

```sh
make eval                                        # CI 同款：replay/本地适配器，--min 0.75
dart run tools/eval/bin/eval.dart run --engine parse   # 不带门槛，看全量分层报告
```

输出含：用例级通过率、字段命中率、分层通过率（`rule_solvable` /
`needs_system_model` / `needs_cloud`）、对抗样例占比。live 模式（云端模型 +
record/replay）待网关接入后启用（04 文档 §6.2），适配器接口见 `tools/eval/lib/src/adapter.dart`。
