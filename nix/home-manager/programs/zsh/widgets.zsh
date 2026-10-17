zstyle ':completion:*' matcher-list "" "m:{[:lower:]}={[:upper:]}" "+m:{[:upper:]}={[:lower:]}"
zstyle ':completion:*' format '[%d]'
zstyle ':completion:*' group-name ""
zstyle ':completion:*:default' menu select=2

_ghq_roots_widget() {
  local selected
  selected="$(ghq list --full-path | roots | fzf \
    --height 40% \
    --reverse \
    --border \
    --cycle \
    --select-1 \
    --preview 'eza --tree --level=2 --git-ignore --color=always --icons {} 2>/dev/null || ls -A -- {}')"
  [[ -n "$selected" ]] && cd -- "$selected"
  zle reset-prompt
}

_fkill_widget() {
  local pid
  pid="$(ps ax -o pid,time,command | fzf --prompt 'Kill> ' --query "$LBUFFER" | awk '{print $1}')" || {
    zle reset-prompt
    return
  }
  [[ -n "$pid" && "$pid" != "PID" ]] && kill "$pid"
  zle reset-prompt
}

# 履歴を前方一致で遡る。標準の history-beginning-search-* は検索条件をカーソルまでの
# 文字列から取るため、検索後に行末へ移すと次の条件が選択した行全体になり、連続して遡れ
# なくなる。直前に表示した行を表示している間は、条件の長さへカーソルを戻してから検索する。
# 複数行を編集中は前方一致が効かないため、行移動を優先する既定の動作に任せる。
typeset -g _history_prefix_offset=0
typeset -g _history_prefix_result=""

_history_prefix_widget() {
  local line="$1" search="$2" before_cursor=$CURSOR

  if [[ $BUFFER == *$'\n'* ]]; then
    zle ".$line"
    return
  fi

  if [[ -n $BUFFER && $BUFFER == "$_history_prefix_result" ]]; then
    CURSOR=$_history_prefix_offset
  else
    _history_prefix_offset=$CURSOR
  fi

  if zle ".$search"; then
    _history_prefix_result="$BUFFER"
    zle .end-of-line
  else
    CURSOR=$before_cursor
  fi
}

_history_prefix_up_widget() {
  _history_prefix_widget up-line-or-history history-beginning-search-backward
}

_history_prefix_down_widget() {
  _history_prefix_widget down-line-or-history history-beginning-search-forward
}

_git_switch_branch_widget() {
  if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    zle -M "Not in a Git repository"
    return
  fi

  local branch
  branch="$(git branch -a --format='%(refname:short) %(symref)' | \
    awk 'NF == 1 { print $1 }' | \
    sed 's|^origin/||' | \
    sort -u | \
    fzf --prompt 'Switch to branch: ')" || {
    zle reset-prompt
    return
  }
  [[ -n "$branch" ]] && git switch "$branch"
  zle reset-prompt
}
