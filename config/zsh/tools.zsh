# Development tools setup

# pnpm
export PNPM_HOME="$XDG_DATA_HOME/pnpm"
[[ ":$PATH:" != *":$PNPM_HOME:"* ]] && export PATH="$PNPM_HOME:$PATH"

# uv (Python package manager)
[[ -f "$HOME/.local/bin/env" ]] && . "$HOME/.local/bin/env"

