#!/usr/bin/env bash
# 完整 make ci(与 PR-CI 等价的本地闸门)
set -uo pipefail
cd "$(dirname "$0")/../.."
. tools/wf/env.sh
exec make ci
