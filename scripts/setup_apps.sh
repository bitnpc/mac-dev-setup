#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

eval "$("$(brew --prefix)"/bin/brew shellenv)"

echo "==> 安装 Brewfile 中定义的 GUI 应用与字体"
brew bundle install --file="${ROOT_DIR}/Brewfile" --no-upgrade

echo "==> 若包含 Mac App Store 应用，请手动使用 mas 登录并执行：mas install <app_id>"

