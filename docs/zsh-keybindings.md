# Zsh キーバインド

この dotfiles で追加・上書きしている Zsh のキーバインドをまとめる。
設定本体は `nix/home-manager/programs/zsh.nix` にある。

## よく使う操作

| キー | 用途 |
|---|---|
| `Ctrl-B` | Git ブランチを fzf で選んで `git switch` |
| `Ctrl-G` | ghq 管理下のプロジェクトを fzf で選んで移動 |
| `Ctrl-R` | コマンド履歴を atuin で検索 |
| `Ctrl-X` → `Ctrl-K` | プロセスを fzf で選んで終了 (`SIGTERM`) |
| `Tab` | fzf 補完（通常は Zsh の標準補完へフォールバック） |

`Ctrl-X` 系は同時押しではない。`Ctrl-X` を押して離してから、次のキーを押す。

## fzf 共通操作

fzf は高さ 40%、reverse、border、cycle、候補が 1 件なら自動選択で表示する。

| キー | 用途 |
|---|---|
| 文字入力 | 候補を絞り込む |
| `Up` / `Down` | 候補を移動 |
| `Enter` | 選択を確定 |
| `Esc` / `Ctrl-C` | キャンセル |

### Git ブランチ (`Ctrl-B`)

Git リポジトリ内で使う。ローカルと remote のブランチを一覧表示し、選んだブランチへ
`git switch` する。remote にしかないブランチは Git の通常動作で追跡ブランチを作る。

Git リポジトリ外では `Not in a Git repository` と表示する。

### ghq プロジェクト移動 (`Ctrl-G`)

`ghq list --full-path` の結果を `roots` に通して表示する。通常のリポジトリに加え、
モノレポ内のプロジェクトルートも候補になる。右側には `eza --tree` のプレビューを表示し、
選択するとそのディレクトリへ移動する。

### コマンド履歴 (`Ctrl-R`)

fzf ではなく atuin の検索画面を開く。`Enter` で選んだコマンドはすぐには実行されず、
プロンプトへ挿入されるので、必要に応じて編集してから実行できる。
検索中にもう一度 `Ctrl-R` を押すと、絞り込みの範囲（全体・ホスト・セッション・
ディレクトリ）が切り替わる。`Up` は atuin に渡さず、Zsh の通常の履歴をたどる。

atuin は実行したディレクトリや終了コードも記録する。導入前の履歴は
`atuin import zsh` で取り込めるが、それらにはディレクトリなどの情報がない。

### ファイル・ディレクトリ選択

| キー | 用途 |
|---|---|
| `Ctrl-T` | ファイルまたはディレクトリを fzf で選んでプロンプトへ挿入 |
| `Alt-C` | ディレクトリを fzf で選んで移動 |

ファイル・ディレクトリ・コマンドの補完を fzf で絞り込みたい場合は、`**` を入力してから `Tab` を押す。通常の `Tab` は Zsh の標準補完へフォールバックする。

### プロセス終了 (`Ctrl-X` → `Ctrl-K`)

`ps` の一覧を表示し、選択した PID へ通常の `SIGTERM` を送る。
強制終了 (`SIGKILL`) ではない。
コマンドラインに文字が入力されている場合は、それを初期クエリとして使う。

## 短縮コマンド

以下は Zsh の alias として定義される。入力した名前のまま Enter で実行される。

| alias | 実行するコマンド |
|---|---|
| `nfu` | `nix flake update --flake ~/dotfiles` |
| `nfs` | `nix flake show ~/dotfiles` |
| `ngc` | `nh clean user --keep 2 --no-gcroots`（最新2世代とdirenvなどの開発用GC rootを残して即座に整理） |

## 反映と調査

`zsh.nix` を変更した場合は Home Manager を反映し、現在のシェルを起動し直す。

```console
nix-switch
exec zsh
```

現在の割り当ては `bindkey` で確認できる。

```console
bindkey '^B'
bindkey '^G'
bindkey '^R'
bindkey '^X^K'
```

期待するウィジェット名が表示されなければ、まず `exec zsh` で設定を読み直す。
