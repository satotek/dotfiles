## Nix Environment

- Tools come from Nix (home-manager profile) and per-project flakes loaded by
  direnv. Agent shells may not have direnv's environment loaded.
- Project-local Node tools live in `node_modules/.bin`, which is not on PATH.
  Run them through the package manager (`pnpm <script>`, `pnpm exec <bin>`), not
  bare (`turbo`, `tsc`). Hooks and scripts must do the same.
- If a command is missing, check the project's `flake.nix` / `.envrc` before
  installing anything globally, and do not install global packages without
  asking.
