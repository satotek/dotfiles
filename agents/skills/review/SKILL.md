---
name: review
description: Reviews the current working-tree changes with another vendor's model and harness — Codex from Claude Code, Claude Code from Codex. Use when the user asks for a code review ("review", "レビューして", "コードレビュー", "この変更を見て"), before opening a PR, or when a change needs an independent second opinion.
---

# Review

A review from the model and harness that wrote the change catches little. Send
the change to another vendor's model, another vendor's harness, or both.

This personal skill shadows any project skill with the same name. Read
`.claude/skills/review/SKILL.md` or `.agents/skills/review/SKILL.md` first when
it exists, plus the repository's review rules in `CLAUDE.md` / `AGENTS.md`, and
let them win.

## Pick the reviewer

Use the harness you are **not** running in:

| Running in | Review with |
| --- | --- |
| Claude Code | Codex CLI (`codex exec review`) |
| Codex | Claude Code CLI (`claude -p`) |
| OpenCode | Codex CLI first; Claude CLI when Codex is unavailable or the user asks |

Never start the CLI of the harness you are running in. If the harness is not
tied to a model vendor (OpenCode), also prefer a model vendor different from the
one you are running. If the other CLI is missing or unauthenticated, say so and
stop; do not silently self-review.

Read [references/codex.md](references/codex.md) or
[references/claude.md](references/claude.md) for the exact command. Read
[references/brief.md](references/brief.md) when the reviewer takes a prompt
instead of a native scope flag.

## Models

Use the reviewer's configured default unless the user names a model. Do not pin
version numbers; use family aliases.

- Codex: `review_model` in `~/.codex/config.toml` (currently `gpt-6.1-sol`);
  when it is unset, the session `model` is used. Pass `-m <model>` only when the
  user asks for one.
- Claude: `opus`; a stronger model only for a genuinely hard review.

## Scope

Review what is in the working tree now: staged, unstaged, and untracked changes.
Inspect it before calling the reviewer:

```sh
git status --short --untracked-files=all
git diff HEAD
git diff --cached --stat
```

- Codex: `--uncommitted` covers staged, unstaged, and untracked files.
- Claude: pass `git diff HEAD` as the scope and list the untracked files so the
  reviewer reads them directly.
- If the user names a specific commit, review that instead with
  `git show <sha>` (`--commit <sha>` for Codex).

If the working tree is clean, say so and stop; do not invent a scope. Do not
review a branch or a PR unless the user explicitly changes the request.

## Run it

- Work from the repository root. The reviewer runs headlessly in the same
  checkout (`codex exec review` or `claude -p`); it does not open an interactive
  session, a TUI, or a second worktree.
- The reviewer sees none of this conversation.
- Run in the foreground. A review can take several minutes; do not background it.
- Keep the reviewer read-only: use the native review mode or plan/manual
  permissions. It must not edit files.
- Save long output to a file and read it rather than moving it around in
  separate commands.

## Report

Verify every finding against the code before repeating or acting on it.
Reviewers hallucinate, and a style preference is not a finding unless the
repository enforces it.

Report:

1. Critical findings first, each with `file:line`, the failure mode, and why it
   matters.
2. Suggestions separately.
3. The harness and model that reviewed, e.g. `Reviewed by Codex (<model>)`.
4. Findings you rejected as incorrect, with the reason, so the user can judge.

Do not edit files unless the user asks for fixes. If they do, fix, run the
relevant tests, and re-review the final diff.
