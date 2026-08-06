cache_dir="${XDG_CACHE_HOME:-$HOME/.local/cache}/zsh"
[[ -d "$cache_dir" ]] || mkdir -p "$cache_dir"

sheldon_cache="$cache_dir/sheldon.zsh"
sheldon_toml="${XDG_CONFIG_HOME:-$HOME/.config}/sheldon/plugins.toml"
sheldon_lock="${XDG_DATA_HOME:-$HOME/.local/share}/sheldon/plugins.lock"
_sheldon_bin="$(command -v sheldon)"

if [[ -n "$_sheldon_bin" && ( ! -r "$sheldon_cache" || "$sheldon_toml" -nt "$sheldon_cache" || ( -r "$sheldon_lock" && "$sheldon_lock" -nt "$sheldon_cache" ) ) ]]; then
  _sheldon_tmp="$sheldon_cache.tmp.$$"
  if "$_sheldon_bin" --quiet source >| "$_sheldon_tmp"; then
    mv -f "$_sheldon_tmp" "$sheldon_cache"
  else
    rm -f "$_sheldon_tmp"
  fi
fi

if [[ -r "$sheldon_cache" ]]; then
  ensure_zcompiled "$sheldon_cache"
  builtin source "$sheldon_cache"
fi
unset _sheldon_tmp _sheldon_bin sheldon_toml sheldon_lock

zle -N ghq-roots-widget _ghq_roots_widget
bindkey '^g' ghq-roots-widget
zle -N fkill-widget _fkill_widget
bindkey '^x^k' fkill-widget
zle -N git-switch-branch-widget _git_switch_branch_widget
bindkey '^b' git-switch-branch-widget

_deferred_compinit() {
  autoload -Uz compinit
  _comp_dump="${XDG_CACHE_HOME:-$HOME/.local/cache}/zsh/.zcompdump"

  if [[ -r "$_comp_dump" ]]; then
    compinit -C -d "$_comp_dump"
  else
    compinit -d "$_comp_dump"
  fi

  ensure_zcompiled "$_comp_dump"
  unset _comp_dump
}

if [[ "$DEFER_COMPINIT" == true ]] && (( $+functions[zsh-defer] )); then
  zsh-defer _deferred_compinit
else
  _deferred_compinit
fi

[[ -f $XDG_CONFIG_HOME/zsh.local ]] && source "$XDG_CONFIG_HOME/zsh.local"

_starship_cache="$cache_dir/starship.zsh"
_starship_stamp="$cache_dir/starship.path"
_starship_config="${XDG_CONFIG_HOME:-$HOME/.config}/starship.toml"
_starship_bin="$(command -v starship)"
_starship_real="${_starship_bin:A}"
# starship init bakes the generator's absolute path into the cache, so a
# profile-path change (e.g. nix-darwin -> standalone home-manager) leaves a
# stale, unresolvable path. Track the resolved Nix store path explicitly
# because store mtimes are fixed and the profile symlink path is stable.
if [[ -n "$_starship_bin" ]] && { [[ ! -r "$_starship_cache" ]] || [[ ! -r "$_starship_stamp" ]] || [[ "$(<"$_starship_stamp")" != "$_starship_real" ]] || { [[ -r "$_starship_config" ]] && [[ "$_starship_config" -nt "$_starship_cache" ]]; }; }; then
  _starship_tmp="$cache_dir/starship.zsh.tmp.$$"
  _starship_stamp_tmp="$cache_dir/starship.path.tmp.$$"
  if "$_starship_bin" init zsh >| "$_starship_tmp"; then
    mv -f "$_starship_tmp" "$_starship_cache"
    print -r -- "$_starship_real" >| "$_starship_stamp_tmp"
    mv -f "$_starship_stamp_tmp" "$_starship_stamp"
  else
    rm -f "$_starship_tmp" "$_starship_stamp_tmp"
  fi
fi
if [[ -r "$_starship_cache" ]]; then
  ensure_zcompiled "$_starship_cache"
  builtin source "$_starship_cache"
fi

_zoxide_cache="$cache_dir/zoxide.zsh"
_zoxide_stamp="$cache_dir/zoxide.path"
_zoxide_bin="$(command -v zoxide)"
_zoxide_real="${_zoxide_bin:A}"
if [[ -n "$_zoxide_bin" ]] && { [[ ! -r "$_zoxide_cache" ]] || [[ ! -r "$_zoxide_stamp" ]] || [[ "$(<"$_zoxide_stamp")" != "$_zoxide_real" ]]; }; then
  _zoxide_tmp="$cache_dir/zoxide.zsh.tmp.$$"
  _zoxide_stamp_tmp="$cache_dir/zoxide.path.tmp.$$"
  if "$_zoxide_bin" init zsh >| "$_zoxide_tmp"; then
    mv -f "$_zoxide_tmp" "$_zoxide_cache"
    print -r -- "$_zoxide_real" >| "$_zoxide_stamp_tmp"
    mv -f "$_zoxide_stamp_tmp" "$_zoxide_stamp"
  else
    rm -f "$_zoxide_tmp" "$_zoxide_stamp_tmp"
  fi
fi
if [[ -r "$_zoxide_cache" ]]; then
  ensure_zcompiled "$_zoxide_cache"
  builtin source "$_zoxide_cache"
fi

if (( $+functions[zsh-defer] )); then
  zsh-defer unfunction ensure_zcompiled _deferred_compinit
else
  unfunction ensure_zcompiled _deferred_compinit 2>/dev/null
fi

unset DEFER_COMPINIT cache_dir sheldon_cache
unset _starship_bin _starship_real _starship_cache _starship_stamp _starship_config
unset _starship_tmp _starship_stamp_tmp
unset _zoxide_bin _zoxide_real _zoxide_cache _zoxide_stamp
unset _zoxide_tmp _zoxide_stamp_tmp
