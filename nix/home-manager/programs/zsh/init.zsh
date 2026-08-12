unfunction dirname 2>/dev/null
zmodload -u zsh/files 2>/dev/null

cache_dir="${XDG_CACHE_HOME:-$HOME/.local/cache}/zsh"
[[ -d "$cache_dir" ]] || mkdir -p "$cache_dir"

# Sheldonのキャッシュはhome-managerのactivation(sheldon.nix)が生成・zcompile済み。
# ここでplugins.toml/lockのmtimeを見て再生成する必要はなく、sheldonの実体を探す
# ための `${commands[sheldon]}` がPATH全走査を誘発していた。読むだけにする。
sheldon_cache="$cache_dir/sheldon.zsh"
[[ -r "$sheldon_cache" ]] && builtin source "$sheldon_cache"

_direnv_cache="$cache_dir/direnv.zsh"
_direnv_stamp="$cache_dir/direnv.path"
if [[ -n "$_ZBIN_DIRENV" ]] && { [[ ! -r "$_direnv_cache" ]] || [[ ! -r "$_direnv_stamp" ]] || [[ "$(<"$_direnv_stamp")" != "$_ZBIN_DIRENV" ]]; }; then
  _direnv_tmp="$cache_dir/direnv.zsh.tmp.$$"
  _direnv_stamp_tmp="$cache_dir/direnv.path.tmp.$$"
  if "$_ZBIN_DIRENV" hook zsh >| "$_direnv_tmp"; then
    mv -f "$_direnv_tmp" "$_direnv_cache"
    print -r -- "$_ZBIN_DIRENV" >| "$_direnv_stamp_tmp"
    mv -f "$_direnv_stamp_tmp" "$_direnv_stamp"
  else
    rm -f "$_direnv_tmp" "$_direnv_stamp_tmp"
  fi
fi
if [[ -r "$_direnv_cache" ]]; then
  ensure_zcompiled "$_direnv_cache"
  builtin source "$_direnv_cache"
fi

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
_starship_cache_version="parallel-prompt-v1"
_starship_signature="${_ZBIN_STARSHIP}|${_starship_cache_version}"
# starship init bakes the generator's absolute path into the cache, so a
# profile-path change (e.g. nix-darwin -> standalone home-manager) leaves a
# stale, unresolvable path. The signature is the Nix store path itself, so any
# starship upgrade or profile move invalidates the cache exactly once.
if [[ -n "$_ZBIN_STARSHIP" ]] && { [[ ! -r "$_starship_cache" ]] || [[ ! -r "$_starship_stamp" ]] || [[ "$(<"$_starship_stamp")" != "$_starship_signature" ]] || { [[ -r "$_starship_config" ]] && [[ "$_starship_config" -nt "$_starship_cache" ]]; }; }; then
  _starship_tmp="$cache_dir/starship.zsh.tmp.$$"
  _starship_raw_tmp="$cache_dir/starship.zsh.raw.tmp.$$"
  _starship_stamp_tmp="$cache_dir/starship.path.tmp.$$"
  if "$_ZBIN_STARSHIP" init zsh >| "$_starship_raw_tmp"; then
    # The generated integration executes `starship prompt --continuation`
    # while it is sourced. Replace that fixed output before caching it.
    while IFS= read -r _starship_line; do
      if [[ "$_starship_line" == 'PROMPT2='* ]]; then
        print -r -- 'PROMPT2=$'\''%{\e[90m%}∙%{\e[0m%} '\'''
      else
        print -r -- "$_starship_line"
      fi
    done < "$_starship_raw_tmp" >| "$_starship_tmp"
    mv -f "$_starship_tmp" "$_starship_cache"
    print -r -- "$_starship_signature" >| "$_starship_stamp_tmp"
    mv -f "$_starship_stamp_tmp" "$_starship_stamp"
    rm -f "$_starship_raw_tmp"
  else
    rm -f "$_starship_tmp" "$_starship_raw_tmp" "$_starship_stamp_tmp"
  fi
fi
if [[ -r "$_starship_cache" ]]; then
  ensure_zcompiled "$_starship_cache"
  builtin source "$_starship_cache"
fi

_fzf_cache="$cache_dir/fzf.zsh"
_fzf_stamp="$cache_dir/fzf.path"
if [[ -n "$_ZBIN_FZF" ]] && { [[ ! -r "$_fzf_cache" ]] || [[ ! -r "$_fzf_stamp" ]] || [[ "$(<"$_fzf_stamp")" != "$_ZBIN_FZF" ]]; }; then
  _fzf_tmp="$cache_dir/fzf.zsh.tmp.$$"
  _fzf_stamp_tmp="$cache_dir/fzf.path.tmp.$$"
  if "$_ZBIN_FZF" --zsh >| "$_fzf_tmp"; then
    mv -f "$_fzf_tmp" "$_fzf_cache"
    print -r -- "$_ZBIN_FZF" >| "$_fzf_stamp_tmp"
    mv -f "$_fzf_stamp_tmp" "$_fzf_stamp"
  else
    rm -f "$_fzf_tmp" "$_fzf_stamp_tmp"
  fi
fi
if [[ -r "$_fzf_cache" ]]; then
  ensure_zcompiled "$_fzf_cache"
fi

typeset -gr _FZF_INIT_CACHE="$_fzf_cache"

_fzf_lazy_load() {
  (( $+functions[fzf-file-widget] )) && return
  [[ -r "$_FZF_INIT_CACHE" ]] || return 1
  builtin source "$_FZF_INIT_CACHE"
}

_fzf_lazy_file_widget() {
  _fzf_lazy_load || return
  zle fzf-file-widget
}

_fzf_lazy_cd_widget() {
  _fzf_lazy_load || return
  zle fzf-cd-widget
}

_fzf_lazy_history_widget() {
  _fzf_lazy_load || return
  zle fzf-history-widget
}

_fzf_lazy_completion_widget() {
  _fzf_lazy_load || return
  zle fzf-completion
}

if [[ -r "$_FZF_INIT_CACHE" && $options[zle] = on ]]; then
  typeset -g fzf_default_completion=expand-or-complete
  _fzf_binding="$(bindkey '^I')"
  if [[ "$_fzf_binding" != *undefined-key* ]]; then
    typeset -g fzf_default_completion="${${(z)_fzf_binding}[2]}"
  fi
  unset _fzf_binding

  zle -N _fzf_lazy_file_widget
  zle -N _fzf_lazy_cd_widget
  zle -N _fzf_lazy_history_widget
  zle -N _fzf_lazy_completion_widget

  for _fzf_keymap in emacs vicmd viins; do
    bindkey -M "$_fzf_keymap" '^T' _fzf_lazy_file_widget
    bindkey -M "$_fzf_keymap" '\ec' _fzf_lazy_cd_widget
    bindkey -M "$_fzf_keymap" '^R' _fzf_lazy_history_widget
  done
  bindkey '^I' _fzf_lazy_completion_widget
  unset _fzf_keymap
fi

_zoxide_cache="$cache_dir/zoxide.zsh"
_zoxide_stamp="$cache_dir/zoxide.path"
if [[ -n "$_ZBIN_ZOXIDE" ]] && { [[ ! -r "$_zoxide_cache" ]] || [[ ! -r "$_zoxide_stamp" ]] || [[ "$(<"$_zoxide_stamp")" != "$_ZBIN_ZOXIDE" ]]; }; then
  _zoxide_tmp="$cache_dir/zoxide.zsh.tmp.$$"
  _zoxide_stamp_tmp="$cache_dir/zoxide.path.tmp.$$"
  if "$_ZBIN_ZOXIDE" init zsh >| "$_zoxide_tmp"; then
    mv -f "$_zoxide_tmp" "$_zoxide_cache"
    print -r -- "$_ZBIN_ZOXIDE" >| "$_zoxide_stamp_tmp"
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
unset _direnv_cache _direnv_stamp _direnv_tmp _direnv_stamp_tmp
unset _starship_cache _starship_stamp _starship_config
unset _starship_cache_version _starship_signature _starship_line
unset _starship_tmp _starship_raw_tmp _starship_stamp_tmp
unset _fzf_cache _fzf_stamp _fzf_tmp _fzf_stamp_tmp
unset _zoxide_cache _zoxide_stamp _zoxide_tmp _zoxide_stamp_tmp
