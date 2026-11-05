# Neovim チートシート

この dotfiles の lazy.nvim ベースの独自設定で、普段よく使う操作とキーバインドをまとめる。

## 基本

| キー | 用途 |
|---|---|
| `i` | 挿入モード |
| `a` | カーソル後ろから挿入 |
| `Esc` | Normal mode に戻る（同時に検索ハイライトを消す） |
| `:w` / `<C-s>` | ファイルを保存（Normal / Insert / Visual） |
| `:q` | 閉じる |
| `:wq` | 保存して閉じる |
| `:qa` / `<leader>qq` | すべて閉じる |
| `u` | undo |
| `<C-r>` | redo |
| `.` | 直前の変更を繰り返す |

## 移動

| キー | 用途 |
|---|---|
| `h` / `j` / `k` / `l` | 左 / 下 / 上 / 右（表示行単位で移動） |
| `w` / `b` | 次 / 前の単語の先頭へ |
| `0` / `^` / `$` | 行頭 / 最初の非空白文字 / 行末 |
| `gg` / `G` | ファイル先頭 / 末尾 |
| `{` / `}` | 前 / 次の段落 |
| `%` | 対応する括弧・タグへ移動 (`vim-matchup`) |
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
| `:noh` / `Esc` | 検索ハイライトを消す |

## 編集

| キー | 用途 |
|---|---|
| `dd` | 行削除 |
| `yy` | 行コピー |
| `p` / `P` | カーソルの後ろ / 前に貼り付け |
| `ciw` / `diw` | 単語の中身を変更 / 削除 |
| `ci"` / `di"` | `"` の中身を変更 / 削除 |
| `ci(` / `di(` | `()` の中身を変更 / 削除 |
| `<A-j>` / `<A-k>` | 現在行（Visual 選択時は選択範囲）を上下に移動 |
| `>>` / `<<` | インデントを増減 |
| `=` | 選択範囲や motion を整形 |
| `sa` / `sd` / `sr` | 囲み文字を追加 / 削除 / 置換 (`mini.surround`) |

## コメント

| キー | 用途 |
|---|---|
| `gcc` | 現在行のコメントをトグル |
| `3gcc` | 3行まとめてコメントをトグル |
| Visual 選択後 `gc` | 選択範囲のコメントをトグル |
| `gcap` | 段落全体のコメントをトグル |

## Visual mode

| キー | 用途 |
|---|---|
| `v` | 文字単位選択 |
| `V` | 行単位選択 |
| `<C-v>` | 矩形選択 |
| `gv` | 直前の選択範囲を再選択 |
| `y` / `d` / `c` | 選択範囲をコピー / 削除 / 変更 |
| `<` / `>` | 選択を維持したままインデント増減 |

## ウィンドウ / バッファ / タブ

### ウィンドウ

| キー | 用途 |
|---|---|
| `<C-h>` / `<C-j>` / `<C-k>` / `<C-l>` | 左 / 下 / 上 / 右のウィンドウへ移動 |
| `<leader>-` / `<leader>\|` | 下 / 右にウィンドウを分割 |
| `<leader>wd` / `<C-w>q` | ウィンドウを閉じる |
| `<leader>wm` | ウィンドウの最大化トグル (`Snacks.toggle.zoom`) |
| `<C-w>=` | ウィンドウサイズを均等化 |
| `<C-Up>` / `<C-Down>` | ウィンドウの高さを増減 |
| `<C-Left>` / `<C-Right>` | ウィンドウの幅を増減 |

### バッファ

| キー | 用途 |
|---|---|
| `<S-h>` / `<S-l>` | 前 / 次のバッファへ移動 |
| `[b` / `]b` | 前 / 次のバッファへ移動 |
| `<leader>bb` | 直前のバッファへ切り替え |
| `<leader>bd` | 現在のバッファを閉じる (`Snacks.bufdelete`) |
| `<leader>bo` | 現在以外のバッファをすべて閉じる |
| `:bd` | バッファを閉じる |

### タブ

| キー | 用途 |
|---|---|
| `<leader><tab><tab>` / `:tabnew` | 新しいタブを開く |
| `<leader><tab>]` / `gt` | 次のタブへ移動 |
| `<leader><tab>[` / `gT` | 前のタブへ移動 |
| `<leader><tab>d` | タブを閉じる |
| `<leader><tab>o` | 他のタブをすべて閉じる |

## ファイル操作

| キー / コマンド | 用途 |
|---|---|
| `<leader>e` | Snacks Explorer を Git root で開く |
| `<leader>E` | Snacks Explorer をカレントディレクトリで開く |
| `<leader>fy` | Yazi を現在のファイル位置で開く |
| `<leader>cw` | Yazi を Neovim のカレントディレクトリで開く |
| Explorer 内 `a` | ファイルまたはディレクトリを新規作成 |
| Explorer 内 `r` | リネーム |
| Explorer 内 `d` | 削除 |
| Explorer 内 `c` / `m` | コピー / 移動 |
| Explorer 内 `H` | 隠しファイルの表示トグル（一時切り替え） |
| Explorer 内 `I` | 除外（ignored）ファイルの表示トグル（一時切り替え） |

## ターミナル

汎用ターミナルは ToggleTerm を使用する。Docker コンテナ管理には Oxker も呼び出せる。

| キー | 用途 |
|---|---|
| `<C-/>` / `<C-_>` | フローティングターミナルを開閉 |
| ターミナル内で `Ctrl-\` → `Ctrl-N` | Terminal mode から Normal mode へ抜ける |
| Normal mode で `i` | Terminal mode へ戻る |
| `<leader>D` | Oxker（Docker TUI）を起動 |

## Snacks / ファインダー・ピッカー

ピッカーには Snacks Picker を使用する。

| キー | 用途 |
|---|---|
| `<leader><space>` / `<leader>ff` | Git root からファイル検索 |
| `<leader>fF` | カレントディレクトリからファイル検索 |
| `<leader>fg` | Git 管理下のファイルを検索 (`git_files`) |
| `<leader>fr` | 最近開いたファイルを検索 (`recent`) |
| `<leader>,` / `<leader>fb` | 開いているバッファ一覧 |
| `<leader>/` / `<leader>sg` | Git root から全文 grep |
| `<leader>sG` | カレントディレクトリから全文 grep |
| `<leader>sw` | カーソル下の単語または Visual 選択範囲を grep |
| `<leader>sb` | 現在のバッファ内を行単位で検索 (`lines`) |
| `<leader>sd` / `<leader>sD` | ワークスペース全体 / 現在バッファの診断一覧 |
| `<leader>ss` / `<leader>sS` | LSP シンボル一覧 / ワークスペースシンボル一覧 |
| `<leader>sR` | 直前のピッカー結果を再開 (`resume`) |
| `<leader>n` | 通知履歴を表示 |

## Git / Diff

| キー | 用途 |
|---|---|
| `<leader>gd` | 作業ツリー全体の差分を Diffview で開く |
| `<leader>gH` | リポジトリ全体のコミット履歴を Diffview で開く |
| `<leader>gF` | 現在のファイルの変更履歴を Diffview で開く |
| `<leader>gg` | Git root で Lazygit を開く |
| `]h` / `[h` | 次 / 前の Git hunk へ移動 |
| `<leader>ghp` | カーソル位置の hunk をインラインプレビュー |
| `<leader>ghs` / `<leader>ghr` | カーソル位置の hunk をステージ / リセット |
| `<leader>ghb` | カーソル行の blame を表示 |

## LSP / 診断

| キー | 用途 |
|---|---|
| `gd` | 定義へジャンプ (`Snacks.picker.lsp_definitions`) |
| `gD` | 定義一覧を Glance でプレビュー |
| `gr` | 参照一覧 (`Snacks.picker.lsp_references`) |
| `gR` | 参照一覧を Glance でプレビュー |
| `gI` | 実装へジャンプ |
| `gM` | 実装一覧を Glance でプレビュー |
| `gy` | 型定義へジャンプ |
| `gY` | 型定義一覧を Glance でプレビュー |
| `K` | ホバー情報（ドキュメント）を表示 |
| `<leader>ca` | コードアクションを実行 |
| `<leader>cr` | シンボルのリネーム (`IncRename`) |
| `<leader>cf` | ファイルのフォーマットを実行 |
| `[d` / `]d` | 前 / 次の診断（エラー・警告等）へ移動 |
| `[e` / `]e` | 前 / 次のエラーへ移動 |
| `[w` / `]w` | 前 / 次の警告へ移動 |
| `<leader>cd` | カーソル行の診断メッセージをフロート表示 |
| `[q` / `]q` | 前 / 次の Quickfix 項目へ移動 |

## UI トグル (`Snacks.toggle`)

| キー | 用途 |
|---|---|
| `<leader>ud` | 診断表示（Diagnostics）のトグル |
| `<leader>ul` / `<leader>uL` | 行番号 / 相対行番号のトグル |
| `<leader>uh` | Inlay Hints のトグル |
| `<leader>uw` | テキスト折り返し（Wrap）のトグル |
| `<leader>uz` | Zen モード（集中モード）のトグル |
| `<leader>wm` | ウィンドウ最大化（Zoom）のトグル |

## Markdown

| キー / コマンド | 用途 |
|---|---|
| `<leader>cp` | md-render のフローティングプレビューをトグル |
| `:MdRender split` | ソースとレンダリング結果を分割表示 |
| `:MdRender tab` | レンダリング結果をタブ表示 |
| `:RenderMarkdown toggle` | render-markdown のインライン装飾をトグル |

> [!NOTE]
> HTML コメント（`<!-- ... -->`）は非表示（conceal）にせず、編集しやすいよう常に表示される設定にしている。

## 設定・診断コマンド

| コマンド | 用途 |
|---|---|
| `:Lazy` | プラグインの管理画面を開く |
| `:checkhealth` | Neovim と各プラグインのヘルスチェックを実行 |
| `:verbose nmap <key>` | Normal mode のキーマップ定義元を確認 |
| `:verbose xmap <key>` | Visual mode のキーマップ定義元を確認 |
| `nvim --startuptime /tmp/nvim.log +q` | 起動時間をプロファイリングする |
