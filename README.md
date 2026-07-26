# dotfiles

Personal dotfiles managed with Nix Flakes.
This repo uses `nix-darwin + Home Manager` on macOS and standalone `Home Manager` on Linux.

## Supported platforms

- macOS
- Linux
  - primarily Ubuntu / Debian-like environments
  - intended to work on Azure VMs and Linux desktop environments

## Approach

- Keep Nix-related configuration under `nix/`
- Group reusable logic by purpose: `home/` (core home setup), `platforms/` (OS-specific), `presets/` (package bundles), `programs/` (one file per tool), `data/` (pure data shared across tools)
- Manage `git`, `tmux`, `wget`, and most of `zsh` with native Home Manager options
- Use `Home Manager` for repo-backed configs as well
- Manage CLI tools with Nix instead of shell installer scripts
- Keep local-only settings and secrets outside the repo

The old shell-based installer flow has been removed.

## Assumptions

- This repo is cloned to `~/dotfiles`
- This repo uses flakes, so `nix-command` and `flakes` must be enabled
- Linux outputs are currently provided for `nosuke` and `azureuser`
- If you use another username, add another output in `flake.nix`

## Install Nix

This repo assumes [Determinate Nix](https://docs.determinate.systems/). At install time we also inject the binary caches we trust via `--extra-conf`. Without this, the `cache.numtide.com` cache declared by flakes such as `llm-agents.nix` is treated as untrusted and ignored, so Rust packages like `codex` are rebuilt from source with `cargo` on every switch.

macOS / Linux:

```bash
curl -fsSL https://install.determinate.systems/nix | sh -s -- install \
  --extra-conf "trusted-users = root $(id -un)" \
  --extra-conf "extra-substituters = https://cache.numtide.com" \
  --extra-conf "extra-trusted-substituters = https://cache.numtide.com" \
  --extra-conf "extra-trusted-public-keys = niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
```

Trust is a property of the machine's Nix install, not of the dotfiles, so we pass it to the installer rather than declaring it in the repo. To inspect or add caches later, append to `/etc/nix/nix.custom.conf` and reload the daemon with `sudo launchctl kickstart -k system/systems.determinate.nix-daemon` (macOS).

After installation, restart your shell or reload the Nix profile script. Determinate Nix enables `nix-command` / `flakes` by default, so the manual step below is usually unnecessary (kept as a fallback when a fresh install hasn't picked it up yet).

Since this repo uses flakes, enable `nix-command` and `flakes` if they are not enabled yet.

```bash
mkdir -p ~/.config/nix
grep -qxF 'experimental-features = nix-command flakes' ~/.config/nix/nix.conf 2>/dev/null \
  || printf '%s\n' 'experimental-features = nix-command flakes' >> ~/.config/nix/nix.conf
```

Check:

```bash
nix --version
nix config show | grep experimental-features
# Is the trust in effect (avoids codex's cargo build)? If empty, you forgot --extra-conf at install time.
nix config show | grep cache.numtide.com
```

If `nix run` still fails with `experimental Nix feature 'nix-command' is disabled` or `flakes is disabled`, the config has not taken effect yet. Restart your shell, or set `NIX_CONFIG` once. This is more reliable than `--extra-experimental-features` here because `home-manager` invokes `nix` internally as well.

```bash
NIX_CONFIG='experimental-features = nix-command flakes' \
  nix run home-manager/master -- switch --flake "path:$PWD#nosuke@linux-aarch64"
```

This is not Ubuntu-specific. It can happen on any fresh Nix install on macOS or Linux before `nix-command` / `flakes` are enabled and picked up.

After one successful `home-manager switch`, this repo also manages `~/.config/nix/nix.conf`, so you normally do not need to keep prefixing commands with `NIX_CONFIG=...`.

## Setup

### macOS

macOS is split into two layers:

- System layer (`darwinConfigurations`): Homebrew casks, fonts, macOS settings. Needs `sudo`.
- Home layer (`homeConfigurations`): everything under Home Manager. No `sudo`.

First apply:

```bash
git clone https://github.com/satotek/dotfiles.git ~/dotfiles
cd ~/dotfiles
# System layer
sudo nix run nix-darwin/master#darwin-rebuild -- switch --flake "path:$PWD#nosuke-M5-MBP"
# Home layer (no sudo)
nix run home-manager/master -- switch --flake "path:$PWD#nosuke@nosuke-M5-MBP"
```

Subsequent applies (both commands are installed by the home layer):

```bash
nix-switch     # home layer, no sudo — day-to-day changes live here
darwin-switch  # system layer (sudo) — only when casks/fonts/macOS settings change
```

### Linux x86_64

`nosuke`:

```bash
git clone https://github.com/satotek/dotfiles.git ~/dotfiles
cd ~/dotfiles
NIX_CONFIG='experimental-features = nix-command flakes' \
nix run home-manager/master -- switch -b backup --flake "path:$PWD#nosuke@linux-x86_64"
```

`azureuser`:

```bash
git clone https://github.com/satotek/dotfiles.git ~/dotfiles
cd ~/dotfiles
NIX_CONFIG='experimental-features = nix-command flakes' \
nix run home-manager/master -- switch -b backup --flake "path:$PWD#azureuser@linux-x86_64"
```

### Linux aarch64

`nosuke`:

```bash
git clone https://github.com/satotek/dotfiles.git ~/dotfiles
cd ~/dotfiles
NIX_CONFIG='experimental-features = nix-command flakes' \
nix run home-manager/master -- switch -b backup --flake "path:$PWD#nosuke@linux-aarch64"
```

`azureuser`:

```bash
git clone https://github.com/satotek/dotfiles.git ~/dotfiles
cd ~/dotfiles
NIX_CONFIG='experimental-features = nix-command flakes' \
nix run home-manager/master -- switch -b backup --flake "path:$PWD#azureuser@linux-aarch64"
```

### Other outputs

Additional Home Manager outputs exist for specific hosts. Use the matching flake attribute:

- `nosuke@nosuke-windows` (WSL)
- `azureuser@gem-ai`

List every available configuration with:

```bash
nix flake show
```

## Local configuration

Git identity:

```bash
cp ~/dotfiles/.config/git.local.example ~/.config/git.local
```

Edit `~/.config/git.local`:

```ini
[user]
    name = Your Name
    email = your@email.com
```

Azure DevOps SSH authentication uses a separate RSA key on each machine. Add
each public key to the Azure DevOps profile, rather than sharing private keys
through this repository or `sops`.

On a machine that stores the private key locally:

```bash
ssh-keygen -t rsa -b 3072 -f ~/.ssh/azure-devops -C "Azure DevOps $(hostname)"
```

On macOS with the 1Password SSH Agent, keep the private key in 1Password and
save only its public key as `~/.ssh/azure-devops.pub`. Git automatically selects
`~/.ssh/azure-devops` when a local private key exists, or the `.pub` file when
the matching private key is supplied by an SSH agent.

Azure Repos remotes use this format:

```text
git@ssh.dev.azure.com:v3/<organization>/<project>/<repository>
```

Optional local Zsh overrides:

```bash
cp ~/dotfiles/.config/zsh.local.example ~/.config/zsh.local
```

Secrets:

Secrets that should be managed by this repo live under `secrets/*.yaml` and are
encrypted with `sops`. The creation rule in `.sops.yaml` uses this GCP Cloud
KMS key:

```text
projects/nosuke-net/locations/global/keyRings/sops/cryptoKeys/dotfiles
```

Each environment decrypts with GCP Application Default Credentials (ADC). Run
`gcloud auth application-default login` once on each machine before using GCP
KMS.

`google-cloud-sdk` is included in the shared `devtools` preset. The GCP project
is `nosuke-net`; ADC should use the same quota project:

```bash
gcloud config set project nosuke-net
gcloud auth application-default set-quota-project nosuke-net
```

Currently managed secrets:

- `secrets/cloudflare.yaml` -> `~/.config/cloudflare/cloudflare-infra.env`
- `secrets/context7.yaml` -> `~/.config/context7/api-key` when the file exists

Existing encrypted files do not gain a new KMS recipient merely by changing
`.sops.yaml`; rewrap them on a machine that can already decrypt the file:

```bash
sops updatekeys secrets/*.yaml
```

`nix/home-manager/programs/sops.nix` is imported by the shared agents preset.
Context7 is therefore materialized on every host that uses that preset, while
the Cloudflare secret remains restricted to macOS. Each participating host
needs GCP ADC credentials before `nix-switch` can decrypt its secrets.

The GCP billing account has a monthly JPY 100 budget for `nosuke-net`, with
current-spend alerts at 50%, 80%, and 100%. A budget sends notifications; it
does not cap or stop spending.

Local-only shell secrets that should not be repo-managed can still be kept in `~/.config/secrets`.

## Files intentionally kept out of git

- `~/.config/git.local`
- `~/.ssh/azure-devops`
- `~/.ssh/azure-devops.pub`
- `~/.config/zsh.local`
- `~/.config/secrets`
- `$XDG_CACHE_HOME/zsh/.zcompdump`

## Repository layout

```text
dotfiles/
├── nix/
│   ├── home-manager/
│   │   ├── default.nix       # entry point for the shared Home Manager config
│   │   ├── data/             # pure data shared across tools (e.g. mcp-servers.nix)
│   │   ├── home/             # core home setup (shell, profile, directories, nix, migrations)
│   │   ├── platforms/        # darwin.nix / linux.nix
│   │   ├── presets/          # package bundles: base / agents / cloud / language toolchains
│   │   └── programs/         # one file per tool (git, zsh, nvim, direnv, claude-code, ...)
│   ├── hosts/
│   │   ├── darwin/
│   │   └── linux/            # azureuser.nix / nosuke.nix
│   └── nix-darwin/           # system.nix / homebrew.nix
├── .github/
│   └── workflows/            # CI: automatic flake.lock updates (see Automation)
├── .config/                  # repo-backed configs (nvim, lazygit, ...)
├── flake.nix
└── flake.lock
```

## Current state

- macOS is usable with `nix-darwin`
- Linux uses standalone `Home Manager` outputs
- Shared Home Manager logic lives under `nix/home-manager/`
- Packages are grouped into presets: `base.nix` (always-on CLI tools), `devtools.nix`, and `webdevtools.nix`
- Each tool's settings live in a single file under `nix/home-manager/programs/<tool>.nix`
- `git`, `tmux`, `wget`, and most of `zsh` are managed with native Home Manager options
- Zsh plugins are managed with `sheldon`, and the prompt is managed with `starship`
- Shell integrations for `zoxide`, `starship`, and `sheldon` are cached at startup for faster shell init
- `direnv` (with `nix-direnv`) is managed under `programs/direnv.nix`
- Ghostty and its settings are managed with native Home Manager options
- Agent tooling — Claude Code, Codex, Antigravity CLI, Grok, agent skills, and MCP servers — is managed under `programs/` (with the MCP server definitions shared via `data/mcp-servers.nix`)
- macOS GUI apps are managed through the `nix-darwin` Homebrew module under `nix/nix-darwin/`
- `flake.lock` is updated automatically by GitHub Actions (see Automation)

## Automation

`flake.lock` is kept up to date by GitHub Actions (under `.github/workflows/`). Two workflows open pull requests, and each one builds the Linux Home Manager configuration as a check before merging, so a broken update never lands on `main`:

- `update-flake-ai.yml` — daily. Updates the fast-moving AI / agent inputs (`llm-agents`, `agent-browser`, `agent-skills`, `anthropic-skills`, `herdr-skill`, `mattpocock-skills`, `vercel-*-skills`).
- `update-flake-stable.yml` — every 3 days. Updates the base inputs (`nixpkgs`, `nix-darwin`, `home-manager`).

Both configure the `cache.numtide.com` binary cache in CI so AI tools are downloaded rather than rebuilt from source during the validation build. Validated PRs are auto-merged; you still apply them per machine with `git pull` and a switch (`nix-switch` / `darwin-switch`). The repo is public, so GitHub-hosted runners are free.

## Included tools and configs

- XDG Base Directory support
- Zsh
- Sheldon
- Starship
- Neovim
- tmux
- WezTerm
- Ghostty
- Karabiner-Elements
- Git / lazygit
- direnv (with nix-direnv)
- Claude Code / Codex / Antigravity CLI / Grok / agent skills / MCP servers
- herdr (agent multiplexer — a tmux-like TUI for AI coding agents)
- rumdl (Markdown linter/formatter, used as the Neovim Markdown LSP)
- dotbench (Zsh / Neovim startup benchmark)
- CLI tools such as ripgrep, fd, fzf, yazi, and zoxide

## Startup benchmark

`dotbench` measures interactive Zsh and headless Neovim startup times. It runs
each command once to warm filesystem caches, then reports statistics from 10
measured runs:

```bash
dotbench
```

Pass a positive integer to change the number of measured runs:

```bash
dotbench 20
```

Example output:

```text
Startup benchmark (10 runs, one warm-up; lower is better)
zsh interactive  min 41.2 ms  median 42.2 ms  mean 42.2 ms  max 43.4 ms
nvim headless    min 26.1 ms  median 26.8 ms  mean 26.8 ms  max 27.9 ms
```

Use the median when comparing changes; it is less affected by occasional
background activity than the mean or maximum. `dotbench` is installed by the
shared Home Manager `base` preset, so it is available after `nix-switch` or the
equivalent Home Manager switch for the current host.

## Insight

### Activity

<a href="https://next.ossinsight.io/widgets/official/compose-last-28-days-stats?repo_id=1105658656" target="_blank" align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://next.ossinsight.io/widgets/official/compose-last-28-days-stats/thumbnail.png?repo_id=1105658656&image_size=auto&color_scheme=dark" width="655" height="auto">
    <img alt="Performance Stats of satotek/dotfiles - Last 28 days" src="https://next.ossinsight.io/widgets/official/compose-last-28-days-stats/thumbnail.png?repo_id=1105658656&image_size=auto&color_scheme=light" width="655" height="auto">
  </picture>
</a>

### Changes

<a href="https://next.ossinsight.io/widgets/official/analyze-repo-loc-per-month?repo_id=1105658656" target="_blank" align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://next.ossinsight.io/widgets/official/analyze-repo-loc-per-month/thumbnail.png?repo_id=1105658656&image_size=auto&color_scheme=dark" width="721" height="auto">
    <img alt="Lines of Code Changes of satotek/dotfiles" src="https://next.ossinsight.io/widgets/official/analyze-repo-loc-per-month/thumbnail.png?repo_id=1105658656&image_size=auto&color_scheme=light" width="721" height="auto">
  </picture>
</a>

<!-- Made with [OSS Insight](https://ossinsight.io/) -->
