## Git Staging

- Stage explicit paths only: `git add <path> [<path> …]`. Never use `git add -A`,
  `git add --all`, `git add .`, `git add -u`, or `git commit -a`; they sweep in
  unrelated working-tree changes.
- Run `git status --short` before staging and build the path list from what the
  task actually touched.
- Staging for a build is not staging for a commit. Nix flakes only see files
  git tracks, so a new file may need `git add -N` before a switch; that does
  not mean it belongs in the next commit.
- Before committing, re-read the index with `git diff --cached --stat` and
  unstage anything the task did not touch.
