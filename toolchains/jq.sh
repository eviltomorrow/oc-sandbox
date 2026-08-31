#!/usr/bin/env bash
# 按需安装 jq：官方静态二进制 → ~/.local/opt/jq（oc-home 卷，重启保留）
# 用法: oc install jq [版本, 默认最新 release]
set -euo pipefail

# 幂等检查：只认 oc install 自己装的路径（避免误判系统自带 jq）
if [[ -x "$HOME/.local/opt/jq" ]]; then
  echo "jq 已安装: $("$HOME/.local/opt/jq" --version)"
  exit 0
fi

VERSION="${1:-latest}"
if [[ "$VERSION" == "latest" ]]; then
  VERSION="$(curl -fsSL https://api.github.com/repos/jqlang/jq/releases/latest \
    | grep -oP '"tag_name":\s*"\K[^"]+' | sed 's/^jq-//')"
fi
ARCH="$(uname -m)"; [[ "$ARCH" == "x86_64" ]] && ARCH=amd64
URL="https://github.com/jqlang/jq/releases/download/jq-${VERSION}/jq-linux-${ARCH}"

mkdir -p "$HOME/.local/opt" "$HOME/.ocbox"

curl -fsSL "$URL" -o "$HOME/.local/opt/jq"
chmod +x "$HOME/.local/opt/jq"

grep -q '\.local/opt:$PATH' "$HOME/.ocbox/env.sh" 2>/dev/null \
  || echo 'export PATH="$HOME/.local/opt:$PATH"' >> "$HOME/.ocbox/env.sh"

echo "jq 安装完成:"
"$HOME/.local/opt/jq" --version
