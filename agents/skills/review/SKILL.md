---
name: review
description: Reviews the current working-tree changes with another vendor's model and harness — Antigravity (Gemini Neon) from Claude Code, Claude Code from Antigravity, Codex or OpenCode. Use when the user asks for a code review ("review", "レビューして", "コードレビュー", "この変更を見て"), before opening a PR, or when a change needs an independent second opinion.
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
| Claude Code | Antigravity CLI (`agy`, Gemini Neon) |
| Antigravity | Claude Code CLI (`claude -p`) |
| Codex | Claude Code CLI (`claude -p`) |
| OpenCode | Claude Code CLI (`claude -p`) |

OpenCode reviews with Claude by default. Use Antigravity instead only when the
OpenCode session already runs a Claude model, Claude is unavailable, or the user
asks for it.

Codex is no longer a reviewer: its subscription is effectively cancelled, and
this skill keeps no Codex command. If the user names Codex, say so and ask how
to proceed.

Never start the CLI of the harness you are running in. If the harness is not
tied to a model vendor (OpenCode), also prefer a model vendor different from the
one you are running. If the other CLI is missing or unauthenticated, say so and
stop; do not silently self-review.

Read [references/antigravity.md](references/antigravity.md) or
[references/claude.md](references/claude.md) for the exact command. Both take a
prompt, so also read [references/brief.md](references/brief.md).

## Models

Pass the model below explicitly, since a reviewer's own default may be something
else, and swap it only when the user names another. Prefer family aliases over
dated or effort-suffixed ids.

Effort and other options stay at the provider default. Raise them only when the
user asks; a large or security-sensitive diff is not enough on its own.

- Antigravity: `gemini-4-neon`, at the provider's default thinking level.
- Claude: `opus`.

## Scope

Review what is in the working tree now: staged, unstaged, and untracked changes.
Inspect it before calling the reviewer:

```sh
git status --short --untracked-files=all
git diff HEAD
git diff --cached --stat
```

- CLI reviewers (Claude, Antigravity): pass `git diff HEAD` as the scope and
  list the untracked files so the reviewer reads them directly.
- If the user names a specific commit, review that instead with
  `git show <sha>`.

If the working tree is clean, say so and stop; do not invent a scope. Do not
review a branch or a PR unless the user explicitly changes the request.

## Run it

- Work from the repository root. The reviewer runs headlessly in the same
  checkout (`agy -p` or `claude -p`); it does not open an interactive session,
  a TUI, or a second worktree.
- The reviewer sees none of this conversation.
- Run in the foreground. A review can take several minutes; do not background it.
- The brief tells the reviewer not to edit files.
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
3. The harness and model that reviewed, e.g. `Reviewed by Antigravity (gemini-4-neon)`.
4. Findings you rejected as incorrect, with the reason, so the user can judge.

Do not edit files unless the user asks for fixes. If they do, fix, run the
relevant tests, and re-review the final diff.
