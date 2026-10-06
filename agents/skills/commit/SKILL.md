---
name: commit
description: Splits changes into small, independently revertable Conventional Commits with WHY-focused messages. Use when asked to commit ("commit", "コミットして", "コミットを分けて"), to write a commit message, or when finishing a unit of work.
---

# Commit

Commit changes as the smallest units that can each be reverted on their own.

## 0. Read the repository's own rules first

This personal skill shadows any project skill with the same name, so project rules would otherwise go unseen. Check these first and let them win:

- `.claude/skills/commit/SKILL.md` or `.agents/skills/commit/SKILL.md`: read it and follow its procedure.
- Commit and branch instructions in `CLAUDE.md` / `AGENTS.md`.
- `commitlint.config.*` (types, scopes, length limits) and hook config such as `lefthook.yml`.

## 1. Inspect the state

```sh
git status --short --untracked-files=all
git diff HEAD
git diff --cached --stat
git log --oneline -15
```

From `git log`, match the message language (English or Japanese), scope style, and granularity.

## 2. Split into units

- One reason per commit. Keep unrelated changes apart, and split review fixes by meaning rather than bundling them as "address review".
- For moves or extractions, include both sides and the reference updates in one commit.
- Treat a pre-populated index as untrusted (files may be staged for a build). Unstage anything outside the current unit with `git restore --staged <path>`.

## 3. Stage

- Whole file in the unit: name it with `git add <path>`.
- Part of a file: write a patch and apply it with `git apply --cached <patch>`.
- Never use `git add -A` / `.` / `-u` (they sweep in unrelated changes), `git add -p` (interactive), or `git commit -a`.

## 4. Write the message

```text
<type>(<scope>): <subject>

<body>
```

- Types: `feat` `fix` `docs` `refactor` `perf` `test` `build` `ci` `chore` `revert`.
- The diff shows HOW; the body explains WHY: why the change was needed and why this approach. Do not restate the diff.
- Omit the body when the subject alone says enough.
- Wrap body lines at 72 characters unless the repository sets its own limit.
- Follow the language and scope conventions found in step 1.

## 5. Commit and verify

- Let hooks run. Use `--no-verify` only when the user asks.
- If a hook fails, no commit was made. Fix the cause, re-stage, and commit again rather than amending.
- Confirm with `git show --stat HEAD` and `git status --short` that the content is as intended and nothing was left behind.

## Never

- Push without being asked.
- Rewrite published commits with amend or rebase; add follow-up commits instead.
- Decide branching on your own; follow repository rules and the user.
