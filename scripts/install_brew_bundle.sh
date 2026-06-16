#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# 确保 brew 在当前 shell 中可用
if ! command -v brew >/dev/null 2>&1; then
  for bp in /opt/homebrew /usr/local; do
    [ -x "${bp}/bin/brew" ] && eval "$("${bp}/bin/brew" shellenv)" && break
  done
fi

echo "==> 执行 Brew Bundle"
brew bundle install --verbose --file="${ROOT_DIR}/Brewfile"

