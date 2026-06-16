#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# 确保 brew 在当前 shell 中可用
if ! command -v brew >/dev/null 2>&1; then
  for bp in /opt/homebrew /usr/local; do
    [ -x "${bp}/bin/brew" ] && eval "$("${bp}/bin/brew" shellenv)" && break
  done
fi
BREW_PREFIX="$(brew --prefix)"
ZSHRC="${HOME}/.zshrc"

echo "==> 安装 iTerm2 / Oh My Zsh / 插件 / Starship"

if [ ! -d "${HOME}/.oh-my-zsh" ]; then
  export RUNZSH=no
  export CHSH=no
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
  echo "Oh My Zsh 已安装，跳过"
fi

touch "${ZSHRC}"

if ! grep -q '自动追加：插件与 Starship' "${ZSHRC}" 2>/dev/null; then
  cat <<EOF >> "${ZSHRC}"

# 自动追加：插件与 Starship
source ${BREW_PREFIX}/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source ${BREW_PREFIX}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
eval "\$(starship init zsh)"
EOF
else
  echo ".zshrc 已包含 Starship 与插件配置，跳过追加"
fi

echo "==> Shell 配置完成，可使用 chezmoi 应用 dotfiles"

