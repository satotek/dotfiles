# AeroSpace

macOS 用の i3 風タイリングウィンドウマネージャ。
本体は Homebrew cask、設定は `.config/aerospace/aerospace.toml` を Home Manager が symlink する。

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
