# ocbox — 仅用于构建镜像
# 日常使用请直接调用 scripts/oc（建议 alias oc='~/Workspaces/space-rust/sandbox/scripts/oc'）

INSTALL_PROXY := env("INSTALL_PROXY", "")

# 列出可用命令
default:
    @just --list

# 构建镜像（装 opencode 需访问 GitHub 时设 INSTALL_PROXY=http://192.168.16.140:1081）
build:
    docker build -t ocbox:latest --build-arg UID=$(id -u) --build-arg GID=$(id -g) {{ if INSTALL_PROXY != "" { "--build-arg INSTALL_PROXY=" + INSTALL_PROXY } else { "" } }} .
