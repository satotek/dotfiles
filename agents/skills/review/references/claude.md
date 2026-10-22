# Claude Code reviewer

Use `claude -p` from Codex or OpenCode. It runs headlessly in the same
repository, prints the review to stdout, and exits; it does not open an
interactive session.

## Command

```sh
claude -p \
  --model opus \
  --permission-mode plan \
  --permission-prompts none \
  --allowedTools="Read,Grep,Glob,Bash(git diff:*),Bash(git show:*),Bash(git status:*),Bash(git log:*),Bash(git ls-files:*),Bash(git rev-parse:*)" \
  "<brief from brief.md>"
```

- `--permission-mode plan` keeps Claude read-only.
- `--permission-prompts none` denies anything that would prompt, so the command
  cannot hang waiting for input.
- Keep the `=` in `--allowedTools=...`. The flag takes multiple values, so
  `--allowedTools "Read" "<brief>"` would consume the brief as a tool name.
- `--allowedTools` must cover every command the brief asks for.
- `--model opus` is the default; use a stronger model only when the user asks.
- `--add-dir <path>` for a repository outside the current directory.
- Output is text by default. Use `--output-format json` only when parsing the
  result; the answer is in the `result` field.

## Troubleshooting

- Empty output: rerun with `--output-format json` and inspect `result`.
- Permission denial: the brief asked for a command outside `--allowedTools`;
  widen the allowlist or make the brief use `git diff` only.
- Auth error: `claude auth status`; stop and report if it is not logged in.
