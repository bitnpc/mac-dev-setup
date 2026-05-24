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
make git           # 初始化 Git / SSH / 凭证模板
make containers    # 启动 Colima / Podman
make apps          # 安装图形应用与字体
make validate      # 运行自检命令
```

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
    ├── dot_tool-versions.tmpl
    ├── dot_ssh/config.tmpl
    └── dot_config/gh/hosts.yml.tmpl
```

## 安装内容

| 类别 | 工具 |
|------|------|
| 版本控制 | git, gh, glab, git-credential-manager |
| 语言运行时 | pyenv, rbenv, volta, go, rustup |
| Shell | Oh My Zsh, zsh-autosuggestions, zsh-syntax-highlighting, starship |
| 容器 | Colima, Podman, Podman Desktop |
| 编辑器 | VS Code, JetBrains Toolbox |
| 效率工具 | Raycast, Hammerspoon |
| 数据库 | TablePlus, Postico, MongoDB Compass |
| 网络调试 | Proxyman, Wireshark |
| 虚拟化 | UTM |
| 字体 | JetBrains Mono Nerd Font, Meslo LG Nerd Font |

## Ansible

如需统一在多台机器执行：

```bash
make ansible
```

Ansible 会复用 `Brewfile` 与 chezmoi dotfiles。运行时需准备：

- 管理员权限（`--ask-become-pass`）
- 已安装 `ansible` 与 `chezmoi`

## chezmoi

`make chezmoi` 将 dotfiles 模板应用到当前用户目录。可通过 `chezmoi apply --dry-run` 预览变更。

如需自定义 Git 信息，编辑 chezmoi 数据文件：

```bash
chezmoi edit-config
# 添加以下内容
[data.git]
name = "Your Name"
email = "your_email@example.com"
ghUser = "your-github-username"
```

## 常见变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `PYTHON_VERSION` | 3.11.6 | Python 版本 |
| `RUBY_VERSION` | 3.2.2 | Ruby 版本 |
| `NODE_VERSION` | 20 | Node.js 主版本 |
| `GIT_AUTHOR_NAME` | - | Git 用户名 |
| `GIT_AUTHOR_EMAIL` | - | Git 邮箱 |

示例：

```bash
PYTHON_VERSION=3.12.4 NODE_VERSION=22 make languages
```

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

### Docker 无法启动

Colima 与 Docker Desktop 可能冲突，建议选择其一：

```bash
# 使用 Colima（轻量）
colima start
# 或使用 Docker Desktop（图形界面）
open /Applications/Docker.app
```

### SSH key 配置

脚本创建了 SSH config 模板，还需手动生成密钥：

```bash
ssh-keygen -t ed25519 -C "your_email@example.com" -f ~/.ssh/id_ed25519
# 添加到 ssh-agent
ssh-add --apple-use-keychain ~/.ssh/id_ed25519
```

## 注意事项

- App Store 应用需先使用 `mas signin`。
- Docker Desktop 第一次运行需手动同意授权。
- `make validate` 可随时运行来检查环境健康状态。
- 所有脚本均支持幂等执行（重复运行安全）。
