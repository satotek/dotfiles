# XDG Base Directory Specification
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.local/cache"
export XDG_STATE_HOME="$HOME/.local/state"

# Zsh configuration directory
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"

# XDG-compatible application configurations
export HISTFILE="$XDG_STATE_HOME/zsh/history"
export LESSHISTFILE="$XDG_CACHE_HOME/less/history"
export WGETRC="$XDG_CONFIG_HOME/wget/wgetrc"
export INPUTRC="$XDG_CONFIG_HOME/readline/inputrc"
export PNPM_HOME="$XDG_DATA_HOME/pnpm"

# Update PATH only when the entry is missing so repeated sourcing stays clean.
path_prepend() {
  case ":$PATH:" in
    *":$1:"*) ;;
    *) PATH="$1${PATH:+:$PATH}" ;;
  esac
}

path_append() {
  case ":$PATH:" in
    *":$1:"*) ;;
    *)
      PATH="${PATH:+$PATH:}$1"
      ;;
  esac
}

# Homebrew (macOS only). `brew shellenv` delegates to path_helper each time its
# output is sourced, so declare the stable prefix directly instead.
if [[ "$OSTYPE" == darwin* ]]; then
  if [[ -x "/opt/homebrew/bin/brew" ]]; then
    HOMEBREW_PREFIX="/opt/homebrew"
  elif [[ -x "/usr/local/bin/brew" ]]; then
    HOMEBREW_PREFIX="/usr/local"
  else
    HOMEBREW_PREFIX=""
  fi

  if [[ -n "$HOMEBREW_PREFIX" ]]; then
    export HOMEBREW_PREFIX
    export HOMEBREW_CELLAR="$HOMEBREW_PREFIX/Cellar"
    export HOMEBREW_REPOSITORY="$HOMEBREW_PREFIX"

    path_prepend "$HOMEBREW_PREFIX/sbin"
    path_prepend "$HOMEBREW_PREFIX/bin"

    if [[ -n "${ZSH_VERSION:-}" ]]; then
      fpath=("$HOMEBREW_PREFIX/share/zsh/site-functions" $fpath)
      typeset -U fpath
      export FPATH
    else
      export FPATH="$HOMEBREW_PREFIX/share/zsh/site-functions${FPATH:+:$FPATH}"
    fi

    [ -z "${MANPATH-}" ] || export MANPATH=":${MANPATH#:}"
    export INFOPATH="$HOMEBREW_PREFIX/share/info:${INFOPATH:-}"
  else
    unset HOMEBREW_PREFIX
  fi
fi

# Keep user-local bins available, but let Nix-managed tools win first.
path_append "$HOME/.local/bin"
path_append "$HOME/.cargo/bin"
path_append "$HOME/bin"
path_append "$PNPM_HOME"
export PATH

# Load local secrets (not tracked by git)
[ -f "$XDG_CONFIG_HOME/secrets" ] && . "$XDG_CONFIG_HOME/secrets"
