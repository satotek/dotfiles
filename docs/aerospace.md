# AeroSpace

macOS 用の i3 風タイリングウィンドウマネージャ。
本体は Homebrew cask、設定は `.config/aerospace/aerospace.toml` を Home Manager が symlink する。
JankyBordersもHome Managerで導入し、AeroSpace起動時に幅3の枠を表示する。
ウィンドウ間・画面端の余白は3。

Safariの新しいウィンドウはワークスペース1へ自動配置する。
Ghosttyはワークスペース2で開く運用とし、タブ追加時の配置を保つため自動移動は指定しない。

## キーバインド

上流のデフォルトどおり `Alt`（Option）系。モニタ間の移動だけは上流に既定バインドが
無いため `Ctrl-Alt` で追加している（`focus` は既定で `--boundaries workspace` なので
`Alt-h/j/k/l` はモニタを跨がない）。

| キー | 動作 |
|---|---|
| `Alt-h/j/k/l` | フォーカス移動 |
| `Alt-Shift-h/j/k/l` | ウィンドウ移動 |
| `Alt-1` … `Alt-9` | ワークスペース切替 |
| `Alt-Shift-1` … `Alt-9` | ウィンドウをワークスペースへ送る |
| `Alt-/` | tiles の横 / 縦切替 |
| `Alt-,` | accordion の横 / 縦切替 |
| `Alt--` / `Alt-=` | リサイズ |
| `Alt-f` | 最大化トグル（AeroSpace 独自。ネイティブ全画面ではない） |
| `Alt-Tab` | 直前のワークスペースへ戻る |
| `Alt-Shift-Tab` | ワークスペースを次のモニタへ |
| `Ctrl-Alt-h/j/k/l` | モニタ間のフォーカス移動 |
| `Ctrl-Alt-Shift-h/j/k/l` | ウィンドウを隣のモニタへ（フォーカスも追従） |
| `Alt-Shift-;` | service モード |
| `Ctrl-Alt-w` | Window モード |
| `Ctrl-Alt-Space` | Layout モード |

### Window / Layout モード

各モードでは修飾キーなしで操作し、`Esc`でmainに戻る。操作後もモードは維持する。
`Ctrl-Alt-w`と`Ctrl-Alt-Space`でWindow / Layoutを相互に切り替えられる。

| モード | キー | 動作 |
|---|---|---|
| Window | `h/j/k/l` | 隣のコンテナと結合 |
| Window | `m` | 次のモニタへフォーカス移動 |
| Window | `Shift-m` / `Ctrl-m` | ウィンドウを次 / 前のモニタへ（フォーカスも追従） |
| Window | `s` / `d` | 縮小 / 拡大 |
| Layout | `t` / `c` | tiles / accordion |
| Layout | `f` | フロート / タイル切替 |
| Layout | `h` / `v` | 横 / 縦配置 |
| Layout | `b` | ウィンドウサイズを均等化 |
| Layout | `r` | レイアウトをリセット |

### service モード

| キー | 動作 |
|---|---|
| `Esc` | 設定を再読み込みして main に戻る |
| `r` | レイアウトをリセット |
| `f` | フロート / タイル切替 |
| `Backspace` | カレント以外のウィンドウを閉じる |
| `Alt-Shift-h/j/k/l` | 隣のコンテナと結合 |

## 初回セットアップ

1. `darwin-switch` で cask を入れる
2. `nix-switch` で設定を配置する
3. AeroSpace.app を起動する
4. システム設定 → プライバシーとセキュリティ → アクセシビリティ で AeroSpace を許可する
5. マルチモニタなら、各モニタの右下または左下に空きが出るよう配置する

設定は `auto-reload-config = true` なので、初回の `Esc`（service モード）以降は
toml を保存すると自動で再読み込みされる。
