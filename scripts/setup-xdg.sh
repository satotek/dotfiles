#!/bin/bash

set -eu

echo "🏠 Setting up XDG Base Directory environment..."

# Create ~/.config directory structure
echo "Creating ~/.config directory structure..."
mkdir -p ~/.config

# Update ~/.profile to source ~/.config/profile
echo "Updating ~/.profile to source ~/.config/profile..."
if [[ ! -f ~/.profile ]]; then
    touch ~/.profile
fi

# Check if the sourcing line already exists in ~/.profile
if ! grep -q '\.config/profile' ~/.profile 2>/dev/null; then
    echo '' >> ~/.profile
    echo '# Source XDG Base Directory configuration' >> ~/.profile
    echo '[ -f "$HOME/.config/profile" ] && . "$HOME/.config/profile"' >> ~/.profile
fi

# Also update ~/.zprofile for Zsh (login shell)
echo "Updating ~/.zprofile to source ~/.config/profile..."
if [[ ! -f ~/.zprofile ]]; then
    touch ~/.zprofile
fi

# Check if the sourcing line already exists in ~/.zprofile
if ! grep -q '\.config/profile' ~/.zprofile 2>/dev/null; then
    echo '' >> ~/.zprofile
    echo '# Source XDG Base Directory configuration' >> ~/.zprofile
    echo '[ -f "$HOME/.config/profile" ] && . "$HOME/.config/profile"' >> ~/.zprofile
fi

echo "✅ XDG Base Directory environment setup completed!"
