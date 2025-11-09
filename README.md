# macOS 开发环境自动化

根据《macOS 开发环境配置》文章整理的自动化脚本，支持通过 `Makefile`、`Brewfile`、Ansible 与 chezmoi 快速复现开发机。

## 目录结构

- `Makefile`：统一入口，按阶段执行。
- `Brewfile`：CLI、语言运行时、GUI 应用与字体清单。
- `scripts/`：细分步骤脚本。
- `ansible/`：可选的 Ansible Playbook。
- `chezmoi/`：dotfiles 模板，可按需扩展。

## 使用方式

```bash
cd automation/mac-dev-setup
make bootstrap     # 检查 Xcode CLT、安装 Homebrew
make brew          # 安装 Brewfile 中的依赖
make shell         # 配置 iTerm2 / Oh My Zsh / Starship
make languages     # 配置 Python / Ruby / Node / Go / Rust
make git           # 初始化 Git / SSH / 凭证模板
make containers    # 启动 Colima / Podman
make apps          # 安装图形应用与字体
make validate      # 运行自检命令
```

### Ansible

如需统一在多台机器执行：

```bash
make ansible
```

Ansible 会复用 `Brewfile` 与 chezmoi dotfiles。运行时需准备：

- 管理员权限（`--ask-become-pass`）
- 已安装 `ansible` 与 `chezmoi`

### chezmoi

`make chezmoi` 将 dotfiles 模板应用到当前用户目录。可通过 `chezmoi apply --dry-run` 预览变更。

如需自定义 Git 信息，可在 `chezmoi` 数据文件中设置：

```bash
chezmoi edit ~/.config/chezmoi/chezmoi.toml
# 添加数据字段
[data.git]
name = "Tony"
email = "tony@example.com"
ghUser = "tony-gh"
```

## 常见变量

- `PYTHON_VERSION`、`RUBY_VERSION`、`NODE_VERSION`：运行 `make languages` 前可覆盖，指定版本。
- `GIT_AUTHOR_NAME`、`GIT_AUTHOR_EMAIL`：运行 `make git` 前覆盖，可直接写入 `git config --global`。

## 注意事项

- App Store 应用需先使用 `mas login`。
- Docker Desktop 第一次运行需手动同意授权。
- 若网络受限，请预先设置代理或替换 Brew 镜像。

