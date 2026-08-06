export FZF_DEFAULT_OPTS="--extended --cycle --select-1 --height 40% --reverse --border"

# Home Manager's history setup invokes external dirname and mkdir on every
# shell startup. Use Zsh's file builtins and a temporary parameter-based
# dirname implementation until that generated setup has run.
zmodload zsh/files
dirname() {
  if (( $# == 1 )); then
    print -r -- "${1:h}"
  else
    command dirname "$@"
  fi
}

ensure_zcompiled() {
  local src="$1"
  local zwc="$src.zwc"
  local dir="${src:h}"

  if [[ ! -r "$src" || ! -w "$dir" ]]; then
    return
  fi

  if [[ ! -r "$zwc" || "$src" -nt "$zwc" ]]; then
    zcompile "$src" 2>/dev/null || true
  fi
}
