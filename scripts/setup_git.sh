#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CHEZMOI_DIR="${ROOT_DIR}/chezmoi"
mkdir -p "${CHEZMOI_DIR}" "${CHEZMOI_DIR}/dot_ssh" "${CHEZMOI_DIR}/dot_config/gh"

# ============================================================
# 辅助函数
# ============================================================
ask() {
  local prompt="$1" env_var="$2"
  local val="${(P)env_var:-}"
  if [ -n "${val}" ]; then
    echo "==> ${prompt}: ${val} (来自 \$${env_var})" >&2
    echo "${val}"
  else
    echo -n "${prompt}: " >&2
    read -r val
    if [ -z "${val}" ]; then
      echo "❌ 此项为必填，请通过 \$${env_var} 设置或重新运行" >&2
      exit 1
    fi
    echo "==> ${prompt}: ${val}" >&2
    echo "${val}"
  fi
}

# ============================================================
# 默认身份（内网 / 公司 Git，用于所有仓库）
# ============================================================
echo "──────────────────────────────────────────"
echo "  默认 Git 身份（所有仓库生效）"
echo "──────────────────────────────────────────"
DEFAULT_NAME=$(ask  "用户名 (如 your-name)"               "GIT_NAME")
DEFAULT_EMAIL=$(ask "邮箱   (如 you@example.com)"          "GIT_EMAIL")

# ============================================================
# GitHub 身份（可选，只对 github.com 仓库生效）
# ============================================================
echo ""
echo "──────────────────────────────────────────"
echo "  GitHub 身份配置（可选，回车跳过）"
echo "    仅当 remote 指向 github.com 时覆盖默认身份"
echo "──────────────────────────────────────────"

echo -n "GitHub 用户名 (无则回车跳过): "
read -r GITHUB_USER

if [ -n "${GITHUB_USER}" ]; then
  GITHUB_EMAIL=$(ask  "  GitHub 邮箱"       "GIT_GITHUB_EMAIL")
  GIT_GH_USER=$(ask  "  GitHub CLI (gh) 用户名" "GIT_GH_USER")
  GITHUB_HOST="${GIT_GITHUB_HOST:-github.com}"

  GITHUB_KEY_NAME="${GIT_GITHUB_KEY_NAME:-id_ed25519_github}"
  GITHUB_SSH_KEY="${HOME}/.ssh/${GITHUB_KEY_NAME}"
  GITHUB_GITCONFIG="${HOME}/.gitconfig-github"
else
  echo "==> 跳过 GitHub 身份，所有仓库使用默认身份"
fi

# ============================================================
# Git 全局配置（默认身份）
# ============================================================
git config --global init.defaultBranch main
git config --global core.autocrlf input
git config --global pull.rebase false

git config --global user.name "${DEFAULT_NAME}"
git config --global user.email "${DEFAULT_EMAIL}"

# ============================================================
# GitHub 专属身份（写入独立文件，按需由仓库引用）
# ============================================================
if [ -n "${GITHUB_USER:-}" ]; then
  cat <<EOF > "${GITHUB_GITCONFIG}"
[user]
  name = ${GITHUB_USER}
  email = ${GITHUB_EMAIL}
EOF
  echo "==> 已写入 ${GITHUB_GITCONFIG}"

  # 同时生成一个快捷脚本，方便给任意 GitHub 仓库绑定身份
  cat <<EOF > "${HOME}/.local/bin/git-github"
#!/bin/zsh
# 将当前仓库的 Git 身份切换为 GitHub
git config --local include.path "${GITHUB_GITCONFIG}"
echo "==> 已为 \$(pwd) 绑定 GitHub 身份 (\$(git config user.name) / \$(git config user.email))"
EOF
  chmod +x "${HOME}/.local/bin/git-github"
  echo "==> 已安装 git-github 快捷命令"

  # 为当前仓库（如果 remote 指向 github.com）自动绑定
  if git remote get-url origin 2>/dev/null | grep -q 'github\.com'; then
    git config --local include.path "${GITHUB_GITCONFIG}"
    echo "==> 已为当前仓库自动绑定 GitHub 身份"
  fi
fi

# ============================================================
# SSH 密钥
# ============================================================
mkdir -p "${HOME}/.ssh"
chmod 700 "${HOME}/.ssh"

# 默认 SSH Key
DEFAULT_KEY_NAME="${GIT_DEFAULT_KEY_NAME:-id_ed25519}"
DEFAULT_SSH_KEY="${HOME}/.ssh/${DEFAULT_KEY_NAME}"
if [ ! -f "${DEFAULT_SSH_KEY}" ]; then
  echo "==> 生成默认 SSH Key: ${DEFAULT_SSH_KEY}"
  ssh-keygen -t ed25519 -C "${DEFAULT_EMAIL}" -f "${DEFAULT_SSH_KEY}" -N ""
  echo "    ⚠️  请将以下公钥添加到对应 Git 平台:"
  echo "    ---"
  cat "${DEFAULT_SSH_KEY}.pub"
  echo "    ---"
else
  echo "==> 默认 SSH Key 已存在: ${DEFAULT_SSH_KEY}"
fi
ssh-add --apple-use-keychain "${DEFAULT_SSH_KEY}" 2>/dev/null || ssh-add "${DEFAULT_SSH_KEY}" 2>/dev/null || true

# GitHub SSH Key（独立的 key）
if [ -n "${GITHUB_USER:-}" ] && [ ! -f "${GITHUB_SSH_KEY}" ]; then
  echo "==> 生成 GitHub SSH Key: ${GITHUB_SSH_KEY}"
  ssh-keygen -t ed25519 -C "${GITHUB_EMAIL}" -f "${GITHUB_SSH_KEY}" -N ""
  echo "    ⚠️  请将以下公钥添加到 https://github.com/settings/keys"
  echo "    ---"
  cat "${GITHUB_SSH_KEY}.pub"
  echo "    ---"
elif [ -n "${GITHUB_USER:-}" ]; then
  echo "==> GitHub SSH Key 已存在: ${GITHUB_SSH_KEY}"
fi
if [ -n "${GITHUB_USER:-}" ]; then
  ssh-add --apple-use-keychain "${GITHUB_SSH_KEY}" 2>/dev/null || ssh-add "${GITHUB_SSH_KEY}" 2>/dev/null || true
fi

# ============================================================
# SSH config
# ============================================================
SSH_CONFIG="${HOME}/.ssh/config"
cat <<EOF > "${SSH_CONFIG}"
Host *
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile ${DEFAULT_SSH_KEY}
EOF
if [ -n "${GITHUB_USER:-}" ]; then
  cat <<EOF >> "${SSH_CONFIG}"

Host ${GITHUB_HOST}
  HostName ${GITHUB_HOST}
  User git
  IdentityFile ${GITHUB_SSH_KEY}
EOF
fi
chmod 600 "${SSH_CONFIG}"
echo "==> 已写入 ${SSH_CONFIG}"

# ============================================================
# chezmoi 模板
# ============================================================
cat <<'EOF' > "${CHEZMOI_DIR}/dot_gitconfig.tmpl"
[user]
  name = {{ .git.name }}
  email = {{ .git.email }}
[init]
  defaultBranch = main
[core]
  autocrlf = input
[pull]
  rebase = false
[credential]
  helper = osxkeychain
{{- if .git.githubUser }}

# GitHub 仓库自动切换身份
[includeIf "hasconfig:remote.*.url:git@{{ .git.githubHost | default "github.com" }}:**"]
  path = ~/.gitconfig-github
{{- end }}
EOF

cat <<'EOF' > "${CHEZMOI_DIR}/dot_gitconfig-github.tmpl"
[user]
  name = {{ .git.githubUser }}
  email = {{ .git.githubEmail }}
EOF

cat <<'EOF' > "${CHEZMOI_DIR}/dot_ssh/config.tmpl"
Host *
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile ~/.ssh/{{ .git.defaultKeyName | default "id_ed25519" }}
{{- if .git.githubUser }}

Host {{ .git.githubHost | default "github.com" }}
  HostName {{ .git.githubHost | default "github.com" }}
  User git
  IdentityFile ~/.ssh/{{ .git.githubKeyName | default "id_ed25519_github" }}
{{- end }}
EOF

cat <<'EOF' > "${CHEZMOI_DIR}/dot_config/gh/hosts.yml.tmpl"
github.com:
    user: {{ .git.ghUser }}
    git_protocol: ssh
EOF

# ============================================================
echo ""
echo "==> Git 与 SSH 配置完成"
echo ""
echo "📋 下一步："
echo "   1. 将 ~/.ssh/${DEFAULT_KEY_NAME}.pub 添加到内网 Git 平台"
if [ -n "${GITHUB_USER:-}" ]; then
  echo "   2. 将 ~/.ssh/${GITHUB_KEY_NAME}.pub 添加到 https://github.com/settings/keys"
  echo "   3. 测试: ssh -T git@${GITHUB_HOST}"
  echo ""
  echo "🔀 GitHub 身份绑定："
  echo "   克隆 GitHub 仓库后，进入目录执行: git-github"
  echo "   或手动: git config --local include.path ~/.gitconfig-github"
fi
echo ""
echo "💡 非交互模式（CI / 自动化）："
echo "   GIT_NAME=your-name GIT_EMAIL=you@corp.example.com \\"
echo "   GIT_GITHUB_EMAIL=you@gmail.com GIT_GH_USER=your-gh \\"
echo "   make git"
