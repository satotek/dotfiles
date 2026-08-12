# dotfiles

macOSとLinuxの開発環境を、Nix Flakes・nix-darwin・Home Managerで管理する個人用dotfilesです。

- macOSはnix-darwinのシステム層と、単独のHome Managerによるホーム環境を分離
- LinuxとWSLは単独のHome Managerで管理
- CLI、シェル、エディター、AIエージェント環境をNixで再現
- 頻繁に編集する設定は、リポジトリを参照するシンボリックリンクで管理
- マシン固有の設定と平文の機密情報はリポジトリ外に保持

## 構成

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

### macOSのシステム層

nix-darwinが次を管理します。

- Homebrew cask: 1Password、1Password CLI、Karabiner-Elements、WezTerm Nightly
- フォント: HackGen NF、Moralerspace
- Dock、Finder、キーボード、トラックパッド、スクリーンショットなどの設定
- sudoのTouch ID認証
- ログインシェルとしてのZsh
- 古いnix-darwinシステム世代の定期整理

### Home Managerによるホーム環境

macOSとLinuxで共有するホーム環境です。

- XDG Base Directory
- Zsh、Sheldon、Starship、Zeno、zoxide、direnv
- Git、delta、lazygit、tmux
- Neovim、Ghostty、WezTerm、Karabiner設定
- 開発ツールチェーンと言語サーバー
- Claude Code、Codex、Antigravity CLI、Grok、Herdr、Hunk
- エージェントスキル、MCPサーバー設定、Herdr連携
- sopsとGCP Cloud KMSによる機密情報の復号

## 対応する構成

| Flake出力 | プラットフォーム | ユーザー / ホスト |
|---|---|---|
| `darwinConfigurations.nosuke-M5-MBP` | `aarch64-darwin` | macOSのシステム層 |
| `homeConfigurations."nosuke@nosuke-M5-MBP"` | `aarch64-darwin` | macOSのホーム環境 |
| `homeConfigurations."nosuke@linux-x86_64"` | `x86_64-linux` | 汎用Linux |
| `homeConfigurations."nosuke@linux-aarch64"` | `aarch64-linux` | 汎用Linux |
| `homeConfigurations."nosuke@nosuke-windows"` | `x86_64-linux` | WSL |
| `homeConfigurations."stko23@stko23-windows"` | `x86_64-linux` | WSL |
| `homeConfigurations."azureuser@linux-x86_64"` | `x86_64-linux` | Azure / 汎用Linux |
| `homeConfigurations."azureuser@linux-aarch64"` | `aarch64-linux` | Azure / 汎用Linux |
| `homeConfigurations."azureuser@gem-ai"` | `x86_64-linux` | `gem-ai` |

すべての出力は次で確認できます。

```bash
nix flake show
```

この構成はリポジトリを`~/dotfiles`へクローンする前提です。別のユーザー、
ホスト、クローン先を使う場合は、`flake.nix`、ホスト定義、またはHome Manager
モジュール内の`dotfilesDir`を調整してください。

## Nixのインストール

[Determinate Nix](https://docs.determinate.systems/)を使用します。
`llm-agents.nix`のバイナリキャッシュを信頼済みの配布元として登録し、
Codexなどの大きなRustパッケージを毎回ソースからビルドしないようにします。

```bash
curl -fsSL https://install.determinate.systems/nix | sh -s -- install \
  --extra-conf "trusted-users = root $(id -un)" \
  --extra-conf "extra-substituters = https://cache.numtide.com" \
  --extra-conf "extra-trusted-substituters = https://cache.numtide.com" \
  --extra-conf "extra-trusted-public-keys = niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
```

インストール後にシェルを開き直し、確認します。

```bash
nix --version
nix config show | grep experimental-features
nix config show | grep cache.numtide.com
```

Determinate Nixは通常`nix-command`と`flakes`を有効化します。新規インストール
直後に無効と表示される場合だけ、代替手段として次を設定します。

```bash
mkdir -p ~/.config/nix
grep -qxF 'experimental-features = nix-command flakes' \
  ~/.config/nix/nix.conf 2>/dev/null \
  || printf '%s\n' 'experimental-features = nix-command flakes' >> ~/.config/nix/nix.conf
```

初回のHome Manager適用後は、リポジトリ内の`.config/nix/nix.conf`が管理対象になります。

## 初回セットアップ

### macOS

```bash
git clone https://github.com/satotek/dotfiles.git ~/dotfiles
cd ~/dotfiles

# システム層
sudo nix run nix-darwin/master#darwin-rebuild -- \
  switch --flake "path:$PWD#nosuke-M5-MBP"

# ホーム環境
nix run home-manager/master -- \
  switch --flake "path:$PWD#nosuke@nosuke-M5-MBP"
```

システム層にはsudoが必要ですが、ホーム環境には不要です。

### Linux / WSL

```bash
git clone https://github.com/satotek/dotfiles.git ~/dotfiles
cd ~/dotfiles

nix run home-manager/master -- \
  switch -b backup --flake "path:$PWD#<home-configuration>"
```

例:

```bash
nix run home-manager/master -- \
  switch -b backup --flake "path:$PWD#azureuser@gem-ai"
```

`-b backup`は、初回適用時に既存ファイルとHome Managerのリンクが
衝突した場合の退避用です。

## 日常的な更新

初回適用後は次のラッパーコマンドがインストールされます。

```bash
nix-switch
```

現在のユーザーとホストに対応するHome Manager構成を適用します。
macOSでもLinuxでもsudoは不要です。

macOSのシステム層を変更した場合だけ次を実行します。

```bash
darwin-switch
```

使い分け:

| 変更 | コマンド |
|---|---|
| シェル、CLI、Neovim、Ghostty、エージェント、Lazygit | `nix-switch` |
| Homebrew cask、フォント、macOS設定、システムのZsh | `darwin-switch` |
| 両方 | `darwin-switch`の後に`nix-switch` |

flakeはGit管理対象だけを入力として扱います。新しいNixモジュールや`.zsh`
スニペットを追加した場合は、切り替えまたは通常のflake評価より先に`git add`
してください。未追跡ファイルを含めて一時的に評価するときは
`path:$PWD#...`を使用できます。

## 設定の管理方法

### Home Managerの標準オプション

可能なものはHome Managerのオプションから生成します。

- Git
- Zshの履歴とエイリアス
- Sheldonプラグイン
- Starship
- direnv / nix-direnv
- zoxide
- tmux
- Ghostty
- Lazygit

Lazygitの`config.yml`は`programs.lazygit.settings`から生成され、適用時に
公式スキーマで検証されます。ページャーとして使うdeltaは、
Nixストアの絶対パスで参照します。

### リポジトリで管理する設定

頻繁に直接編集したい設定には、Home Managerがリポジトリを参照する
シンボリックリンクを作ります。

- `.config/nvim`
- `.config/nvchad`
- `.config/wezterm`
- `.config/hunk/config.toml`
- `.config/karabiner/karabiner.json`
- `.config/nix/nix.conf`
- `nix/home-manager/home/profile.sh`

これらには、編集直後にアプリケーションから読めるものと、再起動・再読み込み・
`nix-switch`が必要なものがあります。各モジュールの管理方法を確認してください。

### ローカルだけで管理するファイル

次はGit管理しません。

- `~/.config/git.local`
- `~/.config/zsh.local`
- `~/.config/secrets`
- `~/.ssh/azure-devops`
- `~/.ssh/azure-devops.pub`
- `$XDG_CACHE_HOME/zsh/`

Gitのユーザー情報:

```bash
cp ~/dotfiles/.config/git.local.example ~/.config/git.local
```

任意のZsh上書き設定:

```bash
cp ~/dotfiles/.config/zsh.local.example ~/.config/zsh.local
```

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
| `secrets/context7.yaml` | `~/.config/context7/api-key` | `agents`プリセットを使うホスト |

既存ファイルの暗号化先にKMSキーを追加した場合は、復号可能なマシンで
暗号化し直します。

```bash
sops updatekeys secrets/*.yaml
```

リポジトリ管理外のシェル用機密情報は`~/.config/secrets`へ置けます。

## シェル

ZshプラグインはSheldon、プロンプトはStarship、スニペットと履歴UIはZenoが担当します。

Zshコードは役割ごとに分割し、Nix評価時に最終`.zshrc`へ埋め込みます。
実行時に分割ファイルを追加で読み込まないため、ファイル分割による
起動時I/Oは増えません。

```text
nix/home-manager/programs/
├── zsh.nix
└── zsh/
    ├── early.zsh
    ├── widgets.zsh
    ├── vm.zsh
    └── init.zsh
```

Sheldon、Starship、zoxideの生成結果は`$XDG_CACHE_HOME/zsh`へ
アトミックに保存し、Zshバイトコードへコンパイルします。Nixストアの
更新時刻に依存せず、パッケージ本体や設定の変更に応じてキャッシュを更新します。

主なキーバインド:

| キー | 動作 |
|---|---|
| `Ctrl-B` | Gitブランチをfzfで選択 |
| `Ctrl-G` | ghq / rootsのプロジェクトへ移動 |
| `Ctrl-R` | Zenoで履歴を検索 |
| `Ctrl-X` → `Ctrl-K` | プロセスをfzfで選択して終了 |
| `Tab` | Zenoによる補完 |

詳細は[Zshのキーバインド](docs/zsh-keybindings.md)を参照してください。

## AIエージェントとHerdr

エージェントのパッケージは主に`llm-agents.nix`オーバーレイから導入します。
設定はHome Managerで生成し、共通のMCP定義は
`nix/home-manager/data/mcp-servers.nix`に置きます。

- Claude Code
- Codex
- Antigravity CLI
- Grok
- Herdr
- Hunk
- agent-browser
- 選定したエージェントスキル

Herdr本体はNixパッケージとして管理しています。Home Managerの適用時に
Claude CodeとCodexのHerdr連携を生成し、セッション復元に必要なフックを設定します。

Herdrのリモート運用とSSHポート転送は
[VMリモート作業手順](docs/vm-remote-workflow.md)を参照してください。

## ツールのプリセット

Home Managerのパッケージは用途別のプリセットに分けています。

| プリセット | 用途 |
|---|---|
| `base` | シェル、エディター、Git、常用CLI |
| `agents` | AIエージェント、スキル、MCP、Herdr、sops |
| `cloud` | Azure CLI、Google Cloud SDK、SOPS、Terraform/OpenTofu関連ツール |
| `devtools` | Go、シェル/Lua/Markdown関連ツール、Mermaid、ffmpeg |
| `rust` | rustc、cargo、clippy、rustfmt、rust-analyzer |
| `webdevtools` | Node.js、Bun、pnpm、Python、NixとWeb系の言語サーバー |

ホストごとのプリセットの組み合わせは`flake.nix`と`nix/hosts/`で定義します。

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

macOSでは毎週日曜に次を整理します。

- 12:00: Home Managerの世代を最低5世代、直近7日分残して整理
- 12:15: nix-darwinのシステム世代を最低5世代、直近7日分残して整理

ストアのGCはDeterminate Nixdへ任せ、`nh clean profile`には
`--no-gc --no-gcroots`を指定しています。

## 自動更新

GitHub Actionsがflakeの入力を更新し、Linux用Home Manager構成のビルドに
成功した場合だけPRを作成して自動マージします。

| ワークフロー | 実行間隔 | 更新対象 |
|---|---|---|
| `update-flake-ai.yml` | 毎日 | `llm-agents`、エージェントブラウザー、エージェントスキル |
| `update-flake-stable.yml` | 3日ごと | `nixpkgs`、`nix-darwin`、`home-manager` |

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
│   ├── nvim/
│   ├── nvchad/
│   └── wezterm/
├── docs/
├── secrets/
├── tools/
│   └── dotbench/
└── .github/
    └── workflows/
```

## 関連ドキュメント

- [メンテナンス用コマンド](docs/maintenance.md)
- [Zshのキーバインド](docs/zsh-keybindings.md)
- [Neovimチートシート](docs/nvim-cheatsheet.md)
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
