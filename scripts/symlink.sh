#!/bin/bash

set -eu

readonly DOTHOME="${HOME}/dotfiles/home"

# XDG Base Directory変数が設定されていない場合にデフォルト値を設定
: "${XDG_CONFIG_HOME:=${HOME}/.config}"
: "${XDG_CACHE_HOME:=${HOME}/.cache}"
: "${XDG_DATA_HOME:=${HOME}/.local/share}"
: "${XDG_STATE_HOME:=${HOME}/.local/state}"

mkdir -p "${XDG_CONFIG_HOME}"
mkdir -p "${XDG_CACHE_HOME}"
mkdir -p "${XDG_DATA_HOME}"
mkdir -p "${XDG_STATE_HOME}"

if [ ! -e "${DOTHOME}" ]; then
  echo "Error: Directory does not exist: ${DOTHOME}"
  exit 1
fi

# Make symbolic links from ~/.* to ~/share/dotfiles/home/.*
for file_path in "${DOTHOME}"/.??*; do
  file_name="$(basename "${file_path}")"
  if [[ "${file_name}" =~ ^(\.DS_Store|\.git|\.github|\.gitignore)$ ]]; then
    continue
  fi
  ln -fvns "${DOTHOME}/${file_name}" "${HOME}/${file_name}"
done

# Symlink config directory contents to ~/.config
for item in "${DOTHOME}/config"/*; do
  name="$(basename "$item")"
  target="${XDG_CONFIG_HOME}/${name}"
  # Remove existing directory (not symlink) to allow symlink creation
  if [[ -d "$target" && ! -L "$target" ]]; then
    rm -rf "$target"
  fi
  ln -fvns "$item" "$target"
done

# Make directories with reference to Filesystem Hierarchy Standard
mkdir -p "${HOME}/bin" # for original commands
mkdir -p "${HOME}/src" # for code repositories
mkdir -p "${HOME}/tmp" # for temporary workspace
