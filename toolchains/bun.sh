#!/usr/bin/env bash
# 按需安装 Bun：官方安装脚本 → ~/.bun（oc-home 卷，重启保留）
set -euo pipefail

if command -v bun >/dev/null 2>&1; then
  echo "bun 已安装: $(bun --version)"
  exit 0
fi

mkdir -p "$HOME/.ocbox"
curl -fsSL https://bun.sh/install | bash

if ! grep -q '.bun/bin' "$HOME/.ocbox/env.sh" 2>/dev/null; then
  echo 'export PATH="$HOME/.bun/bin:$PATH"' >> "$HOME/.ocbox/env.sh"
fi

echo "bun 安装完成: $(PATH="$HOME/.bun/bin:$PATH" bun --version)"
