# dotfiles

macOS・Linux・WSLで、いつもの開発環境を再現する。

Nix Flakes・nix-darwin・Home Managerで管理する個人用dotfilesです。
シェル、Neovim、開発ツール、AIエージェントをまとめて管理し、
macOSのシステム設定とホーム環境は独立して更新できます。

| 環境 | 管理するもの | 適用コマンド |
|---|---|---|
| macOS / Linux / WSL | シェル・エディター・CLI・AIエージェント | `nix-switch` |
| macOSのみ | GUIアプリ・フォント・OS設定 | `darwin-switch` |

[セットアップ](#セットアップ) · [日常の操作](#日常の操作) ·
[設定を変更する](#設定を変更する) · [ドキュメント](#ドキュメント)

## この環境に含まれるもの

- **シェル** — Zsh、Sheldon、Starship、Zeno、zoxide、direnv
- **エディターとGit** — Neovim、tmux、Git、delta、lazygit
- **ターミナル** — Ghostty。macOSではAeroSpace・Karabinerも設定
- **開発ツール** — Go、Rust、Node.js、Bun、pnpm、Python、uv、各種言語サーバー
- **AIエージェント** — Claude Code、Codex、OpenCode、Antigravity CLI、Grok、Herdr、Hunk
- **共通基盤** — エージェント向けルール・スキル・MCP設定、sopsによる機密情報の管理

導入するツールはホストごとのプリセットで選択します。
たとえば`azureuser`のLinux構成はRustを除外し、OrcaのSSHトンネル待受は`gem-ai`だけに追加します。

## セットアップ

このリポジトリは個人のユーザー名・ホスト名に合わせた構成です。
そのまま汎用インストーラーとして使うものではありません。
クローン先は`~/dotfiles`を前提とし、別の環境では
`flake.nix`と`nix/hosts/`のユーザー名・ホームディレクトリ・ホスト名を調整してください。

### 1. Nixをインストール

[Determinate Nix](https://docs.determinate.systems/)を使用します。
`llm-agents.nix`のバイナリキャッシュも登録し、大きなパッケージのソースビルドを避けます。
このコマンドはNixをインストールし、現在のユーザーと指定のキャッシュを信頼対象に追加します。

```bash
curl -fsSL https://install.determinate.systems/nix | sh -s -- install \
  --extra-conf "trusted-users = root $(id -un)" \
  --extra-conf "extra-substituters = https://cache.numtide.com" \
  --extra-conf "extra-trusted-substituters = https://cache.numtide.com" \
  --extra-conf "extra-trusted-public-keys = niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
```

シェルを開き直し、`nix --version`でインストールを確認します。

### 2. クローンして構成を選ぶ

```bash
git clone https://github.com/satotek/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

Home Managerの構成名は次から選びます。

| 構成名 | プラットフォーム | 用途 |
|---|---|---|
| `nosuke@nosuke-M5-MBP` | `aarch64-darwin` | macOS |
| `nosuke@linux-x86_64` | `x86_64-linux` | 汎用Linux |
| `nosuke@linux-aarch64` | `aarch64-linux` | 汎用Linux |
| `nosuke@nosuke-windows` | `x86_64-linux` | WSL |
| `stko23@stko23-windows` | `x86_64-linux` | WSL |
| `azureuser@linux-x86_64` | `x86_64-linux` | Azure / 汎用Linux |
| `azureuser@linux-aarch64` | `aarch64-linux` | Azure / 汎用Linux |
| `azureuser@gem-ai` | `x86_64-linux` | `gem-ai` |

macOSのシステム構成は`darwinConfigurations.nosuke-M5-MBP`です。
すべての出力は`nix flake show`で確認できます。

### 3. 初回適用

**macOS** — システム層を適用してからホーム環境を適用します。
HomebrewアプリやmacOSの既定値も変更されるため、先に`nix/nix-darwin/`を確認してください。

```bash
sudo nix run nix-darwin/master#darwin-rebuild -- \
  switch --flake "path:$PWD#nosuke-M5-MBP"

nix run home-manager/master -- \
  switch -b backup --flake "path:$PWD#nosuke@nosuke-M5-MBP"
```

**Linux / WSL** — `<home-configuration>`を上の構成名に置き換えます。

```bash
nix run home-manager/master -- \
  switch -b backup --flake "path:$PWD#<home-configuration>"
```

ホーム環境の適用にsudoは不要です。`-b backup`は既存ファイルとリンクが
衝突した場合の退避用です。同名のバックアップがある場合は確認してから整理してください。
機密情報の復号を使うホストでは、[機密情報](#機密情報)の認証設定も必要です。

### 4. ローカル設定を用意

Gitのユーザー情報と任意のZsh上書き設定は、リポジトリ外で管理します。
既存ファイルがない場合にテンプレートをコピーし、自分の環境に合わせて編集してください。

```bash
cp -n ~/dotfiles/.config/git.local.example ~/.config/git.local
cp -n ~/dotfiles/.config/zsh.local.example ~/.config/zsh.local
```

## 日常の操作

初回適用後はラッパーコマンドを利用できます。

```bash
cd ~/dotfiles
git pull
nix-switch
```

| 変更したもの | 実行するコマンド |
|---|---|
| シェル、CLI、Neovim、エージェントなど | `nix-switch` |
| Homebrew cask、フォント、macOS設定 | `darwin-switch`（sudoが必要） |
| 両方 | `darwin-switch`の後に`nix-switch` |

`nix-switch`は現在のユーザー名とホスト名から構成を選びます。
ホスト名が構成名と一致しない環境では、対象を明示して適用してください。

```bash
home-manager switch --flake 'path:/home/azureuser/dotfiles#azureuser@linux-x86_64'
```

新規ファイルは通常のGit flake入力に含まれません。
追加したパスだけを`git add -N <path>`で認識させるか、
初回セットアップと同様に`path:$PWD#...`を指定して検証します。

## 管理の仕組み

```text
                            flake.nix
                                │
                 ┌──────────────┴──────────────┐
                 │                             │
        darwinConfigurations             homeConfigurations
           (macOSのみ)                    (macOS / Linux)
                 │                             │
        nix/nix-darwin/                 nix/home-manager/
                 │                             │
   Homebrew cask / フォント /       シェル / エディター / CLI /
   macOSの既定値 / Touch ID        エージェント / リポジトリ内の設定
                 │                             │
          darwin-switch                    nix-switch
             sudo必須                      sudo不要
```

Determinate NixがNixデーモンとストアのGCを担当します。nix-darwinでは
`nix.enable = false`とし、同じNix環境を二重管理しません。

## 設定を変更する

### Home Managerの標準オプション

Git、Zsh、Sheldon、Starship、direnv、zoxide、tmux、Ghostty、Lazygitなどは
Home Managerのオプションから生成します。変更後は`nix-switch`で適用します。

Lazygitの`config.yml`は`programs.lazygit.settings`から生成され、適用時に
公式スキーマで検証されます。ページャーとして使うdeltaは、
Nixストアの絶対パスで参照します。

### リポジトリで管理する設定

頻繁に直接編集したい設定には、Home Managerがリポジトリを参照する
シンボリックリンクを作ります。対象は`.config/nvim`、
Hunk・AeroSpace・Karabiner・Nixの設定です。

これらには、編集直後にアプリケーションから読めるものと、再起動・再読み込み・
`nix-switch`が必要なものがあります。各モジュールの管理方法を確認してください。

### ローカルだけで管理するファイル

次はGit管理しません。

- `~/.config/git.local`
- `~/.config/zsh.local`
- `~/.config/secrets`
- `~/.ssh/id_rsa`（Azure DevOps用。ed25519非対応のためRSA）
- `~/.ssh/id_rsa.pub`
- `$XDG_CACHE_HOME/zsh/`

## 機密情報

リポジトリで管理する機密情報は`secrets/*.yaml`をsopsで暗号化し、
GCP Cloud KMSで復号します。

```text
projects/nosuke-net/locations/global/keyRings/sops/cryptoKeys/dotfiles
```

各ホストで一度、Application Default Credentialsを設定します。

```bash
gcloud config set project nosuke-net
gcloud auth application-default login
gcloud auth application-default set-quota-project nosuke-net
```

現在の出力先:

| 暗号化ファイル | 復号先 | 対象 |
|---|---|---|
| `secrets/cloudflare.yaml` | `~/.config/cloudflare/cloudflare-infra.env` | macOSのみ |
| `secrets/context7.yaml` | `~/.config/context7/api-key` | `secrets`プリセットを使うホスト |

既存ファイルの暗号化先にKMSキーを追加した場合は、復号可能なマシンで
暗号化し直します。

```bash
sops updatekeys secrets/*.yaml
```

リポジトリ管理外のシェル用機密情報は`~/.config/secrets`へ置けます。

## シェルの操作

ZshプラグインはSheldon、プロンプトはStarship、スニペットと履歴UIはZenoが担当します。

Zshコードは`nix/home-manager/programs/zsh/`に分割し、Nix評価時に`.zshrc`へ
埋め込みます。Sheldon、Starship、zoxideの生成結果は`$XDG_CACHE_HOME/zsh`にキャッシュします。

主なキーバインド:

| キー | 動作 |
|---|---|
| `Ctrl-B` | Gitブランチをfzfで選択 |
| `Ctrl-G` | ghq / rootsのプロジェクトへ移動 |
| `Ctrl-R` | Zenoで履歴を検索 |
| `Ctrl-X` → `Ctrl-K` | プロセスをfzfで選択して終了 |
| `Tab` | Zenoによる補完 |

詳細は[Zshのキーバインド](docs/zsh-keybindings.md)を参照してください。

## AIエージェントの設定

エージェントのパッケージは主に`llm-agents.nix`オーバーレイから導入します。
設定はHome Managerで生成し、共通のMCP定義は
`nix/home-manager/data/mcp-servers.nix`に置きます。

Herdr本体はNixパッケージとして管理しています。Home Managerの適用時に
Claude Code、Codex、Grok、OpenCodeのHerdr連携を生成し、セッション復元に必要なフックを設定します。

Herdrのリモート運用とSSHポート転送は
[VMリモート作業手順](docs/vm-remote-workflow.md)を参照してください。

## ツールのプリセット

Home Managerのパッケージは用途別のプリセットに分けています。

| プリセット | 用途 |
|---|---|
| `shell` | Zsh、Starship、Sheldon、direnv、zoxide |
| `cli` | bat、eza、fd、ripgrep、yazi、btop、gh などの常用CLI |
| `git` | Git、delta、lazygit |
| `editor` | Neovim |
| `terminal` | Ghostty。macOS だけで読む（`platforms/darwin.nix`） |
| `agents` | AIエージェント、スキル、MCP、Herdr |
| `secrets` | SOPS と復号の activation |
| `cloud` | Azure CLI、Google Cloud SDK |
| `infra` | tenv、Terraform 言語サーバ、hadolint、lazydocker |
| `go` | Go、gopls |
| `rust` | rustc、cargo、clippy、rustfmt、rust-analyzer |
| `node` | Node.js、Bun、pnpm、TypeScript、Web系の言語サーバ |
| `python` | Python、uv、ruff、basedpyright |
| `editor-lsp` | シェル、Lua、Markdown、YAML、Nix、TOML の言語サーバ |
| `media` | ffmpeg、Mermaid |

ホストは`nix/home-manager/presets/select.nix`を読みます。引数を省くと上の一式です。
`withRust`、`withSecrets`でそれぞれのプリセットを除外できます。

## 検証とメンテナンス

よく使う検証:

```bash
# Nixの整形
nix fmt

# 現在のプラットフォームを検証
nix flake check

# 特定のHome Manager出力をビルド
nix build --no-link \
  '.#homeConfigurations."nosuke@linux-x86_64".activationPackage'

# Zshスニペットの構文
for file in nix/home-manager/programs/zsh/*.zsh; do
  zsh -n "$file"
done
```

詳細なコマンドは[メンテナンス用コマンド](docs/maintenance.md)を参照してください。

### 起動時間の計測

`dotbench`は対話型ZshとヘッドレスNeovimを1回ウォームアップした後、
既定で10回測定し、最小値・中央値・平均値・最大値を表示します。

```bash
dotbench
dotbench 30
```

環境間または変更前後の比較には、バックグラウンド処理の影響を受けにくい
中央値を使います。macOSでは一部のZsh初期化を`zsh-defer`へ渡しているため、
`dotbench`のZsh値はプロンプト表示までの同期処理を中心に測ります。

### 世代の整理

Home Managerの`programs.nh.clean`で、ユーザーのプロファイル（`home-manager`と
`home-manager-path`を入れる`profile`）を毎週`nh clean user`で整理します。
最低2世代と直近7日分を残し、`--no-gcroots`でdirenvなどの開発用GC rootは保持します。

| OS | 実行タイミング | 内容 |
|---|---|---|
| Linux | 毎週月曜0:00（systemd timer、停止中に過ぎた分は起動時に実行） | 世代整理、NixストアのGCと最適化 |
| macOS | 毎週日曜12:00 | 世代整理のみ（`--no-gc`） |
| macOS | 毎週日曜12:15 | nix-darwinのシステム世代を同じ条件で整理し、NixストアのGCと最適化 |

macOSのストアGCはroot権限で動くsystem側の`nh clean profile`に集約しています。
最適化（`--optimise`）は同じ内容のファイルをハードリンクでまとめ、ストアを15%ほど縮めます。

### 自動更新

GitHub Actionsがflakeの入力を更新し、Linux用Home Manager構成のビルドに
成功した場合だけPRを作成して自動マージします。

| ワークフロー | 実行間隔 | 更新対象 |
|---|---|---|
| `update-flake-ai.yml` | 毎日 | `llm-agents`、エージェントブラウザー、エージェントスキル |
| `update-flake-stable.yml` | 3日ごと | `nixpkgs`、`nix-darwin`、`home-manager`、`nix-index-database` |

両ワークフローとも`cache.numtide.com`を利用し、
`homeConfigurations."nosuke@linux-x86_64".activationPackage`を検証します。
更新はリポジトリへマージされるだけなので、各マシンでは`git pull`後に
必要な切り替えを実行します。

## リポジトリ構成

```text
dotfiles/
├── flake.nix
├── flake.lock
├── nix/
│   ├── hosts/
│   │   ├── darwin/
│   │   └── linux/
│   ├── nix-darwin/
│   │   ├── system.nix
│   │   ├── homebrew.nix
│   │   ├── macos-defaults.nix
│   │   └── nix-cleanup.nix
│   └── home-manager/
│       ├── home/
│       ├── platforms/
│       ├── presets/
│       ├── programs/
│       └── data/
├── .config/
│   └── nvim/
├── docs/
├── secrets/
├── tools/
│   └── dotbench/
└── .github/
    └── workflows/
```

## ドキュメント

- [メンテナンス用コマンド](docs/maintenance.md)
- [Zshのキーバインド](docs/zsh-keybindings.md)
- [Neovimチートシート](docs/nvim-cheatsheet.md)
- [AeroSpace](docs/aerospace.md)
- [VMリモート作業手順](docs/vm-remote-workflow.md)

## 統計

<!-- rumdl-disable MD013 MD033 -->

### アクティビティ

<a href="https://next.ossinsight.io/widgets/official/compose-last-28-days-stats?repo_id=1105658656" target="_blank" align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://next.ossinsight.io/widgets/official/compose-last-28-days-stats/thumbnail.png?repo_id=1105658656&image_size=auto&color_scheme=dark" width="655" height="auto">
    <img alt="Performance Stats of satotek/dotfiles - Last 28 days" src="https://next.ossinsight.io/widgets/official/compose-last-28-days-stats/thumbnail.png?repo_id=1105658656&image_size=auto&color_scheme=light" width="655" height="auto">
  </picture>
</a>

### 変更量

<a href="https://next.ossinsight.io/widgets/official/analyze-repo-loc-per-month?repo_id=1105658656" target="_blank" align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://next.ossinsight.io/widgets/official/analyze-repo-loc-per-month/thumbnail.png?repo_id=1105658656&image_size=auto&color_scheme=dark" width="721" height="auto">
    <img alt="Lines of Code Changes of satotek/dotfiles" src="https://next.ossinsight.io/widgets/official/analyze-repo-loc-per-month/thumbnail.png?repo_id=1105658656&image_size=auto&color_scheme=light" width="721" height="auto">
  </picture>
</a>

<!-- Made with [OSS Insight](https://ossinsight.io/) -->

<!-- rumdl-enable MD013 MD033 -->
