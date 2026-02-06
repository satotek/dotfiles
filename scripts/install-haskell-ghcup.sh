#!/bin/bash

set -euo pipefail

echo "Installing Haskell toolchain with ghcup..."

export GHCUP_USE_XDG_DIRS=1
: "${XDG_BIN_HOME:=$HOME/.local/bin}"

readonly GHCUP_XDG_BIN="$XDG_BIN_HOME"
readonly GHCUP_XDG_DATA_BIN="$HOME/.local/share/ghcup/bin"
readonly GHCUP_LEGACY_BIN="$HOME/.ghcup/bin"

resolve_ghcup() {
  if [[ -x "$GHCUP_XDG_BIN/ghcup" ]]; then
    echo "$GHCUP_XDG_BIN/ghcup"
    return 0
  fi

  if [[ -x "$GHCUP_XDG_DATA_BIN/ghcup" ]]; then
    echo "$GHCUP_XDG_DATA_BIN/ghcup"
    return 0
  fi

  if [[ -x "$GHCUP_LEGACY_BIN/ghcup" ]]; then
    echo "$GHCUP_LEGACY_BIN/ghcup"
    return 0
  fi

  if command -v ghcup >/dev/null 2>&1; then
    command -v ghcup
    return 0
  fi

  return 1
}

if ! GHCUP_CMD="$(resolve_ghcup)"; then
  echo "Installing ghcup..."
  curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | GHCUP_USE_XDG_DIRS=1 BOOTSTRAP_HASKELL_CABAL_XDG=1 BOOTSTRAP_HASKELL_NONINTERACTIVE=1 BOOTSTRAP_HASKELL_ADJUST_BASHRC=0 sh
  if ! GHCUP_CMD="$(resolve_ghcup)"; then
    echo "Failed to locate ghcup after installation."
    exit 1
  fi
fi

echo "Using ghcup: $GHCUP_CMD"

"$GHCUP_CMD" install ghc recommended
"$GHCUP_CMD" set ghc recommended
"$GHCUP_CMD" install cabal recommended
"$GHCUP_CMD" set cabal recommended
"$GHCUP_CMD" install hls recommended || "$GHCUP_CMD" install hls latest
"$GHCUP_CMD" install stack recommended || "$GHCUP_CMD" install stack latest

echo "Haskell toolchain installation completed!"
