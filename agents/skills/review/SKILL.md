---
name: review
description: Reviews the current working-tree changes with another vendor's model and harness — Antigravity (Gemini Neon) from Claude Code, Claude Code from Antigravity, Codex or OpenCode, and a delegated child thread inside T3 Code. Use when the user asks for a code review ("review", "レビューして", "コードレビュー", "この変更を見て"), before opening a PR, or when a change needs an independent second opinion.
---

# Review

A review from the model and harness that wrote the change catches little. Send
the change to another vendor's model, another vendor's harness, or both.

This personal skill shadows any project skill with the same name. Read
`.claude/skills/review/SKILL.md` or `.agents/skills/review/SKILL.md` first when
it exists, plus the repository's review rules in `CLAUDE.md` / `AGENTS.md`, and
let them win.

## Where you run

Two paths, picked by what is available, not by preference:

- **Inside T3 Code** (`delegate_task` from the `t3-code` MCP server is visible):
  review as a delegated child thread. Do not start a CLI. See
  [Review inside T3 Code](#review-inside-t3-code).
- **Outside T3 Code** (no `t3-code` tools): use another harness's CLI as below.

Tools can load late in T3 Code. Try the named tool once before concluding it is
absent. If delegation is unavailable, say so rather than quietly falling back
to a CLI.

## Pick the reviewer

Outside T3 Code, use the harness you are **not** running in:

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

## Review inside T3 Code

The reviewer becomes a child thread the user can watch, so keep it read-only and
free of CLI calls.

1. Call `orchestrator_capabilities` once per thread, before the first
   `delegate_task`, and take the provider and model from its live catalogue.
   Pick a different vendor from the model that wrote the change:
   - Claude writes: Antigravity (`antigravity`, `gemini-4-neon`) reviews.
   - Antigravity writes: Claude reviews. If Claude is unavailable, say so and
     stop; never let Antigravity review its own change.
   - Any other harness (Codex, OpenCode, Grok, Cursor, Pi, ACP agents) writes:
     Claude reviews, falling back to Antigravity only when Claude is
     unavailable. If that harness ran a Claude model, Antigravity reviews.
   Never pick Codex as the reviewer on your own; if the user names it, say its
   subscription is effectively cancelled and ask how to proceed.
2. Resolve the scope first (see [Scope](#scope)) and put it in the `task`: the
   child sees none of this conversation.
3. Call `delegate_task` with:
   - `role: "review"`, `interactionMode: "plan"`, `mode: "wait"`, and
     `isolation: "shared"` — the working tree lives in the parent checkout, so a
     worktree child would start from the last commit and miss uncommitted edits.
   - `target.providerInstanceId` and `target.model` always set. Omit
     `target.options` so the provider's default effort applies; pass an option
     only when the user names one.
   - A fresh `clientRequestId` for each round.
   - A self-contained brief: the diff or `git diff HEAD`, the untracked paths,
     the repository review rules, what to check, and the answer shape.
   - For an Antigravity child, paste the diff itself and tell it not to run
     commands. T3 Code gives it no auto-approve mode, so it asks for approval
     before every command, even `git diff`, and waits on the user; reading
     files needs no approval. End the brief with the last paragraph of the
     template in `brief.md` so it answers with the review rather than a plan.
4. A child question ends the wait: read it with `t3_pending_request` on the child
   thread and answer, or let the user answer. A pending approval also ends the
   wait, but this tool cannot grant it: name the child and request in your reply
   and let the user approve in the UI. A `waitTimedOut` child keeps running: keep
   the task ID and let the completion notification wake you. Do not poll.
5. For a second round, call `delegate_task` again with the original brief, its
   findings, and your responses — not a follow-up message into the child.
6. Report the harness and model from the child, as below.

## Models

Inside T3 Code the capabilities catalogue is authoritative; use its model ids.
Outside T3 Code, pass the model below explicitly, since a reviewer's own
default may be something else, and swap it only when the user names another.
Prefer family aliases over dated or effort-suffixed ids.

Effort and other options stay at the provider default. Raise them only when the
user asks; a large or security-sensitive diff is not enough on its own.

- Antigravity: `gemini-4-neon`, at the provider's default thinking level.
  Inside T3 Code it is provider `antigravity`, model `gemini-4-neon`.
- Claude: `opus`.

## Scope

Review what is in the working tree now: staged, unstaged, and untracked changes.
Inspect it before calling the reviewer:

```sh
git status --short --untracked-files=all
git diff HEAD
git diff --cached --stat
```

- Inside T3 Code, this scope becomes the child's `task` instead of a CLI flag.
- CLI reviewers (Claude, Antigravity): pass `git diff HEAD` as the scope and
  list the untracked files so the reviewer reads them directly.
- If the user names a specific commit, review that instead with
  `git show <sha>`.

If the working tree is clean, say so and stop; do not invent a scope. Do not
review a branch or a PR unless the user explicitly changes the request.

## Run it (outside T3 Code)

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
