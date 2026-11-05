# Determinate Nix から通常 Nix への移行

このドキュメントは、Determinate Nix（Determinate Systems の nix-installer）が導入された環境から、本リポジトリが前提とする公式の通常 Nix（Upstream Nix）のマルチユーザー構成へ移行する方針と手順をまとめたものです。

> [!WARNING]
> 既存の `/nix/store` を保持したままの自動移行処理は提供されていません。アンインストーラーの実行によって store やプロファイルは初期化される前提で進めてください。`/nix/store` の手動削除や、既存環境へのインストーラーの重ね掛けは行いません。

---

## 1. 導入状態の確認

対象マシンに Determinate Nix が導入されているかを判定します。通常 Nix が既に導入されている環境では再インストールの必要はありません。

```sh
# Nix のバージョンとパス確認
nix --version
which nix

# Determinate 関連コマンドや記録の確認
command -v determinate-nixd
ls -l /nix/receipt.json 2>/dev/null
```

### 稼働デーモンの確認

- **Linux / WSL**:
  ```sh
  systemctl status determinate-nixd.service
  ```
- **macOS**:
  ```sh
  sudo launchctl list | grep -i determinate
  ```

---

## 2. 移行前の保全

アンインストールにより Nix 関連のバイナリやプロファイルが削除されるため、事前に必要なデータを退避します。

- **dotfiles の作業状態**: 未コミットの変更をコミットまたはリモートに退避する。
- **リポジトリ外の設定・機密情報**: `~/.config/git.local`、`~/.config/zsh.local`、SSH 鍵、各種認証情報などを安全な場所にバックアップする。
- **WSL の場合**: Windows 側で `wsl --export` を実行してディストリビューションのバックアップを取り、可能なら複製環境で移行を検証する。WSL 停止時は SSH 接続も切れるため、Windows 側から復旧できる手段を確保しておく。

---

## 3. アンインストールと再導入

### macOS

> [!IMPORTANT]
> Determinate が稼働している macOS 環境では、**絶対にそのまま `darwin-switch` を実行しないでください**。デーモンや `/nix` の APFS ボリュームマウントの管理競合が発生します。

1. **Determinate Nix のアンインストール**:
   公式のアンインストーラーを実行します。
   ```sh
   /nix/nix-installer uninstall
   ```
2. **通常 Nix のインストール**:
   [README の導入手順](../README.md#1-nixをインストール)に従い、マルチユーザー構成（`--daemon`）でインストールします。
   ```bash
   sh <(curl --proto '=https' --tlsv1.2 -fsSL https://nixos.org/nix/install) --daemon
   ```
3. **nix-darwin と Home Manager の再適用**:
   通常 Nix への切り替え後は、nix-darwin が Nix 本体・デーモン・キャッシュ設定を管理します。初回適用コマンドから再構成します。

### Linux / WSL

1. **Determinate Nix のアンインストール**:
   インストール記録に対応したアンインストーラーを実行します。
   ```sh
   /nix/nix-installer uninstall
   ```
   Determinate の補助サービス（`determinate-nixd`）が完全に停止・削除されたことを確認します。
2. **通常 Nix のインストール**:
   [README の導入手順](../README.md#1-nixをインストール)に従い、マルチユーザー構成でインストールします。
   ```bash
   sh <(curl --proto '=https' --tlsv1.2 -fsSL https://nixos.org/nix/install) --daemon
   ```
3. **キャッシュとデーモンの設定**:
   `/etc/nix/nix.conf` に numtide と satotek のキャッシュ設定を追加し、デーモンを再起動します。
   ```sh
   sudo systemctl restart nix-daemon.service
   ```
4. **Home Manager の復元**:
   `nix run home-manager/master -- switch ...` でホーム環境を再適用します。ログインシェルが Nix の Zsh に向いているかも確認します。

---

## 4. 移行後の検証チェックリスト

- [ ] **デーモン状態**: 通常 Nix の本体とデーモン（`nix-daemon`）が正常に稼働し、Determinate 関連サービスが残っていないこと。
- [ ] **キャッシュ取得**: `satotek.cachix.org` および `cache.numtide.com` からバイナリキャッシュが取得でき、署名検証に成功すること。
- [ ] **レイヤー適用**: `nix-switch`（macOS では `darwin-switch`）がエラーなく完了すること。
- [ ] **定期 GC**: `nh clean` による世代整理ジョブが意図通り設定されていること（重複した別 GC ジョブがないこと）。
- [ ] **マシン再起動**: 再起動後もデーモンが正常起動し、`/nix` が正しくマウントされること。

> [!NOTE]
> `nix-switch` はホーム環境を切り替えるコマンドであり、Nix 本体の構成やデーモンを切り替えるものではありません。リポジトリ側の更新と各実機の Nix インストール移行は独立した作業です。
