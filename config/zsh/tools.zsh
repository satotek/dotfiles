# Development tools setup

# pnpm
export PNPM_HOME="$XDG_DATA_HOME/pnpm"
[[ ":$PATH:" != *":$PNPM_HOME:"* ]] && export PATH="$PNPM_HOME:$PATH"

# uv (Python package manager)
[[ -f "$HOME/.local/bin/env" ]] && . "$HOME/.local/bin/env"

# ghcup use XDG_DATA_HOME
export GHCUP_USE_XDG_DIRS=1

# haskell
: "${XDG_BIN_HOME:=$HOME/.local/bin}"
[[ ":$PATH:" != *":$XDG_BIN_HOME:"* ]] && export PATH="$XDG_BIN_HOME:$PATH"
[[ ":$PATH:" != *":$HOME/.cabal/bin:"* ]] && export PATH="$HOME/.cabal/bin:$PATH"
