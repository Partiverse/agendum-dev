#!/usr/bin/env bash
# 用法: test-one.sh <package-dir>... —— 逐包 flutter test,任一失败即非零退出
set -uo pipefail
cd "$(dirname "$0")/../.."
. tools/wf/env.sh
rc=0
for p in "$@"; do
  echo "== $p =="
  (cd "$p" && flutter test) || rc=1
done
exit $rc
