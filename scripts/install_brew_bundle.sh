#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

eval "$("$(brew --prefix)"/bin/brew shellenv)"

echo "==> 执行 Brew Bundle"
brew bundle install --file="${ROOT_DIR}/Brewfile"

