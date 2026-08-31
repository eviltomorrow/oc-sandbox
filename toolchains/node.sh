#!/usr/bin/env bash
# 按需安装 Node.js：官方二进制 → ~/.local/opt/node-vX（oc-home 卷，重启保留）
# 用法: oc install node [lts | 主版本号 | 完整版本, 默认 lts]
set -euo pipefail

ARCH="$(uname -m)"; [[ "$ARCH" == "x86_64" ]] && ARCH=x64

# 幂等检查：只认 oc install 自己装的路径（避免误判系统自带 node）
if ls "$HOME/.local/opt"/node-*/bin/node >/dev/null 2>&1; then
  echo "node 已安装: $("$HOME/.local/opt"/node-*/bin/node --version)"
  exit 0
fi

# 解析 lts / 主版本(v22) / 完整版本(v22.14.0) → 具体 dist 版本目录（如 v22.14.0）
WANT="${1:-lts}"
DIR="$(curl -fsSL https://nodejs.org/dist/index.json | python3 -c "
import sys, json
data = json.load(sys.stdin)
want = sys.argv[1]
if want == 'lts':
    match = next((x['version'] for x in data if x['lts']), None)
elif want.count('.') >= 2:
    match = 'v' + want.lstrip('v')
else:
    match = next((x['version'] for x in data if x['version'].lstrip('v').startswith(want.lstrip('v') + '.')), None)
if not match:
    sys.exit('ocbox: node version not found: ' + want)
print(match)
" "$WANT")"

mkdir -p "$HOME/.local/opt" "$HOME/.ocbox"

curl -fsSL "https://nodejs.org/dist/${DIR}/node-${DIR}-linux-${ARCH}.tar.xz" -o /tmp/node.txz
tar -C "$HOME/.local/opt" -xJf /tmp/node.txz
rm -f /tmp/node.txz

echo "export PATH=\"\$HOME/.local/opt/node-${DIR}-linux-${ARCH}/bin:\$PATH\"" >> "$HOME/.ocbox/env.sh"

echo "node 安装完成:"
"$HOME/.local/opt/node-${DIR}-linux-${ARCH}/bin/node" --version
