# ocbox — opencode 隔离沙箱

在 Docker 容器里运行 [opencode](https://opencode.ai)，agent 的 bash / 文件操作只能碰到你指定的项目目录，宿主其余部分完全隔离。最坏情况 `rm -rf /` 也只是毁掉一个可重建的容器。

## 前置

- Docker 20+（含 Compose v2）
- 构建时需能访问网络（apt 走 TUNA 镜像；装 opencode 走 GitHub，国内需 `INSTALL_PROXY`）

## 构建镜像（`just`，只需一次）

```bash
cd ~/workspace/oc-sandbox
just build                                     # 直连
INSTALL_PROXY=http://192.168.xx.xx:1081 just build   # 走代理装 opencode
```

## 日常使用（`oc`）

```bash
ln -s ~/workspace/oc-sandbox/scripts/oc ~/.local/bin/oc

cd ~/workspace
oc up                       # 交互 TUI（不传目录 = 当前目录）
oc run "重构 main.go"        # 非交互
OC_GIT=1 oc up              # + git push 权限（挂载 ~/.ssh 等）
OC_PROJECT_RO=1 oc up       # 只读审查模式
oc shell                    # 进沙箱 bash 调试工具链
oc doctor                   # 自检 docker/镜像/compose/git 身份
oc init                     # 写入 opencode.json 权限模板
oc env / oc config          # 排查当前生效配置
oc prune [-y]               # 清理不再需要的项目卷（见下）
```

> 同一项目只开一个沙箱：`oc up/run/install` 以项目数据卷名为 key 加 `flock` 锁，
> 第二个会话会直接拒绝启动（避免共享 `opencode.db` / git 锁冲突）。

不传目录时的优先级：显式参数 > `OC_PROJECT` 环境变量 > 当前目录。

## 开关

| 环境变量 | 默认 | 作用 |
|---|---|---|
| `OC_GIT_NAME` / `OC_GIT_EMAIL` | 宿主 `git config --global` 回退 | git 提交身份，每次运行时注入 |
| `OC_GIT=1` | 关 | 挂载宿主 `~/.ssh` + `~/.git-credentials` |
| `OC_CA_MOUNT=1` | 关 | 挂载宿主 CA bundle（公司 GitLab 自签证书） |
| `OC_USE_HOST_CONFIG=1` | 关 | 复用宿主 opencode 配置/会话（勿与宿主 opencode 同跑） |
| `OC_ROOT_RW=1` | 关 | 容器根文件系统可写（一般用不到，见「注意」） |
| `OC_PROJECT_RO=1` | 关 | 项目目录只读 |
| `OC_PROJECT` | 无 | 默认项目目录 |
| `OC_UID` / `OC_GID` | 宿主 uid/gid | 容器内 `dev` 用户 |
| `OC_VERSION` | latest | opencode 版本 |
| `INSTALL_PROXY` | 空 | `just build` / `oc install` 下载时走代理，不烧进镜像 |
| `OC_MEM_LIMIT` | 4g | 容器内存上限 |
| `OC_PIDS_LIMIT` | 256 | 进程数上限（防 fork 炸弹） |

## 按需安装工具链

容器内是 `dev` 用户（无 root），工具链按需装到 `/home/dev`（`oc-home` 卷），**重启保留**，进沙箱自动加载：

```bash
cd ~/workspace
oc install rust              # rustup → ~/.cargo
oc install go                # → ~/.local/opt/go
oc install node              # LTS；也可 oc install node 22
oc install python 3.12       # uv + Python
oc install bun               # → ~/.bun
INSTALL_PROXY=http://192.168.16.140:1081 oc install rust   # 走代理
```

工具链按项目隔离（装在当前项目数据卷）；想全局用的写进 `Dockerfile`（参考 `toolchains/*.sh`）后 `just build`。

## 隔离边界

| 内容 | 位置 | 重启后 |
|---|---|---|
| 项目代码、`.git` | 宿主目录（bind 挂载） | 保留 |
| opencode 会话/认证 | `oc-home-<项目>-<hash>` 卷 | 保留 |
| `oc install` 工具链 | 同上卷内 `~/.cargo`、`~/.local/opt` 等 | 保留（自动加载 PATH） |
| git 全局配置 | 宿主 `~/.gitconfig`（ro） | 保留 |
| opencode skill（自动加载） | 宿主 `~/.agents/skills`、`~/.claude/skills`（ro） | 保留 |
| git 身份 | 环境变量注入 | 每次进入都有 |
| SSH 密钥 / HTTPS 凭据 | 宿主（ro，需 `OC_GIT=1`） | 保留 |
| 容器内装的任何东西（非卷路径） | 容器层 | **丢弃** |

宿主文件系统在容器内不可见（仅 `~/.gitconfig` 与 skill 目录以 ro 方式挂载）；容器根文件系统只读，仅 `/run` 为 tmpfs，`/tmp`、`/home/dev` 为卷。

## 卷与 compose project

- **compose project 名按项目目录派生**（`oc env` 可见）：小写化并过滤到 `[a-z0-9_-]`，
  与 compose 自身的 project 名规范一致。不同目录 = 不同 compose project，互不干扰。
- **数据卷是 `external` 的，由 ocbox 自己管理**：`docker compose` 只负责挂载、不创建不回收。
  每次 `oc up/run/install/shell` 前自动 `docker volume create`（不存在时）。这样卷不带任何
  compose 标签，多个项目之间永远不会触发 compose 的"卷名不匹配/跨项目复用"警告。
- 卷名 = `oc-home-<目录名>-<路径hash>` / `oc-tmp-<目录名>-<路径hash>`，与早期方案保持兼容，
  已有卷会被原样复用、不重建。

### `oc prune [-y]`

清理旧方案（compose project 固定为 `ocbox`）遗留的 `oc-home-*` / `oc-tmp-*` 卷。它们对当前
compose 完全隐身，只占磁盘。`oc prune` 会自动排除**当前项目**自己的卷，交互确认后删除；
非交互环境加 `-y` 跳过确认。判断标准：卷带 `com.docker.compose.project=ocbox` 标签。

## 多项目 / 禁止

- 不同项目可同时跑（各自独立卷 + 挂载；`network_mode: host` 下 TUI/run 不占端口）
- 同一项目自动互斥：`oc up/run/install` 会上锁，第二个会话被拒绝（共享数据卷 → `opencode.db` / git 锁冲突）
- `OC_USE_HOST_CONFIG=1` 时勿与宿主 opencode 同跑

## 注意

- **首次使用**：默认数据隔离，沙箱内 `/connect` 登录一次即写入卷，之后有效。
- **git 身份**：宿主未配 `user.name/email` 时，设 `OC_GIT_NAME` / `OC_GIT_EMAIL`，否则 commit 失败。
- **`OC_ROOT_RW=1`**：`dev` 用户没有 root/sudo，开它也无法 `apt install` 系统包；装用户态工具请用 `oc install`。
- **网络**：`network_mode: host` 直连，宿主到得了的地址容器都能访问；意味着 agent 也能访问宿主所有 localhost 端口（数据库等）——这是文件隔离之外的唯一妥协。
