# Neovim チートシート

この dotfiles の lazy.nvim ベースの独自設定で、普段よく使いそうな操作だけをまとめる。

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
| `f{char}` / `F{char}` | 行内の右 / 左にある文字へ移動 |
| `t{char}` / `T{char}` | 行内の右 / 左にある文字の手前へ移動 |
| `;` / `,` | 直前の `f` / `F` / `t` / `T` を同方向 / 逆方向へ繰り返す |
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
| `<leader>-` / `<leader>\|` | 下 / 右に window を分割 |
| `<C-Up>` / `<C-Down>` | window の高さを増減 |
| `<C-Left>` / `<C-Right>` | window の幅を増減 |
| `:bd` | buffer を閉じる |
| `:bnext` / `:bprev` | 次 / 前の buffer |
| `:tabnew` | 新しい tab |
| `gt` / `gT` | 次 / 前の tab |

## ファイル操作

| キー / コマンド | 用途 |
|---|---|
| `<leader>e` | Snacks Explorer を Git root で開く |
| `<leader>E` | Snacks Explorer をカレントディレクトリで開く |
| `<leader>fy` | Yazi を現在のファイル位置で開く |
| `<leader>cw` | Yazi を Neovim のカレントディレクトリで開く |
| Explorer で `a` | ファイルまたはディレクトリを作成 |
| Explorer で `r` | rename |
| Explorer で `d` | 削除 |
| Explorer で `c` / `m` | copy / move |

## Terminal

汎用 terminal は ToggleTerm を使う。

| キー | 用途 |
|---|---|
| `<C-/>` / `<C-_>` | floating terminal を開閉 |
| Terminal で `Ctrl-\` → `Ctrl-N` | Terminal mode から Normal mode へ移動 |
| Normal mode で `i` | Terminal mode へ戻る |

## Snacks / Picker 系

picker は Snacks を使う。

| キー | 用途 |
|---|---|
| `<leader><space>` | Git root からファイル検索 |
| `<leader>ff` | Git root からファイル検索 |
| `<leader>fF` | カレントディレクトリからファイル検索 |
| `<leader>fg` | Git 管理対象のファイル検索 |
| `<leader>/` / `<leader>sg` | Git root から grep |
| `<leader>sw` | カーソル下の単語または Visual 選択を Git root から grep |
| `<leader>,` | Buffers |
| `<leader>sd` / `<leader>sD` | 全体 / 現在の buffer の diagnostic 一覧 |
| Explorer で `H` | hidden files toggle |
| Explorer で `I` | ignored files toggle |

Explorer は初期状態で hidden files を表示し、ignored files は非表示にしている。
`H` / `I` は開いている Explorer インスタンスの一時 toggle。

## Git / Diff

| キー | 用途 |
|---|---|
| `<leader>gd` | 作業ツリー全体を Diffview で開く |
| `<leader>gH` | リポジトリ全体のファイル履歴を Diffview で開く |
| `<leader>gF` | 現在のファイル履歴を Diffview で開く |
| `<leader>gg` | Git root で lazygit を開く |
| `]h` / `[h` | 次 / 前の Git hunk |
| `<leader>ghp` | 現在の hunk を inline preview |

## LSP

| キー | 用途 |
|---|---|
| `gd` | 定義へ |
| `gD` | 定義一覧を Glance で表示 |
| `gr` | 参照一覧 |
| `gI` | 実装へ |
| `gy` | 型定義へ |
| `gR` / `gY` / `gM` | 参照 / 型定義 / 実装を Glance で表示 |
| `K` | hover |
| `<leader>ca` | code action |
| `<leader>cr` | rename |
| `[d` / `]d` | 前 / 次の diagnostic |
| `[e` / `]e` | 前 / 次の error |
| `[w` / `]w` | 前 / 次の warning |
| `<leader>cd` | カーソル行の diagnostic を表示 |

## Markdown

| キー / コマンド | 用途 |
|---|---|
| `<leader>cp` | md-render floating preview toggle |
| `:MdRender split` | ソースとレンダリングを分割表示 |
| `:MdRender tab` | レンダリングをタブ表示 |
| `:RenderMarkdown toggle` | render-markdown toggle |

`<!-- ... -->` は `render-markdown.nvim` で conceal しない設定にしている。

## 調査

| コマンド | 用途 |
|---|---|
| `:verbose nmap <key>` | Normal mode の keymap 定義元を見る |
| `:verbose xmap <key>` | Visual mode の keymap 定義元を見る |
| `:Lazy` | plugin 状態を見る |
| `:checkhealth` | health check |
| `nvim --startuptime /tmp/nvim.log +q` | 起動時間ログを取る |
