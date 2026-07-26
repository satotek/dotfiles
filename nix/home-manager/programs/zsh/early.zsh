export ZENO_HOME="$HOME/.config/zeno"
export ZENO_DISABLE_EXECUTE_CACHE_COMMAND=1
export ZENO_GIT_CAT="bat --color=always"
export ZENO_GIT_TREE="eza --tree"
export FZF_DEFAULT_OPTS="--extended --cycle --select-1 --height 40% --reverse --border"

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
