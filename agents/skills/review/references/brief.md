# Review brief

Both reviewers, Antigravity (`agy -p`) and Claude Code (`claude -p`), take
this brief as their prompt. The reviewer sees none of this conversation, so the
brief must be self-contained.

## Template

```text
You are reviewing the current working-tree changes in <absolute repo path> for
correctness, not style.

Scope: `git diff HEAD`
Untracked files: <list, or "none">

Do not edit files. Read the diff and enough surrounding code to judge each
change in context.

Report:
- Critical: bugs, data loss, security issues, broken behavior, or missing tests
  for the changed behavior.
- Suggestions: clarity, structure, performance.

Cite file:line for every finding. If you find nothing, say so explicitly. Do not
report style preferences unless the repository enforces them.

Your final message is the review itself. Do not write an implementation plan
or any file, and do not ask for approval.
```

The last paragraph matters for AGY in T3 Code's plan mode, where it otherwise
answers with an implementation plan and waits for approval.

## Example

```text
You are reviewing the current working-tree changes in /home/azureuser/dotfiles
for correctness, not style.

Scope: `git diff HEAD`
Untracked files: agents/skills/review/SKILL.md, agents/skills/review/references/antigravity.md
```

If the user names a commit, replace the scope with `git show <sha>` and set
untracked files to `none`.

## Antigravity inside T3 Code

An Antigravity child thread asks for approval before every command, even
`git diff`, so it cannot fetch the scope itself. Replace the `Scope:` line with
the diff itself, and say how to read the rest:

```text
Scope: the diff below. You cannot run commands; read changed, untracked, and
surrounding files with your file-reading tool.

~~~~~~diff
<output of git diff HEAD, or of git show <sha> for a named commit>
~~~~~~
```

The long tilde fence keeps a diff of Markdown files, which may hold their own
fences, from closing the block early.

## Untracked files

`git diff` does not include untracked files. List them with
`git ls-files --others --exclude-standard` and name them in the brief so the
reviewer reads them directly. Never stage the user's work just for a review.
