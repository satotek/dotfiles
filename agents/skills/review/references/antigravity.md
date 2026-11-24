# Antigravity reviewer

Use the Antigravity CLI (`agy`) from Claude Code or OpenCode. It runs headlessly
in the same repository, prints the review to stdout, and exits.

## Command

```sh
agy --model gemini-4-neon -p "<brief from brief.md>"
```

- Put `-p` last with the brief right after it. `-p` takes the next argument as
  its prompt, so `agy -p --model ...` sends `--model` as the prompt and ignores
  the brief.
- Pass `--effort <level>` only when the user asks for one.
- `--add-dir <path>` for a repository outside the current directory.

## Troubleshooting

- Model not found: `agy models` lists ids.
- Auth error: run `agy` interactively once to sign in; stop and report rather
  than self-review.
