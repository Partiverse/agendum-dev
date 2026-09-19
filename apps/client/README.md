# apps/client（占位）

Flutter 应用（macOS + iOS 起步，05 文档 Phase 0 → 06 文档 Phase 1）。

## 初始化（需先安装 Flutter SDK 并在 mise.toml 锁定版本）

```sh
flutter create --platforms=ios,macos --org dev.agendum --project-name agendum_client .
```

然后在 pubspec.yaml 加入 `resolution: workspace` 并更新根 workspace 列表。
落地时点：W7–8 风格样板（静态三屏）；S05 起接入真实数据层。
