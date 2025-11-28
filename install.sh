#! /bin/bash

set -eu

readonly ARCH_TYPE="$(arch)"
readonly DOTPATH="${HOME}/dotfiles"

echo -e "\nInstallation has started...\n"
echo -e "My architecture: ${ARCH_TYPE}\n"

# Setup XDG Base Directory environment
"${DOTPATH}/scripts/setup-xdg.sh"
echo

# Create directory structure
"${DOTPATH}/scripts/create-dirs.sh"
echo

# Make symbolic links and directories
"${DOTPATH}/scripts/symlink.sh"
echo

# Install dependencies
"${DOTPATH}/scripts/install-deps.sh"
echo
