#!/bin/zsh
set -euo pipefail

eval "$("$(brew --prefix)"/bin/brew shellenv)"

echo "==> 配置容器与虚拟化工具"

if command -v colima >/dev/null 2>&1; then
  colima start --arch aarch64 --runtime docker --vm-type=vz --memory 4 --cpu 4 || true
fi

if command -v podman >/dev/null 2>&1; then
  podman machine init --now || true
fi

if [ -d "/Applications/Docker.app" ]; then
  echo "Docker Desktop 已安装"
else
  echo "请从 Brewfile 安装 docker --cask，或手动打开 Docker 以完成初始化"
fi

echo "==> 容器工具配置完成"

