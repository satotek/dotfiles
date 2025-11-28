#!/bin/bash

set -eu

echo "📁 Creating directory structure..."

# Create ~/bin directory
echo "Creating ~/bin directory..."
mkdir -p ~/bin

# Create workspace directories
echo "Creating workspace directories..."
mkdir -p ~/workspaces/{develop,education,sandbox,temp}

echo "Created workspace directories:"
echo "  ~/workspaces/develop"
echo "  ~/workspaces/education"
echo "  ~/workspaces/sandbox"
echo "  ~/workspaces/temp"

# Create XDG directories if they don't exist
echo "Creating XDG directories..."
mkdir -p ~/.config
mkdir -p ~/.cache
mkdir -p ~/.local/share
mkdir -p ~/.local/state

# Create application-specific directories for XDG compliance
mkdir -p ~/.local/state/zsh
mkdir -p ~/.cache/less
mkdir -p ~/.config/wget

echo "✅ Directory structure creation completed!"