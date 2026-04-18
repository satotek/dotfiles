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

- Keep application configs under `config/*`
- Link repo-backed configs from `~/dotfiles` through `Home Manager`
- Manage CLI tools with Nix instead of shell installer scripts
- Keep local-only settings and secrets outside the repo

The old shell-based installer flow has been removed.

## Assumptions

- This repo is cloned to `~/dotfiles`
- Nix is already installed
- Linux outputs are currently provided for `nosuke` and `azureuser`
- If you use another username, add another output in `flake.nix`

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
nix run home-manager/master -- switch --flake "path:$PWD#nosuke@linux-x86_64"
```

`azureuser`:

```bash
git clone --recursive https://github.com/satotek/dotfiles.git ~/dotfiles
cd ~/dotfiles
nix run home-manager/master -- switch --flake "path:$PWD#azureuser@linux-x86_64"
```

### Linux aarch64

`nosuke`:

```bash
git clone --recursive https://github.com/satotek/dotfiles.git ~/dotfiles
cd ~/dotfiles
nix run home-manager/master -- switch --flake "path:$PWD#nosuke@linux-aarch64"
```

`azureuser`:

```bash
git clone --recursive https://github.com/satotek/dotfiles.git ~/dotfiles
cd ~/dotfiles
nix run home-manager/master -- switch --flake "path:$PWD#azureuser@linux-aarch64"
```

## Local configuration

Git identity:

```bash
cp ~/dotfiles/config/git.local.example ~/.config/git.local
```

Edit `~/.config/git.local`:

```ini
[user]
    name = Your Name
    email = your@email.com
```

Optional local Zsh overrides:

```bash
cp ~/dotfiles/config/zsh.local.example ~/.config/zsh.local
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
├── config/             # actual app configs
│   ├── git/
│   ├── lazygit/
│   ├── nvim/
│   ├── profile
│   ├── tmux/
│   ├── wezterm/
│   ├── wget/
│   └── zsh/
├── hosts/
│   └── darwin/
│       └── default.nix
├── modules/
│   ├── darwin/
│   │   └── system.nix
│   └── home/
│       ├── common.nix
│       ├── darwin.nix
│       └── linux.nix
├── flake.nix
└── flake.lock
```

## Current state

- macOS is usable with `nix-darwin`
- Linux uses standalone `Home Manager` outputs
- Shared logic lives in `modules/home/common.nix`
- Some apps are still managed by linking the existing `config/*` files rather than rewriting everything into native Nix options

## Included tools and configs

- XDG Base Directory support
- Zsh
- Neovim
- tmux
- WezTerm
- Git / lazygit
- CLI tools such as ripgrep, fd, fzf, and yazi
