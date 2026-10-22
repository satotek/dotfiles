# Codex reviewer

Use `codex exec review` from Claude Code or OpenCode. It runs headlessly in the
same repository — no TUI and no persisted session — and prints the review to
stdout. It has native scope flags, so do not pass a git command in a prompt as
well.

## Commands

```sh
# The default: staged, unstaged, and untracked changes
codex exec review --uncommitted --ephemeral

# A specific commit, when the user names one
codex exec review --commit <sha> --ephemeral

# Long reviews: write the final message to a file
codex exec review --uncommitted --ephemeral -o /tmp/review.md
```

- `--ephemeral` keeps the review out of Codex session history.
- `-m <model>` overrides the configured model. Omit it by default.
- The review model is `review_model` when set in `~/.codex/config.toml`;
  otherwise it is the session `model`. The current config sets
  `review_model = "gpt-6.1-sol"`.

```sh
# One-off override
codex exec review --uncommitted --ephemeral -m <model>
```

- A positional prompt cannot be combined with `--uncommitted` or `--commit`.
  When extra instructions are needed, use plain `codex exec` with the brief from
  `brief.md` and `--sandbox read-only`.

```sh
codex exec --sandbox read-only --ephemeral "<brief>"
```

## Troubleshooting

- `not a git repository`: run from the repository root.
- Auth error: `codex login status`; stop and report if it is not logged in.
- Huge working tree: review one commit at a time instead of raising limits.
- Empty or truncated output: rerun with `-o /tmp/review.md` and read the file.
