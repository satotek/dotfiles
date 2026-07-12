# Neovim チートシート

この dotfiles の LazyVim ベース設定で、普段よく使いそうな操作だけをまとめる。

## 基本

| キー | 用途 |
|---|---|
| `i` | 挿入モード |
| `a` | カーソル後ろから挿入 |
| `Esc` | Normal mode に戻る |
| `:w` | 保存 |
| `:q` | 閉じる |
| `:wq` | 保存して閉じる |
| `:qa` | 全部閉じる |
| `u` | undo |
| `<C-r>` | redo |
| `.` | 直前の変更を繰り返す |

## 移動

| キー | 用途 |
|---|---|
| `h` / `j` / `k` / `l` | 左 / 下 / 上 / 右 |
| `w` / `b` | 次 / 前の単語へ |
| `0` / `^` / `$` | 行頭 / 最初の非空白 / 行末 |
| `gg` / `G` | ファイル先頭 / 末尾 |
| `{` / `}` | 前 / 次の段落 |
| `%` | 対応する括弧・タグなどへ移動 (`vim-matchup`) |
| `<C-o>` / `<C-i>` | ジャンプ履歴を戻る / 進む |

## 検索

| キー | 用途 |
|---|---|
| `/word` | 前方検索 |
| `?word` | 後方検索 |
| `n` / `N` | 次 / 前の検索結果 |
| `*` / `#` | カーソル下の単語を前方 / 後方検索 |
| `:noh` | 検索ハイライトを消す |

## 編集

| キー | 用途 |
|---|---|
| `dd` | 行削除 |
| `yy` | 行コピー |
| `p` / `P` | 後ろ / 前に貼り付け |
| `ciw` | 単語の中身を変更 |
| `diw` | 単語の中身を削除 |
| `ci"` | `"` の中身を変更 |
| `di(` | `()` の中身を削除 |
| `>>` / `<<` | インデント増減 |
| `=` | 選択範囲や motion を整形 |

## コメント

| キー | 用途 |
|---|---|
| `gcc` | 現在行をコメント toggle |
| `3gcc` | 3行コメント toggle |
| Visual 選択後 `gc` | 選択範囲をコメント toggle |
| `gcap` | 段落をコメント toggle |

`gcc` は toggle なので、コメント解除も同じキー。

## Visual mode

| キー | 用途 |
|---|---|
| `v` | 文字単位選択 |
| `V` | 行単位選択 |
| `<C-v>` | 矩形選択 |
| `gv` | 直前の選択範囲を再選択 |
| `y` / `d` / `c` | 選択範囲をコピー / 削除 / 変更 |

## Window / Buffer / Tab

| キー | 用途 |
|---|---|
| `<C-w>h/j/k/l` | window 移動 |
| `<C-w>s` / `<C-w>v` | 水平 / 垂直 split |
| `<C-w>q` | window を閉じる |
| `<C-w>=` | window サイズを揃える |
| `:bd` | buffer を閉じる |
| `:bnext` / `:bprev` | 次 / 前の buffer |
| `:tabnew` | 新しい tab |
| `gt` / `gT` | 次 / 前の tab |

## ファイル操作

| キー / コマンド | 用途 |
|---|---|
| `<leader>e` | Snacks Explorer を開く |
| `nvim .` | Snacks Explorer でカレントディレクトリを開く |
| Explorer で `a` | ファイルまたはディレクトリを作成 |
| Explorer で `r` | rename |
| Explorer で `d` | 削除 |
| Explorer で `c` / `m` | copy / move |

## Terminal

汎用 terminal は ToggleTerm を使う。Snacks Terminal の標準キーは無効化している。

| キー | 用途 |
|---|---|
| `<C-/>` | floating terminal を開閉 |
| Terminal で `Ctrl-\` → `Ctrl-N` | Terminal mode から Normal mode へ移動 |
| Normal mode で `i` | Terminal mode へ戻る |

## Snacks / Picker 系

LazyVim の picker は Snacks を使う。

| キー | 用途 |
|---|---|
| `<leader><space>` | Smart find files |
| `<leader>ff` | Find files |
| `<leader>fg` | Git files |
| `<leader>/` | Grep |
| `<leader>,` | Buffers |
| `<leader>e` | Explorer |
| Explorer で `H` | hidden files toggle |
| Explorer で `I` | ignored files toggle |

Explorer は初期状態で hidden files を表示し、ignored files は非表示にしている。
`H` / `I` は開いている Explorer インスタンスの一時 toggle。

## LSP

| キー | 用途 |
|---|---|
| `gd` | 定義へ |
| `gD` | 宣言へ |
| `gr` | 参照一覧 |
| `gI` | 実装へ |
| `gy` | 型定義へ |
| `K` | hover |
| `<leader>ca` | code action |
| `<leader>cr` | rename |
| `[d` / `]d` | 前 / 次の diagnostic |

## Markdown

| キー / コマンド | 用途 |
|---|---|
| `<leader>cp` | Markdown preview toggle |
| `<leader>um` | render-markdown toggle |

`<!-- ... -->` は `render-markdown.nvim` で conceal しない設定にしている。

## 調査

| コマンド | 用途 |
|---|---|
| `:verbose nmap <key>` | Normal mode の keymap 定義元を見る |
| `:verbose xmap <key>` | Visual mode の keymap 定義元を見る |
| `:Lazy` | plugin 状態を見る |
| `:checkhealth` | health check |
| `nvim --startuptime /tmp/nvim.log +q` | 起動時間ログを取る |
