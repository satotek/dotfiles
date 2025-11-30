#!/bin/bash

set -eu

echo "📦 Installing dependencies..."

# Update package lists
sudo apt update

# Core CLI (always in apt)
echo "Installing core CLI tools (zsh, curl, wget, git, tmux, fzf, ripgrep, fd)..."
sudo apt install -y \
    zsh \
    curl \
    wget \
    git \
    tmux \
    fzf \
  ripgrep \
  fd-find

# Runtime/build deps for Neovim & plugins (treesitter, Mason, markdown-preview, clipboard, AppImage)
echo "Installing Neovim runtime/build dependencies..."
sudo apt install -y \
  build-essential \
  unzip \
  tar \
  xz-utils \
  libfuse2 \
  python3 \
  python3-pip \
  python3-venv \
  nodejs \
  npm \
  pkg-config \
  xclip \
  wl-clipboard

# Install targets may live in /usr/local/bin; if not writable fall back to ~/bin
install_prefix="/usr/local/bin"
if [[ ! -w "$install_prefix" ]]; then
  install_prefix="$HOME/bin"
  mkdir -p "$install_prefix"
fi

ARCH_UNAME="$(uname -m)"

# helper: fetch latest release tag from GitHub
latest_release() {
  # $1 repo path e.g. owner/name
  curl -fsSL "https://api.github.com/repos/$1/releases/latest" | grep '"tag_name"' | head -n1 | cut -d '"' -f 4
}

# lazygit (apt if available; fallback to GitHub release)
echo "Installing lazygit..."
if sudo apt install -y lazygit; then
  :
else
  echo "lazygit not found in apt, using GitHub release..."
  case "$ARCH_UNAME" in
  x86_64) LAZYGIT_ARCH="x86_64" ;;
  aarch64 | arm64) LAZYGIT_ARCH="arm64" ;;
  *)
    echo "Unsupported architecture for lazygit: $ARCH_UNAME"
    exit 1
    ;;
  esac
  LAZYGIT_VERSION="${LAZYGIT_VERSION:-$(latest_release jesseduffield/lazygit)}"
  if [[ -z "$LAZYGIT_VERSION" ]]; then
    LAZYGIT_VERSION="v0.56.0" # fallback
  fi
  LAZYGIT_ASSET="lazygit_${LAZYGIT_VERSION#v}_Linux_${LAZYGIT_ARCH}.tar.gz"
  LAZYGIT_URL="https://github.com/jesseduffield/lazygit/releases/download/${LAZYGIT_VERSION}/${LAZYGIT_ASSET}"
  tmpdir="$(mktemp -d)"
  curl -fsSL "$LAZYGIT_URL" | tar -xz -C "$tmpdir"
  install -m 0755 "$tmpdir/lazygit" "$install_prefix/lazygit"
  rm -rf "$tmpdir"
fi

# git-delta (apt if available; fallback to GitHub release)
echo "Installing git-delta..."
if sudo apt install -y git-delta; then
  :
else
  echo "git-delta not found in apt, using GitHub release..."
  case "$ARCH_UNAME" in
  x86_64) DELTA_ARCH="x86_64-unknown-linux-gnu" ;;
  aarch64 | arm64) DELTA_ARCH="aarch64-unknown-linux-gnu" ;;
  *)
    echo "Unsupported architecture for git-delta: $ARCH_UNAME"
    exit 1
    ;;
  esac
  DELTA_VERSION="${DELTA_VERSION:-$(latest_release dandavison/delta)}"
  if [[ -z "$DELTA_VERSION" ]]; then
    DELTA_VERSION="0.18.1" # fallback
  fi
  DELTA_ASSET="delta-${DELTA_VERSION#v}-${DELTA_ARCH}.tar.gz"
  DELTA_URL="https://github.com/dandavison/delta/releases/download/${DELTA_VERSION}/${DELTA_ASSET}"
  tmpdir="$(mktemp -d)"
  curl -fsSL "$DELTA_URL" | tar -xz -C "$tmpdir"
  install -m 0755 "$tmpdir/delta-${DELTA_ARCH}/delta" "$install_prefix/delta"
  rm -rf "$tmpdir"
fi

# Provide fd as `fd`
if command -v fdfind >/dev/null 2>&1; then
  mkdir -p ~/bin
  ln -sf "$(command -v fdfind)" ~/bin/fd
fi

# Install Neovim AppImage
echo "Installing Neovim..."
NEOVIM_VERSION="v0.11.5"
ARCH=$(uname -m)
if [[ "$ARCH" == "x86_64" ]]; then
  NEOVIM_ARCH="x86_64"
elif [[ "$ARCH" == "aarch64" ]] || [[ "$ARCH" == "arm64" ]]; then
  NEOVIM_ARCH="arm64"
else
  echo "Unsupported architecture: $ARCH"
  exit 1
fi

NEOVIM_FILENAME="nvim-linux-${NEOVIM_ARCH}.appimage"
NEOVIM_URL="https://github.com/neovim/neovim/releases/download/${NEOVIM_VERSION}/${NEOVIM_FILENAME}"

# Create ~/bin directory if it doesn't exist
mkdir -p ~/bin

# Download Neovim AppImage
echo "Downloading Neovim AppImage from ${NEOVIM_URL}..."
wget -O ~/bin/nvim.appimage "${NEOVIM_URL}"

# Make it executable
chmod +x ~/bin/nvim.appimage

# Create a symlink for easier access
ln -sf ~/bin/nvim.appimage ~/bin/nvim

# Create system-wide nvim symlink for sudo usage
if [[ -w /usr/local/bin ]]; then
  sudo ln -sf ~/bin/nvim.appimage /usr/local/bin/nvim
elif [[ -w /usr/bin ]]; then
  sudo ln -sf ~/bin/nvim.appimage /usr/bin/nvim
fi

# Install yazi (TUI file manager)
echo "Installing yazi..."
if apt-cache show yazi >/dev/null 2>&1; then
  sudo apt install -y yazi
else
  # Fallback to upstream installer if package not available
  curl -fsSL https://yazi-rs.github.io/install.sh | bash
fi

# Install pnpm
echo "Installing pnpm..."
curl -fsSL https://get.pnpm.io/install.sh | sh -

# Install uv (Python package manager)
echo "Installing uv..."
curl -LsSf https://astral.sh/uv/install.sh | sh

# Change default shell to Zsh if not already changed
if [[ "$SHELL" != */zsh ]]; then
  echo "Changing default shell to Zsh..."
  chsh -s $(which zsh)
  echo "⚠️  Please log out and log back in for the shell change to take effect."
fi

echo "✅ Dependencies installation completed!"
