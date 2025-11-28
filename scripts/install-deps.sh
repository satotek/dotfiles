#!/bin/bash

set -eu

echo "📦 Installing dependencies..."

# Update package lists
sudo apt update

# Install Zsh
echo "Installing Zsh..."
sudo apt install -y zsh

# Install curl and wget for downloading files
echo "Installing curl and wget..."
sudo apt install -y curl wget

# Install git if not already installed
echo "Installing git..."
sudo apt install -y git

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