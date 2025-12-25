#!/bin/bash

set -eu

echo "📦 Installing dependencies for macOS..."

# Check if Homebrew is installed
if ! command -v brew &>/dev/null; then
  echo "🍺 Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # Add Homebrew to PATH for Apple Silicon
  if [[ "$(uname -m)" == "arm64" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  else
    eval "$(/usr/local/bin/brew shellenv)"
  fi
fi

echo "🍺 Updating Homebrew..."
brew update

# Core CLI tools
echo "Installing core CLI tools..."
brew install \
  zsh \
  curl \
  wget \
  git \
  tmux \
  fzf \
  ripgrep \
  fd

# Development tools
echo "Installing development tools..."
brew install \
  neovim \
  lazygit \
  git-delta \
  node \
  python3 \
  yazi

# Install Rust via rustup
echo "Installing Rust..."
if ! command -v rustup &>/dev/null; then
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
  source "$HOME/.cargo/env"
fi

# Install pnpm
echo "Installing pnpm..."
if ! command -v pnpm &>/dev/null; then
  curl -fsSL https://get.pnpm.io/install.sh | sh -
fi

# Install uv (Python package manager)
echo "Installing uv..."
if ! command -v uv &>/dev/null; then
  curl -LsSf https://astral.sh/uv/install.sh | sh
fi

# Setup fzf key bindings and fuzzy completion
echo "Setting up fzf..."
"$(brew --prefix)/opt/fzf/install" --key-bindings --completion --no-update-rc --no-bash --no-fish

# Change default shell to Zsh if not already
if [[ "$SHELL" != */zsh ]]; then
  echo "Changing default shell to Zsh..."
  chsh -s "$(which zsh)"
  echo "⚠️  Please log out and log back in for the shell change to take effect."
fi

echo "✅ macOS dependencies installation completed!"
