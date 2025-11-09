#!/bin/zsh
set -euo pipefail

commands=(
  "xcode-select --print-path"
  "brew doctor"
  "git --version"
  "python3 --version"
  "pyenv versions"
  "node --version"
  "volta list all"
  "docker info"
)

for cmd in "${commands[@]}"; do
  echo "==> ${cmd}"
  if ! eval "${cmd}"; then
    echo "命令执行失败：${cmd}" >&2
  fi
done

