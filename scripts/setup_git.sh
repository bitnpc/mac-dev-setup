#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CHEZMOI_DIR="${ROOT_DIR}/chezmoi"
mkdir -p "${CHEZMOI_DIR}" "${CHEZMOI_DIR}/dot_ssh" "${CHEZMOI_DIR}/dot_config/gh"

git config --global init.defaultBranch main
git config --global core.autocrlf input
git config --global pull.rebase false

if ! git config --global user.name >/dev/null; then
  DEFAULT_NAME="${GIT_AUTHOR_NAME:-Your Name}"
  git config --global user.name "${DEFAULT_NAME}"
fi

if ! git config --global user.email >/dev/null; then
  DEFAULT_EMAIL="${GIT_AUTHOR_EMAIL:-your_email@example.com}"
  git config --global user.email "${DEFAULT_EMAIL}"
fi

mkdir -p "${HOME}/.ssh"
chmod 700 "${HOME}/.ssh"

if [ ! -f "${HOME}/.ssh/config" ]; then
  cat <<'EOF' > "${HOME}/.ssh/config"
Host *
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile ~/.ssh/id_ed25519
EOF
  chmod 600 "${HOME}/.ssh/config"
fi

if [ ! -f "${CHEZMOI_DIR}/dot_gitconfig.tmpl" ]; then
  cat <<'EOF' > "${CHEZMOI_DIR}/dot_gitconfig.tmpl"
[user]
  name = {{ .git.name | default "Your Name" }}
  email = {{ .git.email | default "your_email@example.com" }}
[init]
  defaultBranch = main
[core]
  autocrlf = input
[pull]
  rebase = false
[credential]
  helper = osxkeychain
EOF
fi

if [ ! -f "${CHEZMOI_DIR}/dot_ssh/config.tmpl" ]; then
  cat <<'EOF' > "${CHEZMOI_DIR}/dot_ssh/config.tmpl"
Host github.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519_github

Host gitlab.internal
  HostName gitlab.internal.company
  User git
  IdentityFile ~/.ssh/id_ed25519_company
EOF
fi

if [ ! -f "${CHEZMOI_DIR}/dot_config/gh/hosts.yml.tmpl" ]; then
  cat <<'EOF' > "${CHEZMOI_DIR}/dot_config/gh/hosts.yml.tmpl"
github.com:
    user: {{ .git.ghUser | default "your-github-username" }}
    git_protocol: https
EOF
fi

echo "==> Git 与 SSH 基础配置完成，请通过 chezmoi data 设置个人信息"

