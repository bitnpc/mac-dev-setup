#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CHEZMOI_DIR="${ROOT_DIR}/chezmoi"
mkdir -p "${CHEZMOI_DIR}"

# 确保 brew 在当前 shell 中可用
if ! command -v brew >/dev/null 2>&1; then
  for bp in /opt/homebrew /usr/local; do
    [ -x "${bp}/bin/brew" ] && eval "$("${bp}/bin/brew" shellenv)" && break
  done
fi

PYTHON_VERSION="${PYTHON_VERSION:-3.11.6}"
RUBY_VERSION="${RUBY_VERSION:-3.2.2}"
NODE_VERSION="${NODE_VERSION:-20}"

echo "==> 配置 Python（pyenv）"
if command -v pyenv >/dev/null 2>&1; then
  # 初始化 pyenv shims，确保 python3/pip 指向 pyenv 版本而非系统 Python
  eval "$(pyenv init - zsh)"
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
  # 初始化 rbenv shims，确保 gem/ruby 指向 rbenv 版本而非系统 Ruby
  eval "$(rbenv init - zsh)"
  if ! rbenv versions --bare | grep -qx "${RUBY_VERSION}"; then
    RUBY_CONFIGURE_OPTS="--with-openssl-dir=$(brew --prefix openssl@3)" rbenv install "${RUBY_VERSION}"
  fi
  rbenv global "${RUBY_VERSION}"
  gem install --no-document bundler cocoapods
else
  echo "未安装 rbenv，跳过 Ruby 配置" >&2
fi

echo "==> 配置 Node.js（Volta）"
if command -v volta >/dev/null 2>&1; then
  export VOLTA_HOME="${HOME}/.volta"
  mkdir -p "${VOLTA_HOME}"
  export PATH="${VOLTA_HOME}/bin:${PATH}"

  # volta 偶发 EAGAIN (os error 35)，加重试
  for tool in "node@${NODE_VERSION}" pnpm; do
    for i in 1 2 3; do
      rm -rf "${VOLTA_HOME}/tmp"
      mkdir -p "${VOLTA_HOME}/tmp"
      if volta install "${tool}" 2>/dev/null; then
        break
      fi
      if [ "$i" -eq 3 ]; then
        echo "❌ volta install ${tool} 重试 3 次均失败" >&2
        volta install "${tool}"  # 最后一次输出完整错误
      fi
      echo "==> ${tool} 安装失败，5 秒后重试 ($i/3)..."
      sleep 5
    done
  done
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

