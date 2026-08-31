#!/usr/bin/env bash
# 按需安装 Go：官方二进制 → ~/.local/opt/go（oc-home 卷，重启保留）
# 用法: oc install go [版本, 默认 latest]
set -euo pipefail

# 幂等检查：只认 oc install 自己装的路径（避免误判系统自带 go）
if [[ -x "$HOME/.local/opt/go/bin/go" ]]; then
  echo "go 已安装: $("$HOME/.local/opt/go/bin/go" version)"
  exit 0
fi

VERSION="${1:-latest}"
if [[ "$VERSION" == "latest" ]]; then
  VERSION="$(curl -fsSL 'https://go.dev/VERSION?m=text' | head -1 | cut -d' ' -f1)"
fi
ARCH="$(uname -m)"; [[ "$ARCH" == "x86_64" ]] && ARCH=amd64

mkdir -p "$HOME/.local/opt" "$HOME/.ocbox"

curl -fsSL "https://go.dev/dl/${VERSION}.linux-${ARCH}.tar.gz" -o /tmp/go.tgz
tar -C "$HOME/.local/opt" -xzf /tmp/go.tgz
rm -f /tmp/go.tgz

echo 'export PATH="$HOME/.local/opt/go/bin:$PATH"' >> "$HOME/.ocbox/env.sh"
echo 'export GOPATH="$HOME/go"' >> "$HOME/.ocbox/env.sh"

echo "go 安装完成:"
"$HOME/.local/opt/go/bin/go" version
