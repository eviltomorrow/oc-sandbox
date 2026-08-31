#!/usr/bin/env bash
# ocbox entrypoint：每次进入容器前加载按需安装的工具链环境。
# oc install 会把 PATH 等写入 /home/dev/.ocbox/env.sh（位于 oc-home 卷，重启保留）。
set -euo pipefail

if [[ -f /home/dev/.ocbox/env.sh ]]; then
  # shellcheck disable=SC1091
  source /home/dev/.ocbox/env.sh
fi

exec "$@"
