# 程簿（Agendum）· 开发计划

> 本目录是「程簿（Agendum）」——AI 原生 GTD 任务管理软件——的工程开发计划文档库。
> 计划依据：2026-09-19《程簿Agendum-可行性分析报告与实现路线》（v1.0，立项评审稿，存于 `.zcode/workspace/default/`）。
> 文档版本：v1.0 ｜ 编制日期：2026-09-19 ｜ 假设 kickoff：2026-10-05（周一，可整体平移）。

---

## 文档地图

| 文档 | 内容 | 主要读者 |
| --- | --- | --- |
| [docs/01-开发总纲与里程碑.md](docs/01-开发总纲与里程碑.md) | 阶段闸门、里程碑甘特、日历锚点、团队分工、风险触发器、KPI 埋点责任、合规里程碑 | 全员 |
| [docs/02-工程架构与规范.md](docs/02-工程架构与规范.md) | Monorepo 结构、技术栈清单、ADR 决策记录、编码/测试/CI-CD 规范、本地开发环境 | 研发 |
| [docs/03-数据模型与同步协议.md](docs/03-数据模型与同步协议.md) | SQLite DDL v1、oplog 同步协议、字段级 LWW 冲突解决、E2EE 加密设计、验收红线 | 研发 |
| [docs/04-AI系统与评估体系.md](docs/04-AI系统与评估体系.md) | 六引擎工程规格、工具调用协议、模型路由网关、提示词版本管理、黄金评估集 | 研发/AI |
| [docs/05-Phase0-执行计划.md](docs/05-Phase0-执行计划.md) | 验证期 8 周逐周计划（评估集、CLI 原型、同步 PoC、访谈、风格样板、闸门评审） | 全员 |
| [docs/06-Phase1-MVP-执行计划.md](docs/06-Phase1-MVP-执行计划.md) | MVP 期 10 个 sprint 逐期计划（GTD 骨架、捕获条、E2E 同步、拆解师、TestFlight 私测） | 全员 |
| [docs/07-Phase2-Phase3-执行计划.md](docs/07-Phase2-Phase3-执行计划.md) | 商业化期与生态期月度计划（澄清副驾、日历、计费、MCP、1.0 发布） | 全员 |

## 计划一览（TL;DR）

- **四阶段 18 个月**：Phase 0 验证（M1–2）→ Phase 1 MVP（M3–7）→ Phase 2 AI 深化与商业化（M8–12）→ Phase 3 生态与 1.0（M13–18）。
- **两道硬闸门**：Phase 0 的 AI 质量闸门（解析准确率 ≥90%）、Phase 2 的付费转化闸门（≥4%）。不达标即收缩范围，不加码投入。
- **节奏**：双周迭代，全程约 39 个 sprint（S01–S39）＋ 2 个发布缓冲 sprint（S38–S39）。
- **团队**：6 人起步（产品/设计 1、Flutter 2、后端 1、AI 1、产品负责人兼任 PM），Phase 2 扩至 8 人。
- **首端**：macOS + iOS；Phase 2 补 Android/Windows；Web 只读兜底放 Phase 3。

## 技术决策速览（详见 02 文档 ADR）

| 决策点 | 结论 |
| --- | --- |
| 客户端 | Flutter（单库五端），Riverpod 3 + Drift（SQLite） |
| 后端 | Dart（Dart Frog + Postgres），与客户端共享协议与领域代码 |
| 同步 | 自研 oplog + 字段级 LWW + 墓碑；PowerSync 为触发式兜底（见 03 文档 §8） |
| 加密 | Argon2id 派生 + XChaCha20-Poly1305，BIP39 恢复短语 |
| 端上 AI | 规则引擎 + Apple DataDetectors / Foundation Models 框架，云端回落 |
| 计费 | RevenueCat（App Store / Play / Stripe 统一） |
| 日历 | Apple 平台 EventKit 优先；非 Apple 平台直连 Google Calendar API |
| 生态 | MCP Server 用官方 Dart SDK，复用 AI 工具层定义（Phase 3 之首） |

## 使用约定

- 文档为**活文档**：阶段执行文档（05–07）每 sprint 评审更新；架构文档（02–04）变更须走 ADR 记录。
- 所有阶段退出标准与可行性报告 §8 一一对应，报告中未量化处已在本计划补充为可测指标。
- 商机/定价/营销细节不在本库范围内，见可行性报告 §7、§9。

---

## 工程进展

| 日期 | 里程碑 | 说明 |
| --- | --- | --- |
| 2026-09-19 | **Phase 0 W1（S01 工程线）完成** | monorepo 初始化：pub workspaces（ADR-015）＋ 6 个工作区成员（domain/protocol/sync/nlp/server/eval）；domain（状态机、Lamport、RRULE 子集、分数索引）、protocol（oplog 契约）、sync（字段级 LWW）、nlp（捕获解析规则引擎 v0）均有实现与测试，共 89 例全绿；黄金评估集种子 20 例 + harness CLI（100% 通过）；server 契约骨架、docker compose、PR-CI/nightly 工作流就绪；`make ci` 本地全绿 |
| 2026-09-19 | **Web 演示页上线** | `apps/demo`：四个可交互演示（智能捕获实时解析 / 双设备 LWW 冲突裁决 / RRULE 展开 / GTD 状态机）——真实引擎代码经 dart2js 编译进浏览器，非 mock。`make demo` 启动（http://localhost:8181）；黄金评估集扩至 32 例（100%）；全仓 92 例测试全绿 |
| 2026-09-19 | **同步引擎 PoC 落地（W5–6 提前）** | 03 文档 §4 协议在 `apps/server` 实现：SyncStore 抽象 + 内存/Postgres 双实现（sync_ops + entity_lamport 裁决表）、push/pull 真实端点；双客户端收敛 PoC 测试 6 场景全过；PG 集成测试 + 端到端 curl 冒烟通过（`make up` 起 PG，宿主机 5433）；E2EE 密文化留待 S08 |
| 2026-09-19 | **AI 网关骨架 + 端云链路打通** | `/v1/ai/parse` 云端回落端点：分级强制（L2/L3 须 BYOK 否则 403）、月度额度账本（429）、可插拔适配器、prompt_version 回显；演示页可从浏览器直连真实服务端体验完整端云流程 |
| 2026-09-19 | **Flutter SDK 就位 + 风格样板落地（W7–8 提前）** | Flutter 3.47.4（国内镜像安装，锁定版本）；`apps/client` 接入 workspace：捕获条（实时解析预览，真实 nlp 引擎）/收件箱/今日视图（"现在，做这件事"）三屏，亮暗双主题，4 个 widget 测试全绿；`make ci` 升级为全 flutter 工具链（8 套件全绿） |
| 待办 | macOS/iOS 真机构建（需 Xcode + CocoaPods） | `flutter run` 走查前的环境准备；W7–8 风格走查清单执行 |
