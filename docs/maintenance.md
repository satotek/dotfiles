# メンテナンス用コマンド

この dotfiles を更新・検証するときによく使うコマンドをまとめる。

## Nix

| コマンド | 用途 |
|---|---|
| `nix flake show` | flake outputs を確認する |
| `nix fmt` | Nix ファイルを formatter で整形する |
| `nix flake check` | 現在のシステム向け Nix フォーマット・Home Manager・nix-darwin チェックを走らせる |
| `nix build --no-link '.#homeConfigurations."nosuke@linux-x86_64".activationPackage'` | 汎用 Linux 向け Home Manager 構成をビルド検証する |
| `nix build --no-link '.#homeConfigurations."azureuser@linux-x86_64".activationPackage'` | Azure user 向け Linux 構成をビルド検証する |
| `nix build --no-link '.#homeConfigurations."azureuser@gem-ai".activationPackage'` | `gem-ai` 向け Linux 構成をビルド検証する |
| `nix flake update nixpkgs` | nixpkgs のパッケージを更新する |
| `nfu` | `nix flake update --flake ~/dotfiles`（エイリアス） |
| `nfs` | `nix flake show ~/dotfiles`（エイリアス） |

## 構成の適用

| コマンド | 用途 |
|---|---|
| `nix-switch` | `nh home switch` で Home Manager レイヤーを適用する（`--ask` を渡すと差分確認後に適用） |
| `darwin-switch` | `nh darwin switch` で macOS システムレイヤーを適用する（sudo は nh が内部で要求） |
| `home-manager switch --flake "path:$PWD#azureuser@linux-x86_64"` | 構成名を明示して直接 Home Manager を適用する |

新規追加したファイルは Git が未追跡だと Flake ビルドに含まれない。`git add -N <path>` で認識させるか、`path:$PWD#...` を指定して適用する。

## Neovim

本体は Nix パッケージ（`pkgs.neovim`）、設定は `.config/nvim` の out-of-store symlink、プラグインは lazy.nvim で管理する。

| コマンド | 用途 |
|---|---|
| `nvim --headless '+Lazy! sync' +qa` | プラグインの同期をヘッドレスで実行する |
| `nvim --headless '+checkhealth' +qa` | ヘルスチェックをヘッドレスで実行する |
| `nvim --startuptime /tmp/nvim.log +q` | 起動時間ログを取得する |
| `nvim --headless --cmd 'set shadafile=NONE' '+lua print(vim.inspect(require("lazy.core.config").plugins["snacks.nvim"]))' +qa` | lazy.nvim 上のプラグイン定義を確認する |

## シェルとベンチマーク

| コマンド | 用途 |
|---|---|
| `zsh -i -c exit` | 対話型 Zsh の起動確認 |
| `time zsh -i -c exit` | Zsh の起動時間を計測する |
| `for f in nix/home-manager/programs/zsh/*.zsh; do zsh -n "$f"; done` | Zsh 設定スニペットの構文チェック |
| `dotbench` | Zsh と Neovim の起動時間を10回測定し、min/median/mean/max を表示する |
| `dotbench 20` | 指定回数（20回）で測定する |
| `dotbench --help` | 計測オプションを確認する |
| `dotbench --only zsh --runs 50 --output before.json` | Zsh だけ計測し、結果と環境情報を JSON へ保存する |
| `dotbench --only zsh --compare before.json` | 保存した中央値と比較する（環境の違いは警告） |
| `dotbench interactive --runs 10` | 擬似端末でプロンプト表示・最初のコマンド・Enter 応答・終了の待ち時間を測定する |

Zsh プラグインは `nix/home-manager/programs/zsh/plugins.nix` で管理する。
更新後は Home Manager を適用（`nix-switch`）して、新しいシェルを開く。
適用時に補完キャッシュ（`.zcompdump` / `.zwc`）を無効化し、次回起動時に再生成する。
Nix 外で補完を手動追加した場合は、別途キャッシュを削除してシェルを起動し直す。

`dotbench` の通常計測は `zsh -i -c exit` およびヘッドレス Neovim の起動・終了時間であり、遅延読み込み完了や操作応答時間ではない。
対話計測の条件と制約は [README](../README.md#起動時間の計測) を参照。
Go 依存を更新する場合は `tools/dotbench/` で `go mod tidy` を実行し、`nix/home-manager/presets/cli.nix` 内の dotbench の `vendorHash` を更新する。

## 機密情報 (SOPS)

機密情報は `secrets/*.yaml` を SOPS で暗号化し、GCP Cloud KMS で復号する。復号結果は stamp ファイルでキャッシュされ、変更がなければ KMS を叩かずに前回の出力を再利用する。

| コマンド | 用途 |
|---|---|
| `sops secrets/agents.yaml` | 機密情報ファイルを復号・編集する |
| `sops updatekeys secrets/*.yaml` | `.sops.yaml` の鍵定義変更時に暗号化鍵を更新する |
| `gcloud auth application-default login` | KMS 復号用の Google Cloud ADC 認証を通す |

## サービスと AI エージェント

| コマンド | 用途 |
|---|---|
| `systemctl --user status t3code` | T3 Code サーバー（gem-ai）の稼働状態を確認する |
| `systemctl --user restart t3code` | T3 Code サーバーを再起動する |
| `journalctl --user -u t3code -f` | T3 Code サーバーのログをストリーミング表示する |
| `aerospace reload-config` | AeroSpace の設定を再読み込みする（`nix-switch` 時にも自動実行） |
| `aerospace run-callback --for-every-window on-window-detected` | AeroSpace のウィンドウ配置ルールを既存ウィンドウへ再適用する |

> [!NOTE]
> T3 Code サーバーのサービス停止中にクライアント側が自前の managed runtime を起動すると、ポート競合により `ServerAlreadyRunningError` で systemd 側が起動できなくなる。クライアント側のランタイムを停止するか再起動で解消する。

## 世代整理 (GC)

Home Manager の `programs.nh.clean` により、不要な世代の削除と Nix ストアの最適化が定期実行される。手動での実行も可能。

| コマンド | 用途 |
|---|---|
| `ngc` | `nh clean user --keep 2 --no-gcroots`（最新2世代と開発用 GC root を残して即時整理） |
| `nh clean user --keep 2` | ユーザー世代を整理する |
| `nh clean profile --keep 2` | macOS システム世代を整理する（要管理者権限） |

## Git

| コマンド | 用途 |
|---|---|
| `git status --short --branch` | ブランチと作業ツリーの状態を確認する |
| `git log --oneline --decorate --graph --left-right main...origin/main` | ローカルとリモートの分岐差分を確認する |
| `git fetch origin` | リモートの状態を更新する |
