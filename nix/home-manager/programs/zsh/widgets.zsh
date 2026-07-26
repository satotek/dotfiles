zstyle ':completion:*' matcher-list "" "m:{[:lower:]}={[:upper:]}" "+m:{[:upper:]}={[:lower:]}"
zstyle ':completion:*' format '%B%F{blue}%d%f%b'
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
