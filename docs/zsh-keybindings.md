# Zsh キーバインド

この dotfiles で追加・上書きしている Zsh のキーバインドをまとめる。
設定本体は `nix/home-manager/programs/zsh.nix` と
`nix/home-manager/programs/zsh/` にある。

## よく使う操作

| キー | 用途 |
|---|---|
| `Ctrl-B` | Git ブランチを fzf で選んで `git switch` |
| `Ctrl-G` | ghq 管理下のプロジェクトを fzf で選んで移動 |
| `Ctrl-R` | コマンド履歴を atuin で検索 |
| `Ctrl-X` → `Ctrl-K` | プロセスを fzf で選んで終了 (`SIGTERM`) |
| `Tab` | Zsh の補完候補を fzf-tab で絞り込んで選択 |

`Ctrl-X` 系は同時押しではない。`Ctrl-X` を押して離してから、次のキーを押す。

## vi モード

行の編集は vi 方式で、起動時は入力モード（`viins`）になる。`Esc` でコマンドモード
（`vicmd`）に入り、`i` / `a` / `I` / `A` などで入力モードに戻る。
Zsh は方式の指定がないと `EDITOR` に `vi` が含まれるかで決めるため、`zsh.nix` で明示している。

| キー | 用途 |
|---|---|
| `Esc` | コマンドモードへ（待ち時間は 0.05 秒） |
| `Home` / `End` | 行頭 / 行末へ（両モード） |
| `Delete` | カーソル位置の 1 文字を削除（両モード） |
| `Backspace` | 入力モードに入る前の文字も削除できる |
| `v`（コマンドモード） | 今の行を `$EDITOR`（Neovim）で開き、保存して閉じると戻る |

カーソルは入力モードで縦線、コマンドモードでブロックになる。
割り当てのない特殊キーは先頭の `Esc` でコマンドモードに入り、残りが vi コマンドとして
実行されて行を書き換えるため、使う特殊キーは両モードに登録している。

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

### Tab 補完（fzf-tab）

`**` は不要で、`git <Tab>` や `cd <Tab>` で候補を選択できる。
説明はコマンドの補完定義が提供するものを表示する。
fzf-tab は通常の fzf 設定とは分け、高さ45%、角丸枠、青系の配色で表示する。
`<` / `>` で候補のグループを切り替える。
`cd` / `pushd` の補完では `eza` でディレクトリの中身をプレビューし、
狭い画面ではプレビューを下側に配置する。

fzf の初回遅延読み込み後も Tab の割り当ては fzf-tab のまま維持する。
Home Manager 適用時に `.zcompdump` と `.zcompdump.zwc` を削除し、
次のシェル起動で補完定義を再登録する。既存のシェルには自動反映されない。

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
