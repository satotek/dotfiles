# Zsh キーバインド

この dotfiles で追加・上書きしている Zsh のキーバインドをまとめる。
設定本体は `nix/home-manager/programs/zsh.nix` にある。

## よく使う操作

| キー | 用途 |
|---|---|
| `Ctrl-B` | Git ブランチを fzf で選んで `git switch` |
| `Ctrl-G` | ghq 管理下のプロジェクトを fzf で選んで移動 |
| `Ctrl-R` | Zeno のコマンド履歴を fzf で検索 |
| `Ctrl-X` → `Ctrl-K` | プロセスを fzf で選んで終了 (`SIGTERM`) |
| `Tab` | Zeno の補完 |

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

Zeno の SQLite 履歴を検索する。入力中のコマンドが初期クエリになる。

| キー | 用途 |
|---|---|
| `Enter` | 選択したコマンドをプロンプトへ挿入 |
| `Ctrl-R` | global / repository / directory / session のスコープを切り替える |
| `Ctrl-D` | 選択中の履歴を削除 |
| `?` | 右側の詳細プレビューを表示・非表示 |

### プロセス終了 (`Ctrl-X` → `Ctrl-K`)

`ps` の一覧を表示し、選択した PID へ通常の `SIGTERM` を送る。
強制終了 (`SIGKILL`) ではない。
コマンドラインに文字が入力されている場合は、それを初期クエリとして使う。

## Zeno

| キー | 用途 |
|---|---|
| `Space` | 一致する auto snippet を展開。なければ通常の空白を入力 |
| `Enter` | auto snippet を展開してコマンドを実行 |
| `Tab` | Zeno 補完 |
| `Ctrl-X` → `Space` | snippet 展開をせずに空白を入力 |
| `Ctrl-X` → `Enter` | snippet 展開をせずにコマンドを実行 |
| `Ctrl-X` → `Z` | auto snippet の有効・無効を切り替える |
| `Ctrl-X` → `S` | snippet を選んで挿入 |
| `Ctrl-X` → `F` | 次の snippet placeholder へ移動 |

Zeno の snippet 定義は `.config/zeno/` に置く。

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
