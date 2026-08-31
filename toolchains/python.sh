#!/usr/bin/env bash
# 按需安装 Python 工具链：uv（版本管理+包管理，单二进制 → ~/.local/bin）
# 用法: oc install python [版本号, 如 3.12; 不传则仅装 uv]
set -euo pipefail

if ! command -v uv >/dev/null 2>&1; then
  mkdir -p "$HOME/.ocbox"
  curl -LsSf https://astral.sh/uv/install.sh | sh
  if ! grep -q '.local/bin' "$HOME/.ocbox/env.sh" 2>/dev/null; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.ocbox/env.sh"
  fi
fi

if [[ -n "${1:-}" ]]; then
  export PATH="$HOME/.local/bin:$PATH"
  uv python install "$1"
  echo "python 安装完成:"
  uv python list
fi

echo "uv 安装完成: $(PATH="$HOME/.local/bin:$PATH" uv --version)"
