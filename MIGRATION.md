# 迁移交接：macOS → Linux（2026-09-21）

> 本文是程簿（Agendum）从 macOS 开发机迁往 Linux 长期作业的一次性交接锚点。
> 目标：迁移后状态、任务、记忆、业务规则零丢失。落地后本文保留作历史存档。
> 兄弟项目 partisync / wordfolio 各有独立交接（partisync 已有其 `migration-handoff-macos-to-linux` 记忆），本文只覆盖 agendum。

---

## 0. 迁移时点快照

| 项 | 值 |
| --- | --- |
| 分支 / 工作区 | `main`，工作区 clean，无 tag；远端 **`https://github.com/Partiverse/agendum-dev`**（private，2026-09-21 已推送 `d623717`） |
| 最后代码提交 | `9455bb8`（S07：标签系统 + 拖拽排序 + E2EE 层 + 设计走查 #1），其时 `make ci` 全绿 |
| 本文档所在提交 | 交接锚点提交（`fba0eda` 为其父，docs-only，不涉代码） |
| 测试基线 | 全仓 110+ 例测试全绿；黄金评估集约 300 例，CI 门槛 `--min 0.75` |
| 计划进度 | Phase 0 的 W1–2 物料（评估集 265→300、访谈物料）已完成；**S05/S06/S07 已提前完成**（相当于 Phase 1 M3–M4 上旬）；下一站 S08 |
| 已确认无遗留 | ZCode 定时任务/闲时任务均为空（CronList/OffPeakList 已核） |

CI 即 `ubuntu-latest`（`.github/workflows/pr-ci.yml`，Flutter 3.47.4），**仓库本身已验证可在 Linux 工具链下全绿**，迁移平台风险很低。

## 1. 迁移物清单

### 必带

1. **git 历史**（已推 GitHub，bundle 转为离线备份）：
   - 远端：`https://github.com/Partiverse/agendum-dev`（private，Kubuntu 侧 `git clone` 此地址即可）。
   - 离线备份：`/Users/nebulaboratories/ai-dev-codebase/agendum-migration-20260921.bundle`（1.9 MB，含完整历史，`git clone <bundle> -b main` 可用）。
   - 注：mac 全局 gitconfig 有 `url.https://gh-proxy.com/…insteadOf` 重写（国内直连加速）；**Linux 默认没有**，直连 github.com，如需镜像自行加同样的全局重写。
2. **持久记忆目录**（不随 git 走）：
   `/Users/nebulaboratories/.zcode/cli/memories/projects/agendum-dev-64c18836016433f5/memory/`
   （2 个文件：`MEMORY.md` 索引 + `agendum-macos-build-quirks.md` + 本迁移新增的 `migration-handoff-macos-to-linux.md`）。重挂方法见 §5。
3. **可行性报告原件**（原存 `~/.zcode/workspace/default/程簿Agendum-可行性分析报告与实现路线.md`，在仓库之外、git 之外）——本次已**复制入库**为 `docs/00-可行性分析报告与实现路线.md`，随 bundle 走；原件 mac 侧留存。

### 可选（只读参考）

- 会话记录：`~/.zcode/cli/db/db.sqlite`（110 MB，session/message 索引）＋ `~/.zcode/cli/rollout/model-io-sess_*.jsonl`（仅最近两个 agendum 会话有 model-io 日志：`96cc1a68`≈151 MB、`04ba9ddf`）。会话谱系已固化在本文 §3，即使不带记录也不丢结论。
- `~/.zcode/cli/artifacts/`（会话产物缓存）。

### 不带（可重建 / 平台特有）

- `build/`、`*/.dart_tool/`、`apps/client/build/`（工作区 1.1 GB 的大头，Linux 全量重编）。
- `.DS_Store`；macOS app 运行时数据 `~/Library/Containers/dev.agendum.agendumClient/`（开发种子库，空库会自动重新播种，无需迁移）。
- Xcode / CocoaPods / `DEVELOPER_DIR` / ScreenCaptureKit 截图管线相关一切（macOS-only）。

## 2. Linux 侧重建步骤（按序执行）

1. 工具链：Flutter 3.47.x stable + Dart 3.10.6（Linux x64/aarch64 官方均有；CI 锁 3.47.4）；Docker（`make up` 起 Postgres，宿主机 5433）；GNU make。`mise.toml` 备而未用（brew 仅为 mac 方案）。
2. 取代码（二选一）：`gh repo clone Partiverse/agendum-dev`（先 `gh auth login`，HTTPS 协议，token 需 repo+workflow scope）；或 `git clone https://github.com/Partiverse/agendum-dev.git`；无网环境用 bundle（§1）。
3. `flutter pub get`（pub workspaces 一次解析全部成员；`pubspec.lock` 已入库保证可复现）。
4. **`make ci`**（fmt-check → analyze → test → eval → flutter-check）——迁移后第一件事，全绿才算迁移成功。
5. ~~建远端~~ **mac 侧已完成**：仓库为 Partiverse/agendum-dev（private）。Linux 只需 `gh auth login` 后正常 fetch/push。
6. 服务端冒烟：`PORT=8090 dart run apps/server/bin/server.dart`（无 `DATABASE_URL` 时用内存存储）；`curl 'localhost:8090/v1/sync/pull?since=0'`。
7. 客户端：`apps/client` 目前只含 macos/ios 平台目录。Linux 上 `flutter test` 不受影响；要桌面运行需 `flutter config --enable-linux-desktop && flutter create --platforms=linux .`（生成的 `linux/` 是否入库需另行决定；macos/Runner 已入库，不受影响）。
8. 记忆重挂（§5）。

## 3. 会话谱系（跨机续接锚点）

| 会话 | 时间 | 主题 → 产出 |
| --- | --- | --- |
| `sess_ffb8fb69` | 09-19 凌晨 | 程簿调研与设计方案（workspace/default）→ 可行性分析报告（已入库 `docs/00`） |
| `sess_f2446d1e` | 09-19 | 制定开发计划 docs 01–07；Flutter 工具链就位；S03/S04 风格样板；macOS 真机走查 → `c3e4ef8`…`32ce682` |
| `sess_f61bb511` | 09-19 夜–09-20 | S05 数据层：Drift + 客户端同步闭环 → `e3e4048`；写入本机构建要点记忆 |
| `sess_8dd9abff` | 09-20 上午 | W1–2 评估集扩容（32→265）＋访谈物料；S07 切片（任务详情页）→ `634a90e`、`6767c12`、`315b163` |
| `sess_96cc1a68` | 09-20 全天 | S07 剩余：标签互斥/拖拽排序/E2EE 层/设计走查 #1 → `9455bb8`、`fba0eda`；更新构建记忆 |
| `sess_04ba9ddf` | 09-21 | 本次迁移交接 |

所有历史会话 TODO 均已 completed，无挂起任务。若新机器 `ReadSessionContext` 按 sess_id 不可达，以本表＋docs/ 为准。

## 4. 工作进展与下一步（S08 待办）

按 `docs/06` S08 行，迁移后即开工：

- 嵌套项目树 + next action 显式强调；等待/将来也许视图；状态流转手势。
- 状态机统一（inbox→next→waiting→someday→done→trashed 及回退）；重复任务完成即展开下一个。
- **混沌测试套件 v1**（03 文档 §7.2 场景 1–7）接入 nightly；墓碑与 GC；断网重连。
- **E2EE 接线**：S07 已就绪 VaultKeys/`E2eeOpCodec`/设备注册端点，但 oplog 仍明文（`value_blob`），S08 换密文串入 push/pull。
- macOS 全局捕获条（⌥Space 悬浮窗）——**macOS-only 平台能力，Linux 开发期搁置或做平台抽象**（02 文档 §4.3 已要求 macOS 质感收敛到 `platform/`）。

## 5. 持久记忆（auto-memory）重挂

- 位置：`~/.zcode/cli/memories/projects/agendum-dev-64c18836016433f5/memory/`。project key 按工作区路径哈希生成，**Linux 路径不同 → 新 key → 记忆不会自动加载**。
- 方法：Linux 首次打开工作区生成新 key 目录后，把上述 `memory/` 整体拷入。
- 内容甄别：`agendum-macos-build-quirks.md` 中 **macOS-only**（DEVELOPER_DIR、PATH、SPM HTTP2 降级、ScreenCaptureKit 截图管线、Containers 数据路径、`flutter build macos`）条目可删；**跨平台仍有效**的是：drift watch 流在 FakeAsync zone 不可达 → 视图用显式快照 + `SyncEngine.onRemoteApplied` 刷新（设计约束，详见 `packages/db/README.md`）；长命令注意工作目录。原文全文存档于 §6。

## 6. macOS 构建要点原文存档（Linux 仅供参考）

- `xcode-select` 未切换：构建前 `export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`。
- PATH：brew `dart` 在前会干扰 Flutter 工具链，`export PATH="$HOME/flutter-sdk/bin:$PATH"`（Flutter 3.47.x）。
- SPM 拉包 HTTP2 故障：`GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=http.version GIT_CONFIG_VALUE_0=HTTP/1.1`（进程级，勿改全局 git config）。
- 改码后必须 `flutter build macos --debug` 重建再实测（`open` 旧包跑旧代码，易误判 bug）。
- 截图管线：ScreenCaptureKit `SCContentFilter(desktopIndependentWindow:)` + `SCScreenshotManager.captureImage`，必须包在 NSApplication runloop 内；AX 树对 Flutter 窗口可点但拿不到像素。

## 7. 业务规则地图（均在 repo 内，随 git 迁移，不丢失）

- **规范与 ADR**：`docs/02` —— ADR-001…015 索引（Flutter/Riverpod+Drift/Dart Frog/自研 oplog 字段级 LWW/E2EE/规则引擎+云回落/UUIDv7/RRULE 子集/分数索引/pub workspaces…）；编码/协作/测试/CI 规范。
- **数据与同步红线**：`docs/03` —— DDL v1、Lamport 规则、oplog 协议、字段级 LWW `(lamport, origin)` 裁决、E2EE 设计（§6）、混沌矩阵（§7.2）、PowerSync 兜底标准（§8）。
- **代码内红线**：状态变更只走 `domain` 的 `transition()`；`TaskRepository` 是唯一写路径（事务内 lamport tick + 字段级 oplog）；视图不订阅 drift watch；密钥禁止入库（`.gitignore` 已挡 `.env*`）。
- **AI 与评估**：`docs/04` —— 六引擎、模型路由网关、评估集规范（对抗样例 ≥15%、分层标注 rule_solvable/needs_system_model/needs_cloud）；`tools/eval`（CI 门槛 0.75，G0 目标 ≥90%）。
- **范围纪律**：`docs/06` §4 "明确不做"清单（S05 锁定，变更须 P0 书面批准）。
- **提交规范**：Conventional Commits；trunk-based；PR CI 全绿才可合并。

## 8. 平台差异与风险

| 项 | 影响 |
| --- | --- |
| ~~无 git 远端~~ 已解决 | 2026-09-21 mac 侧已建 private 远端并推送；bundle 留作离线备份 |
| 实机走查/截图管线 | ScreenCaptureKit 方案不可迁移；Linux 上走 widget test / 手动核对 |
| KPI 数字口径 | 现有性能数字均为 Apple Silicon 实测，Linux 不可直接对比，验收需重测口径 |
| Apple 平台能力 | DataDetectors/Foundation Models 桥（ADR-006）、EventKit、全局捕获条均为 Apple 侧；Linux 开发期以规则引擎/平台抽象推进 |
| 首端决策 | 首端 macOS+iOS 不变；Linux 机定位为开发/测试/服务端机 |

## 9. ZCode 全局侧（跨项目通用）

- `~/.zcode/v2/`（`tasks-index.sqlite`、`setting.json`）、`~/.zcode/cli/db/db.sqlite` 可作只读档案带走；**凭证类（`provider_config.json`、`credentials.json`）建议不拷贝，Linux 重新登录**。
- 插件缓存（`~/.zcode/cli/plugins/cache/`）在 Linux 重新下载即可；`certs/zcode-network-ca` 如有代理抓包需求再迁。
- 定时任务/闲时任务：已确认为空，无迁移项。
