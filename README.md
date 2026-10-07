# dotfiles

macOS・Linux・WSLで、いつもの開発環境を再現する。

Nix Flakes・nix-darwin・Home Managerで管理する個人用dotfilesです。
シェル、Neovim、開発ツール、AIエージェントをまとめて管理し、
macOSのシステム設定とホーム環境は独立して更新できます。

| 環境 | 管理するもの | 適用コマンド |
|---|---|---|
| macOS / Linux / WSL | シェル・エディター・CLI・AIエージェント | `nix-switch` |
| macOSのみ | Homebrewのアプリ・フォント・OS設定 | `darwin-switch` |

[セットアップ](#セットアップ) · [日常の操作](#日常の操作) ·
[設定を変更する](#設定を変更する) · [ドキュメント](#ドキュメント)

## この環境に含まれるもの

- **シェル** — Zsh、fzf-tab、Starship、atuin、fzf、zoxide、direnv
- **エディターとGit** — Neovim、Git、delta、lazygit
- **CLI** — bat、eza、fd、ripgrep、yazi、gh、xh など
- **ターミナル** — Ghostty。macOSではAeroSpace・Karabinerも設定
- **macOSのアプリ** — Homebrewのformula・caskをnix-homebrewで宣言。Xcodeはxcodesで導入
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
Homebrew本体はnix-homebrewが導入するので、事前のインストールは不要です。

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

既存の`/opt/homebrew`がある場合は、nix-homebrewが初回の適用で引き継ぎます。
tapは宣言したものだけにするため、`/opt/homebrew/Library/Taps`が残っていると
適用が止まります。中のtapは宣言から作り直されるので、退避してから再実行してください。
宣言にないformula・caskが入っている場合も適用は止まります（[Homebrew](#homebrew)）。

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
| Homebrewのformula・cask、フォント、macOS設定 | `darwin-switch`（sudoが必要） |
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
   Homebrew / フォント /            シェル / エディター / CLI /
   macOSの既定値 / sudo認証        エージェント / リポジトリ内の設定
                 │                             │
          darwin-switch                    nix-switch
             sudo必須                      sudo不要
```

Determinate NixがNixデーモンとストアのGCを担当します。nix-darwinでは
`nix.enable = false`とし、同じNix環境を二重管理しません。

## 設定を変更する

### Home Managerの標準オプション

Git、Zsh、Starship、direnv、zoxide、fzf、atuin、bat、eza、yazi、gh、
ripgrep、delta、Ghostty、Lazygitなどは、Home Managerのオプションから生成します。
変更後は`nix-switch`で適用します。ghの`config.yml`のように生成したファイルは
読み取り専用になるので、`gh config set`などアプリ側からは変更できません。

Lazygitの`config.yml`は`programs.lazygit.settings`から生成され、適用時に
公式スキーマで検証されます。ページャーとして使うdeltaは、
Nixストアの絶対パスで参照します。

### リポジトリで管理する設定

頻繁に直接編集したい設定には、Home Managerがリポジトリを参照する
シンボリックリンクを作ります。対象は`.config/nvim`、
Hunk・AeroSpace・Karabiner・OpenCode・Nix（`nix.conf`）の設定です。

これらには、編集直後にアプリケーションから読めるものと、再起動・再読み込み・
`nix-switch`が必要なものがあります。各モジュールの管理方法を確認してください。

### Homebrew

macOSのGUIアプリと一部のformulaは、`nix/nix-darwin/homebrew.nix`に用途別に宣言します。
mpv・IINA・SVPのように連携して使うものは`homebrew-video.nix`に分けています。

- **brew本体とtap** — nix-homebrewが管理します。brew本体は`flake.nix`の`brew-src`で
  リリースのタグに固定し、サードパーティのtapもflake inputで固定します。
  `brew tap`で宣言にないtapは追加できません。
- **宣言にないパッケージ** — `onActivation.cleanup = "check"`なので、`brew install`で
  入れただけのものがあると`darwin-switch`が止まります。先に宣言へ追加してください。
- **Nixとcaskの使い分け** — 版を`flake.lock`で決めたいアプリはNixで入れ、アプリ自身の
  自動更新を切ります（Ghosttyなど）。アプリが自分で更新するものはcaskにします。
- **更新** — formulaと自動更新のないcaskは`brew upgrade`で上げます。brew本体を上げるときは
  `brew-src`のタグを書き換え、`nix flake update brew-src`の後に`darwin-switch`します。
- **Xcode** — NixにもHomebrewにも載せず、`xcodes`で導入と切り替えを行います。

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

Zshプラグインはnixpkgsで取得し、`zsh-defer`でハイライトと入力候補を遅延読み込みします。
プロンプトはStarship、履歴検索はatuin、ファイル選択はfzf、Tab補完はfzf-tabが担当します。

Zshコードは`nix/home-manager/programs/zsh/`に分割し、Nix評価時に`.zshrc`へ
埋め込みます。Starship、direnv、fzf、zoxideの生成結果は`$XDG_CACHE_HOME/zsh`に
キャッシュします。出力がパッケージだけで決まるatuinとnix-your-shellの初期化は、
ビルド時に生成します。プラグインのローダーもビルド時に生成・コンパイルします。
補完は自前の`compinit`で初期化し、通常は`compinit -C`でキャッシュを利用します。
Home Manager適用時に補完キャッシュを無効化するため、新しいシェルで追加・更新に追従します。

主なキーバインド:

| キー | 動作 |
|---|---|
| `Ctrl-B` | Gitブランチをfzfで選択 |
| `Ctrl-G` | ghq / rootsのプロジェクトへ移動 |
| `Ctrl-R` | atuinで履歴を検索 |
| `Ctrl-T` / `Alt-C` | ファイルをfzfで選んで挿入 / ディレクトリへ移動 |
| `Ctrl-X` → `Ctrl-K` | プロセスをfzfで選択して終了 |
| `Tab` | fzf-tabで説明付きの補完候補を選択 |

詳細は[Zshのキーバインド](docs/zsh-keybindings.md)を参照してください。

## AIエージェントの設定

エージェントのパッケージは主に`llm-agents.nix`オーバーレイから導入します。
設定はHome Managerで生成し、共通のMCP定義は
`nix/home-manager/data/mcp-servers.nix`に置きます。

Herdr本体はNixパッケージとして管理しています。`ai`ロールのホストでは、Home Managerの適用時に
Claude Code、Codex、Grok、OpenCodeのHerdr連携を生成し、セッション復元に必要なフックを設定します。

Herdrの新規ペインとscratch terminalはHome ManagerのNix製Zshを起動します。
OS標準ZshとNix製fzf-tabのバイナリモジュール間でglibcの不一致が起きるのを避けるためです。

Herdrのリモート運用とSSHポート転送は
[VMリモート作業手順](docs/vm-remote-workflow.md)を参照してください。

## ロールとプリセット

Home Managerのパッケージは用途別のプリセットに分け、プリセットをロールに束ねています。
ホストは`nix/home-manager/roles.nix`の`select`でロールを選びます。

| プリセット | 用途 |
|---|---|
| `shell` | Zsh（nixpkgsプラグイン・fzf-tab）、Starship、direnv、zoxide、nix-index（comma） |
| `cli` | atuin、bat、eza、fd、ripgrep、yazi、btop、gh、xh、nix-your-shell、Herdr、hunk などの常用CLI |
| `git` | Git、delta、lazygit |
| `editor` | Neovim、rumdl |
| `terminal` | Ghostty。macOS だけで読む（`platforms/darwin.nix`） |
| `agents` | AIエージェント、スキル、MCP、Herdrとの連携 |
| `secrets` | SOPS と復号の activation |
| `cloud` | Azure CLI、Google Cloud SDK |
| `infra` | tenv、Terraform 言語サーバ、hadolint、lazydocker、psql |
| `go` | Go、gopls |
| `rust` | rustc、cargo、clippy、rustfmt、rust-analyzer |
| `node` | Node.js、Bun、pnpm、TypeScript、Web系の言語サーバ |
| `python` | Python、uv、ruff、basedpyright |
| `editor-lsp` | シェル、Lua、Markdown、YAML、Nix、TOML の言語サーバ |
| `media` | ffmpeg、Mermaid |

| ロール | プリセット |
|---|---|
| `base` | `shell`、`cli`、`git`、`editor` |
| `dev` | `editor-lsp`、`node`、`python`、`go`、`infra`、`cloud`、`media` |
| `rust` | `rust` |
| `ai` | `agents` |
| `secrets` | `secrets` |

| ホスト | ロール |
|---|---|
| macOS（`nosuke@nosuke-M5-MBP`） | `base`、`dev`、`rust`、`ai`、`secrets` |
| `nosuke@*`（Linux、WSL） | `base`、`dev`、`rust`、`ai`、`secrets` |
| `azureuser@*`（Azure VM） | `base`、`dev`、`ai`、`secrets` |
| `stko23@stko23-windows`（業務用WSL） | `base`、`dev`、`rust` |

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
dotbench --only zsh --runs 50 --warmup 2 --output before.json
dotbench --only zsh --warmup 2 --compare before.json
dotbench --only zsh --zsh "$HOME/.nix-profile/bin/zsh"
dotbench interactive --runs 10
```

環境間または変更前後の比較には、バックグラウンド処理の影響を受けにくい
中央値を使います。通常のZsh計測は`zsh -i -c exit`の起動・終了時間であり、
プロンプト表示や遅延プラグインの読み込み完了、入力応答を直接測るものではありません。

`--only`で対象、`--runs`と`--warmup`で回数、`--zsh`と`--nvim`で実行ファイルを指定できます。
JSONには生の時間（ナノ秒）とOS・CPU・ホスト・実行パス・バージョンを保存します。
`--output`は既存ファイルを上書きしません。比較は中央値の増減率を表示し、環境の違いは警告します。
設定内容やシステム負荷の同一性までは確認しないため、条件を揃えて比較してください。

`interactive`は同梱の`zsh-bench`を使い、非ログイン・Gitなしの環境でプロンプト・入力・
コマンド応答を測ります。出力は既定で10回分の生データ（時間はミリ秒）で、
プロンプトにホスト名か現在のディレクトリ名が必要です。遅延ロードのプラグインは
検出前に読み込まれない場合があります。Tabの待ち時間や対話結果のJSON保存・比較は未対応です。
Nixなしで実行する場合、対話計測には別途`zsh-bench`が必要です。

ヘルプは`dotbench --help`を参照してください。Bash・Zsh・fishの補完はNixパッケージに同梱します。

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
必要な切り替えを実行します。Homebrewの`brew-src`、`nix-homebrew`、tapは対象外で、
必要なときに手動で更新します。

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
│   │   ├── homebrew-video.nix
│   │   ├── fonts.nix
│   │   ├── macos-defaults.nix
│   │   └── nix-cleanup.nix
│   └── home-manager/
│       ├── home/
│       ├── platforms/
│       ├── roles.nix
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
