#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CHEZMOI_DIR="${ROOT_DIR}/chezmoi"
mkdir -p "${CHEZMOI_DIR}"

eval "$("$(brew --prefix)"/bin/brew shellenv)"

PYTHON_VERSION="${PYTHON_VERSION:-3.11.6}"
RUBY_VERSION="${RUBY_VERSION:-3.2.2}"
NODE_VERSION="${NODE_VERSION:-20}"

echo "==> 配置 Python（pyenv）"
if command -v pyenv >/dev/null 2>&1; then
  if ! pyenv versions --bare | grep -qx "${PYTHON_VERSION}"; then
    CFLAGS="-I$(xcrun --show-sdk-path)/usr/include" pyenv install "${PYTHON_VERSION}"
  fi
  pyenv global "${PYTHON_VERSION}"
  if command -v pipx >/dev/null 2>&1; then
    echo "pipx 已安装"
  else
    python3 -m pip install --user pipx
    python3 -m pipx ensurepath
  fi
else
  echo "未安装 pyenv，跳过 Python 配置" >&2
fi

echo "==> 配置 Ruby（rbenv）"
if command -v rbenv >/dev/null 2>&1; then
  if ! rbenv versions --bare | grep -qx "${RUBY_VERSION}"; then
    RUBY_CONFIGURE_OPTS="--with-openssl-dir=$(brew --prefix openssl@3)" rbenv install "${RUBY_VERSION}"
  fi
  rbenv global "${RUBY_VERSION}"
  gem install --no-document bundler cocoapods
else
  echo "未安装 rbenv，跳过 Ruby 配置" >&2
fi

echo "==> 配置 Node.js（Volta & nvm）"
if command -v volta >/dev/null 2>&1; then
  export VOLTA_HOME="${HOME}/.volta"
  mkdir -p "${VOLTA_HOME}"
  export PATH="${VOLTA_HOME}/bin:${PATH}"
  volta install "node@${NODE_VERSION}"
  volta install pnpm
fi

echo "==> 配置 Go / Rust / asdf"
if command -v go >/dev/null 2>&1; then
  mkdir -p "${HOME}/go/bin"
  if [ ! -f "${CHEZMOI_DIR}/dot_zshrc.local.tmpl" ]; then
    cat <<'EOF' > "${CHEZMOI_DIR}/dot_zshrc.local.tmpl"
export GOPATH="$HOME/go"
export GOBIN="$GOPATH/bin"
export PATH="$GOBIN:$PATH"
EOF
  fi
else
  echo "未安装 Go，可通过 Brewfile 安装" >&2
fi

if command -v rustup-init >/dev/null 2>&1 && ! command -v rustup >/dev/null 2>&1; then
  rustup-init -y --no-modify-path
  source "${HOME}/.cargo/env"
fi
if command -v rustup >/dev/null 2>&1; then
  rustup toolchain install stable
  rustup component add rustfmt clippy
else
  echo "未安装 rustup，请先运行 make brew 安装 rustup-init" >&2
fi

cat <<EOF > "${CHEZMOI_DIR}/dot_tool-versions.tmpl"
ruby ${RUBY_VERSION}
nodejs ${NODE_VERSION}
python ${PYTHON_VERSION}
EOF

echo "==> 语言运行时配置完成"

