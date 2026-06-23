# macOS 开发环境自动化

根据《macOS 开发环境配置》文章整理的自动化脚本，支持通过 `Makefile`、`Brewfile`、Ansible 与 chezmoi 快速复现开发机。

## 前置条件

- macOS 13 (Ventura) 或更高版本
- Apple Silicon (M1/M2/M3/M4) 或 Intel Mac
- 管理员权限
- 网络连接（部分依赖需从 GitHub 下载）

## 快速开始

```bash
git clone <repo-url> ~/mac-dev-setup && cd ~/mac-dev-setup
make all
```

以上命令将按顺序执行全部配置步骤。也可分步执行：

```bash
make bootstrap     # 检查 Xcode CLT、安装 Homebrew
make brew          # 安装 Brewfile 中的依赖
make shell         # 配置 iTerm2 / Oh My Zsh / Starship
make languages     # 配置 Python / Ruby / Node / Go / Rust
make git           # 初始化 Git 双身份 / SSH / GitHub CLI（交互式）
make containers    # 启动 Podman Desktop
make apps          # 安装图形应用与字体
make validate      # 运行自检命令
```

> **注意**：`make git` 为交互式步骤，会提示输入用户名和邮箱。如需非交互模式（CI/自动化），见下方 [Git 配置](#git-配置) 章节。

## 目录结构

```
mac-dev-setup/
├── Makefile          # 统一入口，按阶段执行
├── Brewfile          # CLI、语言运行时、GUI 应用与字体清单
├── scripts/          # 细分步骤脚本
│   ├── bootstrap.sh
│   ├── install_brew_bundle.sh
│   ├── setup_shell.sh
│   ├── setup_languages.sh
│   ├── setup_git.sh
│   ├── setup_containers.sh
│   ├── setup_apps.sh
│   └── validate.sh
├── ansible/          # 可选的 Ansible Playbook
│   └── mac_dev.yml
└── chezmoi/          # dotfiles 模板，可按需扩展
    ├── dot_zshrc.tmpl
    ├── dot_zshrc.local.tmpl
    ├── dot_zprofile.tmpl
    ├── dot_gitconfig.tmpl
    ├── dot_gitconfig-github.tmpl
    ├── dot_tool-versions.tmpl
    ├── dot_ssh/config.tmpl
    └── dot_config/gh/hosts.yml.tmpl
```

## 安装内容

| 类别 | 工具 |
|------|------|
| 版本控制 | git, gh, glab, Fork (Git GUI) |
| 语言运行时 | pyenv, pyenv-virtualenv, rbenv, volta, go, rustup, pipx |
| Shell | Oh My Zsh, zsh-autosuggestions, zsh-syntax-highlighting, starship |
| 容器 | Podman Desktop (含 podman CLI) |
| 编辑器 | VS Code, JetBrains Toolbox |
| 浏览器 | Google Chrome |
| 效率工具 | Raycast, Hammerspoon |
| 数据库 | TablePlus, Postico, MongoDB Compass |
| 网络调试 | Proxyman, Wireshark |
| 虚拟化 | UTM |
| 字体 | JetBrains Mono Nerd Font, Meslo LG Nerd Font |

## Git 配置

`make git` 提供交互式引导，支持**双身份配置**：

- **默认身份**（必填）— 所有仓库生效，通常为公司/内网 Git 身份
- **GitHub 身份**（可选）— 仅对 `github.com` 仓库生效，`git clone` 时自动检测并绑定

### 交互模式

直接运行，按提示输入：

```bash
make git
```

### 非交互模式（CI / 自动化）

通过环境变量跳过交互：

```bash
GIT_NAME="Your Name" \
GIT_EMAIL="you@corp.example.com" \
GIT_GITHUB_EMAIL="you@gmail.com" \
GIT_GH_USER="your-gh-username" \
make git
```

> 不设置 `GIT_GITHUB_EMAIL` / `GIT_GH_USER` 则跳过 GitHub 身份配置，所有仓库使用默认身份。

### 工作原理

| 机制 | 说明 |
|------|------|
| 全局 `user.name` / `user.email` | 默认身份，所有仓库生效 |
| `~/.gitconfig-github` | GitHub 身份文件，包含独立的 `user.name` / `user.email` |
| `init.templateDir` + post-checkout hook | `git clone` 时自动检测 remote 是否指向 `github.com`，如果是则通过 `include.path` 绑定 GitHub 身份 |
| 独立 SSH Key | 默认 key (`id_ed25519`) + GitHub key (`id_ed25519_github`)，SSH config 自动按 Host 匹配 |

## 常见变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `PYTHON_VERSION` | 3.11.6 | Python 版本 |
| `RUBY_VERSION` | 3.2.2 | Ruby 版本 |
| `NODE_VERSION` | 20 | Node.js 主版本 |
| `GIT_NAME` | - | Git 默认用户名 |
| `GIT_EMAIL` | - | Git 默认邮箱 |
| `GIT_GITHUB_EMAIL` | - | GitHub 邮箱（可选，不设则跳过） |
| `GIT_GH_USER` | - | GitHub CLI (gh) 用户名（可选） |
| `GIT_GITHUB_HOST` | github.com | GitHub 主机名 |
| `GIT_DEFAULT_KEY_NAME` | id_ed25519 | 默认 SSH Key 文件名 |
| `GIT_GITHUB_KEY_NAME` | id_ed25519_github | GitHub SSH Key 文件名 |

示例：

```bash
PYTHON_VERSION=3.12.4 NODE_VERSION=22 make languages
```

## chezmoi

`make chezmoi` 将 dotfiles 模板应用到当前用户目录。可通过 `chezmoi apply --dry-run` 预览变更。

Git 模板所需的数据字段：

```bash
chezmoi edit-config
```

```toml
[data.git]
name = "Your Name"
email = "your_email@example.com"
githubUser = "your-github-username"     # 可选
githubEmail = "you@gmail.com"           # 可选
ghUser = "your-github-username"         # 可选（gh CLI）
defaultKeyName = "id_ed25519"           # 可选
githubKeyName = "id_ed25519_github"     # 可选
githubHost = "github.com"               # 可选
```

## Ansible

如需统一在多台机器执行：

```bash
make ansible
```

Ansible 会复用 `Brewfile` 与 chezmoi dotfiles。运行时需准备：

- 管理员权限（`--ask-become-pass`）
- 已安装 `ansible` 与 `chezmoi`

## 故障排除

### Homebrew 安装失败

若网络受限，设置代理后重试：

```bash
export https_proxy=http://127.0.0.1:7890
make bootstrap
```

或使用国内镜像：

```bash
export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git"
export HOMEBREW_CORE_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git"
export HOMEBREW_API_DOMAIN="https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles/api"
export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles"
```

### pyenv install 失败

确保已安装 Xcode CLT 并更新 SDK headers：

```bash
xcode-select --install
```

### Colima / Podman 无法启动

Podman Desktop 自带 podman CLI，无需单独安装。若与 Docker Desktop 冲突，建议选择其一：

```bash
# 使用 Podman Desktop（推荐）
open /Applications/Podman\ Desktop.app
# 或使用 Docker Desktop
open /Applications/Docker.app
```

### SSH 密钥

脚本会自动生成两把 SSH Key（若不存在）：

- `~/.ssh/id_ed25519` — 默认密钥，添加到内网 Git 平台
- `~/.ssh/id_ed25519_github` — GitHub 专用密钥，添加到 https://github.com/settings/keys

也可手动生成：

```bash
ssh-keygen -t ed25519 -C "your_email@example.com" -f ~/.ssh/id_ed25519
ssh-add --apple-use-keychain ~/.ssh/id_ed25519
```

### 验证 GitHub 身份自动切换

克隆任意 GitHub 仓库后，检查本地配置是否已自动绑定：

```bash
git clone git@github.com:some/repo.git
cd repo
git config --local include.path
# 应输出: ~/.gitconfig-github
```

## 注意事项

- App Store 应用需先使用 `mas signin`。
- Podman Desktop 第一次运行需手动同意授权。
- `make validate` 可随时运行来检查环境健康状态。
- 所有脚本均支持幂等执行（重复运行安全）。
- Volta 安装偶发 EAGAIN 错误时会自动重试 3 次。
