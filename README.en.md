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

This repo assumes the official multi-user install.

macOS / Linux:

```bash
curl -L https://nixos.org/nix/install | sh -s -- --daemon
```

After installation, restart your shell or reload the Nix profile script.

Since this repo uses flakes, enable `nix-command` and `flakes` if they are not enabled yet.

```bash
mkdir -p ~/.config/nix
grep -qxF 'experimental-features = nix-command flakes' ~/.config/nix/nix.conf 2>/dev/null \
  || printf '%s\n' 'experimental-features = nix-command flakes' >> ~/.config/nix/nix.conf
```

Check:

```bash
nix --version
nix show-config | grep experimental-features
```

If `nix run` still fails with `experimental Nix feature 'nix-command' is disabled` or `flakes is disabled`, the config has not taken effect yet. Restart your shell, or set `NIX_CONFIG` once. This is more reliable than `--extra-experimental-features` here because `home-manager` invokes `nix` internally as well.

```bash
NIX_CONFIG='experimental-features = nix-command flakes' \
  nix run home-manager/master -- switch --flake "path:$PWD#nosuke@linux-aarch64"
```

This is not Ubuntu-specific. It can happen on any fresh Nix install on macOS or Linux before `nix-command` / `flakes` are enabled and picked up.

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
nix run home-manager/master -- switch -b backup --flake "path:$PWD#nosuke@linux-x86_64"
```

`azureuser`:

```bash
git clone --recursive https://github.com/satotek/dotfiles.git ~/dotfiles
cd ~/dotfiles
nix run home-manager/master -- switch -b backup --flake "path:$PWD#azureuser@linux-x86_64"
```

### Linux aarch64

`nosuke`:

```bash
git clone --recursive https://github.com/satotek/dotfiles.git ~/dotfiles
cd ~/dotfiles
nix run home-manager/master -- switch -b backup --flake "path:$PWD#nosuke@linux-aarch64"
```

`azureuser`:

```bash
git clone --recursive https://github.com/satotek/dotfiles.git ~/dotfiles
cd ~/dotfiles
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
- CLI tools such as ripgrep, fd, fzf, and yazi
