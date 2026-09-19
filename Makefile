# 程簿（Agendum）monorepo 任务编排 —— 使用方式见 02 文档 §9。
# 纯 Dart 包用 dart 工具链；Flutter 包（apps/client）用 flutter 工具链。
MEMBERS := packages/domain packages/protocol packages/sync packages/nlp apps/server apps/demo tools/eval

.PHONY: bootstrap analyze test fmt fmt-check eval ci up down demo demo-build flutter-check clean

bootstrap: ## 解析整个工作区（含 Flutter 包，pub workspaces）
	flutter pub get

analyze: ## 静态分析（工作区含 Flutter 包后统一用 flutter 工具链）
	@for p in $(MEMBERS); do echo "▸ analyze $$p"; (cd $$p && flutter analyze --fatal-infos) || exit 1; done

test: ## 单测（flutter test 兼容纯 Dart 包）
	@for p in $(MEMBERS); do echo "▸ test $$p"; (cd $$p && flutter test) || exit 1; done

flutter-check: ## Flutter 客户端分析与测试
	cd apps/client && flutter analyze --fatal-infos && flutter test

fmt: ## 格式化全部代码
	dart format . && flutter format apps/client 2>/dev/null || dart format apps/client

fmt-check: ## CI 用：仅检查格式
	dart format --output=none --set-exit-if-changed .

eval: ## 本地跑黄金评估集（replay/本地适配器，零 API 成本）
	dart run tools/eval/bin/eval.dart run --engine parse --min 0.75

ci: fmt-check analyze test eval flutter-check ## 本地复现 PR-CI

demo-build: ## dart2js 编译 Web 演示页
	dart compile js apps/demo/web/main.dart -o apps/demo/web/main.dart.js -O2

demo: demo-build ## 编译并本地起演示页（http://localhost:8181）
	dart run apps/demo/tool/serve.dart

up: ## 启动本地依赖（Postgres，宿主机 5433）
	docker compose up -d

down:
	docker compose down -v

clean:
	dart pub get --offline >/dev/null 2>&1 || true
	@find . -name build -type d -prune -exec rm -rf {} + 2>/dev/null || true
