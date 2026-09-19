# 程簿（Agendum）monorepo 任务编排 —— 使用方式见 02 文档 §9。
MEMBERS := packages/domain packages/protocol packages/sync packages/nlp apps/server tools/eval

.PHONY: bootstrap analyze test fmt fmt-check eval ci up down clean

bootstrap: ## 解析整个工作区（pub workspaces，无需 melos）
	dart pub get

analyze: ## 全工作区静态分析
	@for p in $(MEMBERS); do echo "▸ analyze $$p"; dart analyze --fatal-infos $$p || exit 1; done

test: ## 全工作区单测（make test 全绿 = W1 验收标准）
	@for p in $(MEMBERS); do echo "▸ test $$p"; dart test $$p || exit 1; done

fmt: ## 格式化全部代码
	dart format .

fmt-check: ## CI 用：仅检查格式
	dart format --output=none --set-exit-if-changed .

eval: ## 本地跑黄金评估集（replay/本地适配器，零 API 成本）
	dart run tools/eval/bin/eval.dart run --engine parse --min 0.75

ci: fmt-check analyze test eval ## 本地复现 PR-CI

up: ## 启动本地依赖（Postgres）
	docker compose up -d

down:
	docker compose down -v

clean:
	dart pub get --offline >/dev/null 2>&1 || true
	@find . -name build -type d -prune -exec rm -rf {} + 2>/dev/null || true
