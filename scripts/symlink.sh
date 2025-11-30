#!/bin/bash

set -eu

readonly DOTPATH="${HOME}/dotfiles"

# XDG Base Directory変数が設定されていない場合にデフォルト値を設定
: "${XDG_CONFIG_HOME:=${HOME}/.config}"
: "${XDG_CACHE_HOME:=${HOME}/.cache}"
: "${XDG_DATA_HOME:=${HOME}/.local/share}"
: "${XDG_STATE_HOME:=${HOME}/.local/state}"

mkdir -p "${XDG_CONFIG_HOME}"
mkdir -p "${XDG_CACHE_HOME}"
mkdir -p "${XDG_DATA_HOME}"
mkdir -p "${XDG_STATE_HOME}"

if [ ! -e "${DOTPATH}/config" ]; then
  echo "Error: Directory does not exist: ${DOTPATH}/config"
  exit 1
fi

# Symlink config directory contents to ~/.config
for item in "${DOTPATH}/config"/*; do
  name="$(basename "$item")"
  target="${XDG_CONFIG_HOME}/${name}"
  # Remove existing directory (not symlink) to allow symlink creation
  if [[ -d "$target" && ! -L "$target" ]]; then
    rm -rf "$target"
  fi
  ln -fvns "$item" "$target"
done

# Ensure legacy tmux path (~/.tmux.conf) points to XDG config
if [[ -f "${DOTPATH}/config/tmux/tmux.conf" ]]; then
  ln -fvns "${DOTPATH}/config/tmux/tmux.conf" "${HOME}/.tmux.conf"
fi

# Make directories with reference to Filesystem Hierarchy Standard
mkdir -p "${HOME}/bin" # for original commands
mkdir -p "${HOME}/src" # for code repositories
mkdir -p "${HOME}/tmp" # for temporary workspace
