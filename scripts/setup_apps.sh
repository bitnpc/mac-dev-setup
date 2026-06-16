#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# 确保 brew 在当前 shell 中可用
if ! command -v brew >/dev/null 2>&1; then
  for bp in /opt/homebrew /usr/local; do
    [ -x "${bp}/bin/brew" ] && eval "$("${bp}/bin/brew" shellenv)" && break
  done
fi

echo "==> 安装 Brewfile 中定义的 GUI 应用与字体"
brew bundle install --file="${ROOT_DIR}/Brewfile" --no-upgrade

echo "==> 若包含 Mac App Store 应用，请手动使用 mas 登录并执行：mas install <app_id>"

