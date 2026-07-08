# Maintenance Commands

この dotfiles を更新・検証するときによく使うコマンドをまとめる。

## Nix

| コマンド | 用途 |
|---|---|
| `nix flake show` | flake outputs を確認する |
| `nix fmt` | Nix ファイルを formatter で整形する |
| `nix flake check` | flake の基本チェックを走らせる |
| `nix build --no-link '.#homeConfigurations."nosuke@linux-x86_64".activationPackage'` | Linux Home Manager 構成をビルド検証する |
| `nix build --no-link '.#homeConfigurations."azureuser@linux-x86_64".activationPackage'` | Azure user 向け Linux 構成をビルド検証する |
| `nix build --no-link '.#homeConfigurations."azureuser@gem-ai".activationPackage'` | `gem-ai` 向け Linux 構成をビルド検証する |

## Apply

| コマンド | 用途 |
|---|---|
| `nix-switch` | Home Manager layer を適用する |
| `darwin-switch` | macOS system layer を適用する |
| `home-manager switch --flake "path:$PWD#azureuser@linux-x86_64"` | コマンドを直接指定して Home Manager を適用する |

## Neovim

| コマンド | 用途 |
|---|---|
| `nvim --headless '+Lazy! sync' +qa` | plugin の同期を headless で実行する |
| `nvim --headless '+checkhealth' +qa` | health check を headless で実行する |
| `nvim --startuptime /tmp/nvim.log +q` | 起動時間ログを取る |
| `nvim --headless --cmd 'set shadafile=NONE' '+lua print(vim.inspect(require("lazy.core.config").plugins["snacks.nvim"]))' +qa` | lazy.nvim 上の plugin 定義を確認する |

## Shell

| コマンド | 用途 |
|---|---|
| `zsh -i -c exit` | interactive zsh の起動確認 |
| `time zsh -i -c exit` | zsh 起動時間をざっくり測る |
| `sheldon lock --update` | Sheldon plugin lock を更新する |

## Git

| コマンド | 用途 |
|---|---|
| `git status --short --branch` | branch と作業ツリーの状態を見る |
| `git log --oneline --decorate --graph --left-right main...origin/main` | local / remote の分岐を確認する |
| `git fetch origin` | remote の状態を更新する |
