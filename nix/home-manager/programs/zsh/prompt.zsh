# Starship's standard Zsh integration renders PROMPT and RPROMPT sequentially.
# Pre-render both in parallel while retaining Starship's status/duration hooks and
# exact module output. The files are per-shell and overwritten on every prompt.
typeset -gr _STARSHIP_PROMPT_BIN="${_ZBIN_STARSHIP:-}"
typeset -gr _STARSHIP_PROMPT_DIR="${XDG_CACHE_HOME:-$HOME/.local/cache}/zsh"
typeset -gr _STARSHIP_PROMPT_LEFT="${_STARSHIP_PROMPT_DIR}/starship-prompt-${$}.left"
typeset -gr _STARSHIP_PROMPT_RIGHT="${_STARSHIP_PROMPT_DIR}/starship-prompt-${$}.right"

_starship_render_parallel() {
  [[ -n "$_STARSHIP_PROMPT_BIN" ]] || return
  [[ -d "$_STARSHIP_PROMPT_DIR" && -w "$_STARSHIP_PROMPT_DIR" ]] || return

  local -a prompt_args=(
    --terminal-width="$COLUMNS"
    --keymap="${KEYMAP:-}"
    --status="${STARSHIP_CMD_STATUS:-}"
    --pipestatus="${STARSHIP_PIPE_STATUS[*]:-}"
    --cmd-duration="${STARSHIP_DURATION:-}"
    --jobs="${STARSHIP_JOBS_COUNT:-0}"
  )
  local left_pid right_pid left_status right_status

  # Zsh normally lowers the priority of background jobs. Avoid that here: both
  # jobs are on the critical path and are awaited immediately.
  setopt localoptions no_bg_nice no_monitor
  "$_STARSHIP_PROMPT_BIN" prompt "${prompt_args[@]}" >| "$_STARSHIP_PROMPT_LEFT" &
  left_pid=$!
  "$_STARSHIP_PROMPT_BIN" prompt --right "${prompt_args[@]}" >| "$_STARSHIP_PROMPT_RIGHT" &
  right_pid=$!

  wait "$left_pid"
  left_status=$?
  wait "$right_pid"
  right_status=$?

  (( left_status == 0 )) && PROMPT="$(<"$_STARSHIP_PROMPT_LEFT")"
  (( right_status == 0 )) && RPROMPT="$(<"$_STARSHIP_PROMPT_RIGHT")"
}

_starship_prompt_cleanup() {
  command rm -f -- "$_STARSHIP_PROMPT_LEFT" "$_STARSHIP_PROMPT_RIGHT"
}

if [[ -n "$_STARSHIP_PROMPT_BIN" ]]; then
  autoload -Uz add-zsh-hook
  add-zsh-hook precmd _starship_render_parallel
  add-zsh-hook zshexit _starship_prompt_cleanup

  # `starship prompt --continuation` is otherwise a separate process during
  # every shell startup. This is its exact default output for the current
  # configuration, represented directly as Zsh prompt escapes.
  PROMPT2=$'%{\e[90m%}∙%{\e[0m%} '

  # PROMPT/RPROMPT now contain rendered text rather than command substitutions.
  # Re-render when a vi keymap change asks Starship to redraw the prompt.
  starship_zle-keymap-select() {
    _starship_render_parallel
    zle reset-prompt
  }
fi

unset _ZBIN_DIRENV _ZBIN_STARSHIP _ZBIN_FZF _ZBIN_ZOXIDE
