# Review brief

Use this when the reviewer takes a prompt rather than a native scope flag:
Claude Code, or `codex exec` as the fallback. The reviewer sees none of this
conversation, so the brief must be self-contained.

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
```

## Example

```text
You are reviewing the current working-tree changes in /home/azureuser/dotfiles
for correctness, not style.

Scope: `git diff HEAD`
Untracked files: agents/skills/review/SKILL.md, agents/skills/review/references/codex.md
```

If the user names a commit, replace the scope with `git show <sha>` and set
untracked files to `none`.

## Untracked files

`git diff` does not include untracked files. List them with
`git ls-files --others --exclude-standard` and name them in the brief so the
reviewer reads them directly. Never stage the user's work just for a review.
