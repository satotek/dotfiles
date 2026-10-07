# Maintenance Commands

この dotfiles を更新・検証するときによく使うコマンドをまとめる。

## Nix

| コマンド | 用途 |
|---|---|
| `nix flake show` | flake outputs を確認する |
| `nix fmt` | Nix ファイルを formatter で整形する |
| `nix flake check` | 現在のsystem向けNixフォーマット・Home Manager・nix-darwinチェックを走らせる |
| `nix build --no-link '.#homeConfigurations."nosuke@linux-x86_64".activationPackage'` | Linux Home Manager 構成をビルド検証する |
| `nix build --no-link '.#homeConfigurations."azureuser@linux-x86_64".activationPackage'` | Azure user 向け Linux 構成をビルド検証する |
| `nix build --no-link '.#homeConfigurations."azureuser@gem-ai".activationPackage'` | `gem-ai` 向け Linux 構成をビルド検証する |

## Apply

| コマンド | 用途 |
|---|---|
| `nix-switch` | `nh home switch` で Home Manager layer を適用する（`--ask` で差分確認後に適用） |
| `darwin-switch` | `nh darwin switch` で macOS system layer を適用する |
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
| `dotbench` | ZshとNeovimの起動時間を10回測り、min/median/mean/maxを表示する |
| `dotbench 20` | 実行回数を指定して起動時間を測る |
| `dotbench --help` | 計測オプションを確認する |
| `dotbench --only zsh --runs 50 --output before.json` | Zshだけ計測し、新しいJSONファイルへ結果と環境情報を保存する |
| `dotbench --only zsh --compare before.json` | 保存した中央値と比較する（環境の違いは警告） |
| `dotbench interactive --runs 10` | zsh-benchでプロンプト・入力・コマンド応答を測る（Tab計測・JSON保存は未対応） |
| `nix flake update nixpkgs` | Zsh plugin を含む nixpkgs のパッケージを更新する |

Zshプラグインは `nix/home-manager/programs/zsh/plugins.nix` で管理する。
更新後はHome Managerを適用して、新しいシェルを開く。
適用時に補完キャッシュ（`.zcompdump` / `.zwc`）を無効化し、次の起動で再生成する。
Nix外で補完を手動追加した場合は、別途このキャッシュを削除してシェルを起動し直す。

dotbenchの通常計測は `zsh -i -c exit` / ヘッドレスNeovimの起動・終了時間であり、
Zshの遅延読み込み完了や操作の応答時間ではない。
対話計測の条件と制約は [README](../README.md#起動時間の計測) を参照する。
Go依存を更新する場合は `tools/dotbench/` で `go mod tidy` を実行し、
`nix/home-manager/presets/cli.nix` のdotbenchの `vendorHash` も更新する。

## Git

| コマンド | 用途 |
|---|---|
| `git status --short --branch` | branch と作業ツリーの状態を見る |
| `git log --oneline --decorate --graph --left-right main...origin/main` | local / remote の分岐を確認する |
| `git fetch origin` | remote の状態を更新する |
