# AeroSpace

macOS 用の i3 風タイリングウィンドウマネージャ。
本体は Homebrew cask、設定は `.config/aerospace/aerospace.toml` を Home Manager が symlink する。
JankyBordersもHome Managerで導入し、AeroSpace起動時に角丸・幅1.5の枠を表示する
（`order=above`、activeはCatppuccinのmauve `#cba6f7`、inactiveは20%透過の`#494d64`）。
GUI起動のAeroSpaceはHomebrewと`/usr/bin`のPATHしか持たないため、
`[exec.env-vars]`で`~/.nix-profile/bin`を足して`borders`を解決している。
ウィンドウ間・画面端の余白は3。

## ワークスペース

役割で固定する。数字は 1〜3 を残し、`3` を catch-all にしている。空でも消えないよう
`persistent-workspaces` にすべて並べてある。

| WS | 役割 | 割り当て |
|---|---|---|
| `W` | ブラウザ | Safari, Google Chrome |
| `T` | ターミナル | Ghostty |
| `C` | コミュニケーション | Discord, LINE, メール |
| `D` | 開発 | Android Studio, T3 Code, Zed, VS Code Insiders |
| `A` | AI | ChatGPT, Claude, Muse, Grok Bot |
| `M` | メディア | ミュージック |
| `1` / `2` | 一時置き場 | 手動で置く |
| `3` | その他（catch-all） | 上記以外すべて |

AeroSpace はウィンドウの配置を覚えないため、`on-window-detected` のルールで検出のたびに
寄せ直す。ルールは上から順に評価され、最初にマッチしたものだけが実行されるので
catch-all は必ず末尾に置く。設定アプリ・1Password・Karabiner・Finder は catch-all より前に
フロート指定があり、開いた場所に浮いたまま残る（Finder はファイル操作の補助なのでタイルに混ぜない）。

ルールを変更した後は、開いているウィンドウにも再適用できる。

```sh
aerospace run-callback --for-every-window on-window-detected
```

`aerospace.toml` は `mkOutOfStoreSymlink` でリポジトリを直接指しているため、このファイルの
変更に `nix-switch` は不要（`auto-reload-config = true` なら保存で、手動なら
`aerospace reload-config` で反映される）。

## キーバインド

上流のデフォルトどおり `Alt`（Option）系。モニタ間の移動だけは上流に既定バインドが
無いため `Ctrl-Alt` で追加している（`focus` は既定で `--boundaries workspace` なので
`Alt-h/j/k/l` はモニタを跨がない）。

| キー | 動作 |
|---|---|
| `Alt-h/j/k/l` | フォーカス移動 |
| `Alt-Shift-h/j/k/l` | ウィンドウ移動 |
| `Alt-w` / `Alt-t` / `Alt-c` / `Alt-d` / `Alt-a` / `Alt-m` | ワークスペース切替（W / T / C / D / A / M） |
| `Alt-1` … `Alt-3` | ワークスペース切替（一時置き場・その他） |
| `Alt-Shift-w/t/c/d/a/m` | ウィンドウを各ワークスペースへ送る |
| `Alt-Shift-1` … `Alt-Shift-3` | ウィンドウを一時置き場・その他へ送る |
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

## 既知の制約

- 自動隠しの Dock でアイコンをクリックしても、別ワークスペースにいる起動中のアプリが
  前に出ないことがある。クリック時のリフレッシュが直前のワークスペースを復元するためで、
  上流の既知の問題（[#949](https://github.com/nikitabobko/AeroSpace/discussions/949),
  [#2223](https://github.com/nikitabobko/AeroSpace/discussions/2223)）。
  DockDoor のプレビューからウィンドウを選ぶ、`Alt-w/t/c/d/1/2/3` で切り替える、
  Dock の自動隠しを切る、のいずれかで回避する。
- DockDoor は `Alt-Tab` のウィンドウスイッチャーを内蔵しているが、AeroSpace が `Alt-Tab` を
  `workspace-back-and-forth` に使っているため通常は発火しない。併用するならどちらかのキーを変える。

## 初回セットアップ

1. `darwin-switch` で cask を入れる
2. `nix-switch` で設定を配置する
3. AeroSpace.app を起動する
4. システム設定 → プライバシーとセキュリティ → アクセシビリティ で AeroSpace を許可する
5. マルチモニタなら、各モニタの右下または左下に空きが出るよう配置する

設定は `auto-reload-config = true` なので、初回の `Esc`（service モード）以降は
toml を保存すると自動で再読み込みされる。
