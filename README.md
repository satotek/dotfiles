# dotfiles

## Installation

```bash
git clone --recursive https://github.com/satotek/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
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
├── scripts/
│   ├── create-dirs.sh
│   ├── install-deps.sh
│   ├── setup-xdg.sh
│   └── symlink.sh
└── install.sh
```

## Post-installation

Set your name and email in `~/.config/git/config`:

```ini
[user]
    name = <your_name>
    email = <your_email>
```

Create `~/.config/secrets` for API keys and other sensitive data (not tracked by git):

```bash
export AZURE_OPENAI_API_KEY='your_api_key'
export OTHER_SECRET='...'
```

## Features

- XDG Base Directory compliant
- Zsh with zinit (auto-installed on first launch)
- Neovim with LazyVim
- Powerlevel10k prompt
