# dotfiles

Supports **macOS** and **Linux** (Ubuntu/Debian).

## Installation

```bash
git clone --recursive https://github.com/satotek/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

## Nix Migration (WIP)

This repo now has a flake-based Nix entrypoint for macOS:

- `flake.nix`
- `hosts/darwin/default.nix`
- `modules/darwin/system.nix`
- `modules/home/common.nix`
- `modules/home/darwin.nix`
- `modules/home/linux.nix`

The current migration keeps the existing `config/*` layout and lets Home Manager
link those files from `~/dotfiles`, so edits in the repo still show up
immediately.

Bootstrap on this machine after installing Nix:

```bash
cd ~/dotfiles
sudo nix run nix-darwin/master#darwin-rebuild -- switch --flake ~/dotfiles#nosuke-M5-MBP
```

After that, apply changes with:

```bash
cd ~/dotfiles
sudo darwin-rebuild switch --flake ~/dotfiles#nosuke-M5-MBP
```

## Structure

```
dotfiles/
├── config/             # -> ~/.config/
│   ├── git/            # Git configuration
│   ├── nvim/           # Neovim (LazyVim)
│   ├── profile         # XDG environment variables
│   ├── wget/           # Wget configuration
│   └── zsh/            # Zsh configuration (zinit auto-install)
├── hosts/
│   └── darwin/
│       └── default.nix # Host entrypoint while using a single Mac
├── modules/
│   ├── darwin/
│   │   └── system.nix  # Shared nix-darwin system module
│   └── home/
│       ├── common.nix  # Shared Home Manager config and dotfile links
│       ├── darwin.nix  # macOS-specific Home Manager packages
│       └── linux.nix   # Linux-specific Home Manager packages
├── scripts/
│   ├── create-dirs.sh
│   ├── install-deps.sh        # OS auto-detection wrapper
│   ├── install-deps-linux.sh  # Linux (apt)
│   ├── install-deps-macos.sh  # macOS (Homebrew)
│   ├── install-haskell-ghcup.sh # Haskell toolchain (ghcup)
│   ├── setup-xdg.sh
│   └── symlink.sh
├── flake.nix
└── install.sh
```

## Post-installation

Copy the git config template and set your name and email:

```bash
cp ~/dotfiles/config/git.local.example ~/.config/git.local
```

Then edit `~/.config/git.local`:

```ini
[user]
    name = Your Name
    email = your@email.com
```

Optional local Zsh overrides can live outside the managed `config/zsh/` directory:

```bash
cp ~/dotfiles/config/zsh.local.example ~/.config/zsh.local
```

Create `~/.config/secrets` for API keys and other sensitive data (not tracked by git):

```bash
export AZURE_OPENAI_API_KEY='your_api_key'
export OTHER_SECRET='...'
```

Local-only or generated files are intentionally kept out of git, including:

- `~/.config/git.local`
- `~/.config/zsh.local`
- `~/.config/secrets`
- `$XDG_CACHE_HOME/zsh/.zcompdump`

## Features

- XDG Base Directory compliant
- Zsh with zinit (auto-installed on first launch)
- Neovim with LazyVim
- Powerlevel10k prompt
- Haskell toolchain via ghcup (ghc/cabal/hls/stack)
