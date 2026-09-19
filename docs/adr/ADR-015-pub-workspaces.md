# ADR-015 · 构建编排采用 Dart pub workspaces，弃用 melos

- 状态：已采纳（2026-09-19，Phase 0 W1 实施时确定）
- 关联：[02-工程架构与规范](../02-工程架构与规范.md) §1/§9、原计划 melos

## 背景

Monorepo 需要统一解析多个 Dart 包。原计划（计划 v1.0）采用 melos 管理。

## 决策

使用 Dart 3.6+ 原生 pub workspaces：根 `pubspec.yaml` 声明 `workspace:` 成员列表，各成员以 `resolution: workspace` 加入；依赖版本由根 `pubspec.lock` 统一锁定并入库。

## 理由

1. **零额外工具**：melos 需 `dart pub global activate`，团队与 CI 各少一个全局依赖与版本漂移源。
2. **解析一致性**：IDE、`dart test`、CI 共享同一份 package_config，杜绝"本地能跑 CI 挂"的解析差异。
3. **跨包依赖即普通依赖**：成员间按包名引用，pub 自动从工作区解析。

## 后果与约束

- 根 `pubspec.yaml` 的 `workspace:` 列表是包注册的唯一入口；新增包须同时更新该列表。
- Flutter 包（`apps/client`、`packages/ui`）在其依赖可用后（Flutter SDK 就绪、S05）才加入工作区，避免破坏解析。
- 触发重审：包数 >12 或需要按包任务编排时评估 melos（见 02 文档 ADR 表）。
