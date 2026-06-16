#!/bin/zsh
set -euo pipefail

# 确保 brew 在当前 shell 中可用
if ! command -v brew >/dev/null 2>&1; then
  for bp in /opt/homebrew /usr/local; do
    [ -x "${bp}/bin/brew" ] && eval "$("${bp}/bin/brew" shellenv)" && break
  done
fi

echo "==> 配置容器与虚拟化工具"

if command -v colima >/dev/null 2>&1; then
  if ! colima status >/dev/null 2>&1; then
    echo "启动 Colima..."
    colima start --arch aarch64 --runtime docker --vm-type=vz --mount-type=virtiofs --memory 4 --cpu 4 || true
  else
    echo "Colima 已在运行"
  fi
fi

if command -v podman >/dev/null 2>&1; then
  if ! podman machine info >/dev/null 2>&1; then
    podman machine init --now || true
  else
    echo "Podman machine 已初始化"
  fi
fi

echo "提示：可通过 docker context use colima 将 docker CLI 指向 Colima"

echo "==> 容器工具配置完成"
