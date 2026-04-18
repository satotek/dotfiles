# Development tools setup

# pnpm
export PNPM_HOME="$XDG_DATA_HOME/pnpm"
[[ ":$PATH:" != *":$PNPM_HOME:"* ]] && export PATH="$PATH:$PNPM_HOME"

# User-local binaries
: "${XDG_BIN_HOME:=$HOME/.local/bin}"
[[ ":$PATH:" != *":$XDG_BIN_HOME:"* ]] && export PATH="$PATH:$XDG_BIN_HOME"
