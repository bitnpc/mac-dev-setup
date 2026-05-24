SHELL := /bin/zsh

.PHONY: help all bootstrap brew shell languages git containers apps validate ansible chezmoi clean

help:
	@echo "macOS 开发环境自动化"
	@echo
	@echo "可用目标："
	@echo "  all        - 按顺序执行全部配置步骤"
	@echo "  bootstrap  - 检查并安装 Xcode CLT 与 Homebrew"
	@echo "  brew       - 使用 Brewfile 安装 CLI 与应用"
	@echo "  shell      - 安装并配置 iTerm2、Oh My Zsh、插件与 Starship"
	@echo "  languages  - 配置 Python、Ruby、Node.js、Go、Rust 等运行时"
	@echo "  git        - 初始化 Git/SSH 及凭证工具"
	@echo "  containers - 安装 Docker、Colima/Podman 等容器工具"
	@echo "  apps       - 安装常用 GUI 工具与字体"
	@echo "  validate   - 自检核心工具链版本"
	@echo "  ansible    - 运行 Ansible Playbook（需要 sudo）"
	@echo "  chezmoi    - 使用 chezmoi 应用 dotfiles"
	@echo "  clean      - 清理缓存文件"

all: bootstrap brew shell languages git containers apps validate
	@echo "==> 全部配置完成"

bootstrap:
	./scripts/bootstrap.sh

brew:
	./scripts/install_brew_bundle.sh

shell:
	./scripts/setup_shell.sh

languages:
	./scripts/setup_languages.sh

git:
	./scripts/setup_git.sh

containers:
	./scripts/setup_containers.sh

apps:
	./scripts/setup_apps.sh

validate:
	./scripts/validate.sh

ansible:
	ansible-playbook ansible/mac_dev.yml --ask-become-pass

chezmoi:
	chezmoi init --apply --source="$(PWD)/chezmoi"

clean:
	rm -rf .cache
