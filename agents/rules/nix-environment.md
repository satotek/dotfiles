## Nix Environment

- Tools come from the Home Manager profile, or from a project flake loaded by
  direnv. Agent shells often do not load direnv; run project commands with
  `direnv exec . <cmd>` instead of assuming they are on PATH. If direnv
  refuses, `direnv allow` that project rather than skipping its environment.
- Project-local Node tools live in `node_modules/.bin`, which is not on PATH.
  Run them through that project's package manager (`pnpm exec`, `bunx`), not
  bare (`turbo`, `tsc`). Hooks and scripts must do the same.
- A missing command is not a reason to install it. command-not-found only
  prints a hint. Look up providers with `, -p <cmd>` (comma) and run one
  without installing: `nix shell nixpkgs#<attr> --command <cmd>`. `nixpkgs`
  here is the Home Manager pin, not floating unstable. Skip `tests.*` hits.
- Do not run bare `, <cmd>` when `, -p` lists more than one package. The
  picker is interactive and hangs without a terminal. Never pass `-i` /
  `--install`, and do not `nix profile install` or `nix-env` without asking.
- Check the project's `flake.nix` / `.envrc` before a one-off. A project tool
  belongs there, not in a temporary `nix shell`.
