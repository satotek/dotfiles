## Shell

- Agent Bash calls run in zsh, not bash. Do not use `path` as a variable
  name: zsh ties it to `PATH`, so `for path in …` breaks every later command.
- `pkill -f <pattern>` / `pgrep -f` also match the shell running the command,
  because the pattern is in its command line, and kill it (exit 144). Bracket
  one character (`pkill -f '[s]erver.js'`), or record the PID at start and
  kill that.
