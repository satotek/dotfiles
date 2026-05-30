# dotfiles

日本語版: [README.md](README.md)

Personal dotfiles managed with Nix Flakes.
This repo uses `nix-darwin + Home Manager` on macOS and standalone `Home Manager` on Linux.

## Supported platforms

- macOS
- Linux
  - primarily Ubuntu / Debian-like environments
  - intended to work on Azure VMs and Linux desktop environments

## Approach

- Keep Nix-related configuration under `nix/`
- Group each tool under `nix/programs/<tool>/`
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

First apply:

```bash
git clone --recursive https://github.com/satotek/dotfiles.git ~/dotfiles
cd ~/dotfiles
sudo nix run nix-darwin/master#darwin-rebuild -- switch --flake "path:$PWD#nosuke-M5-MBP"
```

Subsequent applies:

```bash
cd ~/dotfiles
sudo darwin-rebuild switch --flake "path:$PWD#nosuke-M5-MBP"
```

### Linux x86_64

`nosuke`:

```bash
git clone --recursive https://github.com/satotek/dotfiles.git ~/dotfiles
cd ~/dotfiles
NIX_CONFIG='experimental-features = nix-command flakes' \
nix run home-manager/master -- switch -b backup --flake "path:$PWD#nosuke@linux-x86_64"
```

`azureuser`:

```bash
git clone --recursive https://github.com/satotek/dotfiles.git ~/dotfiles
cd ~/dotfiles
NIX_CONFIG='experimental-features = nix-command flakes' \
nix run home-manager/master -- switch -b backup --flake "path:$PWD#azureuser@linux-x86_64"
```

### Linux aarch64

`nosuke`:

```bash
git clone --recursive https://github.com/satotek/dotfiles.git ~/dotfiles
cd ~/dotfiles
NIX_CONFIG='experimental-features = nix-command flakes' \
nix run home-manager/master -- switch -b backup --flake "path:$PWD#nosuke@linux-aarch64"
```

`azureuser`:

```bash
git clone --recursive https://github.com/satotek/dotfiles.git ~/dotfiles
cd ~/dotfiles
NIX_CONFIG='experimental-features = nix-command flakes' \
nix run home-manager/master -- switch -b backup --flake "path:$PWD#azureuser@linux-aarch64"
```

## Local configuration

Git identity:

```bash
cp ~/dotfiles/nix/programs/git/git.local.example ~/.config/git.local
```

Edit `~/.config/git.local`:

```ini
[user]
    name = Your Name
    email = your@email.com
```

Optional local Zsh overrides:

```bash
cp ~/dotfiles/nix/programs/zsh/zsh.local.example ~/.config/zsh.local
```

Secrets:

```bash
export AZURE_OPENAI_API_KEY='your_api_key'
export OTHER_SECRET='...'
```

You can also keep them in `~/.config/secrets`.

## Files intentionally kept out of git

- `~/.config/git.local`
- `~/.config/zsh.local`
- `~/.config/secrets`
- `$XDG_CACHE_HOME/zsh/.zcompdump`

## Repository layout

```text
dotfiles/
├── nix/
│   ├── hosts/
│   │   ├── darwin/
│   │   └── linux/
│   ├── darwin/
│   │   └── system.nix
│   ├── home-manager/
│   │   ├── default.nix
│   │   ├── darwin.nix
│   │   ├── linux.nix
│   │   └── home/
│   └── programs/
│       ├── common.nix
│       ├── darwin.nix
│       ├── linux.nix
│       ├── git/
│       ├── karabiner/
│       ├── lazygit/
│       ├── nvim/
│       ├── sheldon/
│       ├── starship/
│       ├── tmux/
│       ├── wezterm/
│       ├── wget/
│       └── zsh/
├── config/
│   └── nvim/
├── flake.nix
└── flake.lock
```

## Current state

- macOS is usable with `nix-darwin`
- Linux uses standalone `Home Manager` outputs
- Shared Home Manager logic lives under `nix/home-manager/`
- Shared and OS-specific packages live in `nix/programs/common.nix` and `nix/programs/darwin.nix` / `linux.nix`
- `nix/programs/common.nix` plus the OS-specific `darwin.nix` / `linux.nix` files bundle the per-tool modules under `nix/programs/<tool>/`
- Tool-specific packages live alongside each tool module under `nix/programs/<tool>/`
- `git`, `tmux`, `wget`, and most of `zsh` are already managed with native Home Manager options
- Zsh plugins are managed with `sheldon`, and the prompt is managed with `starship`
- macOS GUI apps are managed through the `nix-darwin` Homebrew module
- `lazygit`, `nvim`, `wezterm`, and `karabiner` use tool-local `files/` directories referenced by Home Manager

## Included tools and configs

- XDG Base Directory support
- Zsh
- Sheldon
- Starship
- Neovim
- tmux
- WezTerm
- Karabiner-Elements
- Git / lazygit
- CLI tools such as ripgrep, fd, fzf, yazi, and zoxide
