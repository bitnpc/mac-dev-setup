#!/bin/zsh
set -euo pipefail

echo "==> 检查 Xcode Command Line Tools"
if ! xcode-select --print-path >/dev/null 2>&1; then
  echo "未检测到 Command Line Tools，开始安装..."
  xcode-select --install || true
  echo "请在安装完成后重新运行 make bootstrap"
  exit 1
else
  echo "Command Line Tools 已安装：$(xcode-select --print-path)"
fi

echo "==> 检查 Homebrew"
if ! command -v brew >/dev/null 2>&1; then
  echo "未检测到 Homebrew，开始安装..."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

BREW_PREFIX="$(brew --prefix)"
PROFILE_FILE="${HOME}/.zprofile"

if ! grep -q 'brew shellenv' "${PROFILE_FILE}" 2>/dev/null; then
  echo "==> 将 Homebrew shellenv 写入 ${PROFILE_FILE}"
  mkdir -p "$(dirname "${PROFILE_FILE}")"
  {
    echo ''
    echo '# Homebrew 环境变量'
    echo "eval \"\$(${BREW_PREFIX}/bin/brew shellenv)\""
  } >> "${PROFILE_FILE}"
fi

eval "$(${BREW_PREFIX}/bin/brew shellenv)"

echo "==> Homebrew 版本：$(brew --version | head -n1)"

