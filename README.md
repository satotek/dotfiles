# dotfiles

English version: [README.en.md](README.en.md)

Nix Flakes を使って管理している個人用 dotfiles です。
macOS では `nix-darwin + Home Manager`、Linux では standalone の `Home Manager` で使います。

## 対応環境

- macOS
- Linux
  - Ubuntu / Debian 系を想定
  - Azure VM や Linux desktop でも利用可能

## 方針

- Nix 関連の構成は `nix/` 配下にまとめる
- 各ツールの設定は `nix/programs/<tool>/` に寄せる
- `git`、`tmux`、`wget`、Zsh の主要部分は Home Manager の native option で管理する
- repo-backed な設定ファイルも `Home Manager` 経由で使う
- 依存ツールの導入は shell script ではなく Nix で管理する
- ローカル専用設定や secrets は repo の外に置く

旧来の `install.sh` などの shell installer は廃止済みです。

## 前提

- この repo は `~/dotfiles` に clone する前提です
- この repo は flake を使うため `nix-command` と `flakes` が必要です
- Linux 側は現在 `nosuke` と `azureuser` の出力を用意しています
- それ以外の username で使う場合は `flake.nix` にエントリ追加が必要です

## Nix の導入

公式の multi-user install を前提にしています。

macOS / Linux:

```bash
curl -L https://nixos.org/nix/install | sh -s -- --daemon
```

インストール後はいったん shell を開き直すか、Nix の profile script を読み直してください。

flake を使うので、未設定なら `nix-command` と `flakes` を有効にします。

```bash
mkdir -p ~/.config/nix
grep -qxF 'experimental-features = nix-command flakes' ~/.config/nix/nix.conf 2>/dev/null \
  || printf '%s\n' 'experimental-features = nix-command flakes' >> ~/.config/nix/nix.conf
```

確認:

```bash
nix --version
nix show-config | grep experimental-features
```

もし `nix run` 実行時に `experimental Nix feature 'nix-command' is disabled` や `flakes is disabled` が出たら、まだ設定が反映されていません。shell を開き直すか、初回だけ `NIX_CONFIG` で明示します。`home-manager` は内部でも `nix` を呼ぶため、`--extra-experimental-features` よりこちらの方が確実です。

```bash
NIX_CONFIG='experimental-features = nix-command flakes' \
  nix run home-manager/master -- switch --flake "path:$PWD#nosuke@linux-aarch64"
```

これは Ubuntu 固有ではなく、fresh install 直後で `nix-command` / `flakes` がまだ有効になっていない環境なら macOS / Linux のどちらでも起こりえます。

この repo を 1 度 `home-manager switch` できれば、以後は `~/.config/nix/nix.conf` も Home Manager で管理されるため、通常は毎回 `NIX_CONFIG=...` を付けなくて大丈夫です。

## セットアップ

### macOS

初回適用:

```bash
git clone --recursive https://github.com/satotek/dotfiles.git ~/dotfiles
cd ~/dotfiles
sudo nix run nix-darwin/master#darwin-rebuild -- switch --flake "path:$PWD#nosuke-M5-MBP"
```

2回目以降:

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

## ローカル設定

Git の個人設定:

```bash
cp ~/dotfiles/nix/programs/git/git.local.example ~/.config/git.local
```

`~/.config/git.local` を編集:

```ini
[user]
    name = Your Name
    email = your@email.com
```

Zsh のローカル上書き設定:

```bash
cp ~/dotfiles/nix/programs/zsh/zsh.local.example ~/.config/zsh.local
```

secrets:

```bash
export AZURE_OPENAI_API_KEY='your_api_key'
export OTHER_SECRET='...'
```

必要なら `~/.config/secrets` を作って読み込ませます。

## Git 管理しないファイル

以下は repo の外に置く想定です。

- `~/.config/git.local`
- `~/.config/zsh.local`
- `~/.config/secrets`
- `$XDG_CACHE_HOME/zsh/.zcompdump`

## ディレクトリ構成

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

## 現状メモ

- macOS は `nix-darwin` ベースで運用可能です
- Linux は standalone `Home Manager` 出力を用意しています
- 共通の Home Manager 構成は `nix/home-manager/` にあります
- 汎用 package と OS 固有 package は `nix/programs/common.nix` と `nix/programs/darwin.nix` / `linux.nix` にあります
- 各アプリ設定は `nix/programs/common.nix` と OS 別の `darwin.nix` / `linux.nix` から束ねています
- tool 固有の package は対応する `nix/programs/<tool>/` で管理します
- `git`、`tmux`、`wget`、Zsh の主要部分は native option 化済みです
- Zsh plugin は `sheldon`、prompt は `starship` で管理しています
- macOS の GUI アプリは `nix-darwin` の Homebrew module 経由で管理しています
- `lazygit`、`nvim`、`wezterm`、`karabiner` などは tool ごとの `files/` を Home Manager から参照します

## 主な内容

- XDG Base Directory 対応
- Zsh
- Sheldon
- Starship
- Neovim
- tmux
- WezTerm
- Karabiner-Elements
- Git / lazygit
- ripgrep / fd / fzf / yazi / zoxide などの CLI ツール
