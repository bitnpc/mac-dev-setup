#!/bin/zsh
set -euo pipefail

# 确保 brew 在当前 shell 中可用
if ! command -v brew >/dev/null 2>&1; then
  for bp in /opt/homebrew /usr/local; do
    [ -x "${bp}/bin/brew" ] && eval "$("${bp}/bin/brew" shellenv)" && break
  done
fi

pass=0
fail=0

check() {
  local label="$1"
  shift
  echo -n "==> ${label}: "
  if output=$(eval "$@" 2>&1); then
    echo "✓ ${output}"
    ((pass++))
  else
    echo "✗ 未通过"
    ((fail++))
  fi
}

check "Xcode CLT"      "xcode-select --print-path"
check "Homebrew"        "brew --version | head -n1"
check "Git"            "git --version"
check "Python"         "python3 --version"
check "pyenv"          "pyenv --version"
check "Ruby"           "ruby --version"
check "rbenv"          "rbenv --version"
check "Node.js"        "node --version"
check "Volta"          "volta --version"
check "Go"             "go version"
check "Rust (rustc)"   "rustc --version"
check "Cargo"          "cargo --version"
check "Docker"         "docker --version"
check "Colima"         "colima status 2>/dev/null || colima version"
check "Podman"         "podman --version"
check "Starship"       "starship --version"
check "chezmoi"        "chezmoi --version"

echo ""
echo "结果：${pass} 通过，${fail} 未通过"
[ "${fail}" -eq 0 ]
