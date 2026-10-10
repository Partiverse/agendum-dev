#!/usr/bin/env bash
# 起 PG 容器,带 DATABASE_URL 跑 apps/server 测试(PG 裁决路径真实验证)
set -uo pipefail
cd "$(dirname "$0")/../.."
. tools/wf/env.sh
docker compose up -d postgres >/dev/null 2>&1
for i in $(seq 1 20); do
  docker compose exec -T postgres pg_isready -U agendum -d agendum_dev >/dev/null 2>&1 && break
  sleep 1
done
export DATABASE_URL='postgres://agendum:agendum_dev_only@localhost:5433/agendum_dev'
cd apps/server && exec flutter test
