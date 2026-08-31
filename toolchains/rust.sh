#!/usr/bin/env bash
# 按需安装 Rust：rustup → ~/.rustup ~/.cargo（oc-home 卷，重启保留）
set -euo pipefail

if command -v cargo >/dev/null 2>&1; then
  echo "rust 已安装: $(cargo --version) / $(rustc --version)"
  exit 0
fi

export RUSTUP_HOME="$HOME/.rustup"
export CARGO_HOME="$HOME/.cargo"
mkdir -p "$HOME/.ocbox"

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable --no-modify-path

echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> "$HOME/.ocbox/env.sh"

echo "rust 安装完成:"
"$HOME/.cargo/bin/rustc" --version
"$HOME/.cargo/bin/cargo" --version
