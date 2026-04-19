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

# Homebrew (macOS only)
if [[ "$OSTYPE" == darwin* ]]; then
  if [[ -x "/opt/homebrew/bin/brew" ]]; then
    brew_bin="/opt/homebrew/bin/brew"
  elif [[ -x "/usr/local/bin/brew" ]]; then
    brew_bin="/usr/local/bin/brew"
  else
    brew_bin=""
  fi

  if [[ -n "$brew_bin" ]]; then
    brew_cache="$XDG_CACHE_HOME/shell/brew-shellenv.sh"
    mkdir -p "${brew_cache%/*}"
    if [[ ! -r "$brew_cache" || "$brew_bin" -nt "$brew_cache" ]]; then
      _brew_tmp="$brew_cache.tmp.$$"
      if "$brew_bin" shellenv >| "$_brew_tmp"; then
        mv -f "$_brew_tmp" "$brew_cache"
      else
        rm -f "$_brew_tmp"
      fi
    fi
    [ -r "$brew_cache" ] && . "$brew_cache"
    unset brew_cache _brew_tmp
  fi
  unset brew_bin
fi

# Append to PATH only when the entry is missing so repeated sourcing stays clean.
path_append() {
  case ":$PATH:" in
    *":$1:"*) ;;
    *)
      PATH="${PATH:+$PATH:}$1"
      ;;
  esac
}

# Keep user-local bins available, but let Nix-managed tools win first.
path_append "$HOME/.local/bin"
path_append "$HOME/.cargo/bin"
path_append "$HOME/bin"
path_append "$PNPM_HOME"
export PATH

# Load local secrets (not tracked by git)
[ -f "$XDG_CONFIG_HOME/secrets" ] && . "$XDG_CONFIG_HOME/secrets"
