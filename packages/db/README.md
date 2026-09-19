# packages/db

客户端本地数据层(本地权威):Drift + SQLite。DDL v1 见 `docs/03-数据模型与同步协议.md` §2;S05 落地。

## 内容

- **schema v1**(`lib/src/tables.dart`):`tasks`(03 文档 §2.2 子集,PoC 单实体)+ 同步基建:
  - `oplog`:待推送/已推送的字段级变更(03 文档 §2.4),开发模式 `value_blob` 存 OpValue JSON 明文,E2EE 时换密文(S08);
  - `sync_state`:设备 ID、lamport 时钟、拉取游标;
  - `field_lamport`:字段裁决镜像(03 文档 §2.4 之外的客户端补充表,与服务端 `entity_lamport` 同构)—— pull 应用按 `(lamport, origin)` 裁决、重放幂等。
- **TaskRepository**(`task_repository.dart`):唯一写路径。每次写 = 一个事务:领域校验(状态变更必须走 `transition()` —— 领域红线)→ lamport +1 → 行更新 + 字段级 oplog 追加 + 镜像更新。值未变化的字段不产生 op。
- **DriftLocalSyncStore**(`local_sync_store.dart`):实现 `agendum_sync` 的 `LocalSyncStore` —— oplog 队列、游标、时钟持久化、远端 op 的字段级 LWW 应用(胜出落地实体表;未知字段/实体前向兼容跳过)。
- 字段白名单与类型标签(`task_fields.dart`):`date` = epoch days、`ms` = epoch ms;非空列(`title/status/sort_key`)的远端 del 保持原值仅推进行级同步列。

## 视图数据流

视图缓存不订阅 drift watch 流(drift watch 依赖真实事件循环,在 widget 测试的 FakeAsync zone 不可达),由明确刷新点驱动:本地写后、`SyncEngine.onRemoteApplied` 后。透视查询提供 `inboxSnapshot()` / `todaySnapshot()` 一次性快照。

## 已知 PoC 简化(S06+ 收敛)

- 仅 `tasks` 实体;Project/Area/Tag 随 S06 视图扩展落地(外键约束一并补)。
- 行缺失时收到单字段 op 会先建桩行(title 置空)—— 快照/补拉边界的兜底。
- sort_key 用 fractional indexing 追加,重排压缩策略随 S07 拖拽排序实现。

## 开发

改表结构后:`dart run build_runner build --delete-conflicting-outputs`(packages/db 目录下),并递增 `AgendumDatabase.schemaVersion` 与迁移逻辑。

```bash
flutter test   # 本包测试(NativeDatabase.memory(),宿主 macOS 用系统 libsqlite3)
```
