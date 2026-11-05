# VM リモート作業ワークフロー (Herdr + SSH 動的フォワード / SOCKS)

Azure 上の VM (`vm` = `172.207.57.61`) や `gem-ai` に対する日常のリモート作業ワークフローをまとめる。
Herdr の運用、SSH 接続共有 (ControlMaster)、および必要な時だけポートを開通する動的フォワード／SOCKS プロキシの仕組みを扱う。

- **ローカル / ホスト**: 手元の Mac（ブラウザや GUI クライアントがある側）
- **リモート**: Azure VM（コード編集・開発サーバー・T3 Code サーバーが稼働する側）

---

## 1. Herdr

AI エージェント特化のターミナルマルチプレクサ。各ペインのエージェント状態（working / idle / blocked）を可視化し、セッション復元やエージェント連携フックを提供する。

### パッケージと設定管理

- **CLI 本体 (`herdr`) / サーバー (`herdr-core` / `hc`)**:
  - Home Manager の `cli` プリセット（`programs.herdr` / `pkgs.llm-agents.herdr` および `pkgs.llm-agents.herdr-core`）として管理。
  - macOS・Linux（VM 側含む）の両方に導入される。
  - プレフィックスキーは Neovim や Zsh と競合しにくい `Ctrl-Q` に設定。
  - 起動シェルは Nix 製の Zsh（`/bin/zsh`）を指定し、OS 標準 Zsh と Nix 製 `fzf-tab` バイナリモジュール間の glibc 不一致を防止している。
- **macOS GUI クライアント (`herdr-app`)**:
  - `nix/nix-darwin/homebrew.nix` の Cask（`casks = [ "herdr-app" ]`）で導入。
  - キーバインドや mod 設定は `nix/home-manager/programs/herdr-app.nix` で `~/.config/herdr-app/keys.json` に activation でマージ。
- **Herdr 公式スキル**:
  - `flake.nix` の `herdr-skill` input から抽出し、`~/.claude/skills/herdr/` および `~/.agents/skills/herdr/` に配置。
  - `HERDR_ENV=1` ガードがあるため、Herdr パネル外では無害。

### リモート連携

```console
herdr --remote vm            # ローカルクライアントから VM 上の Herdr サーバーへ接続
```

- クライアント側でターミナルが動くため、**画像のクリップボード貼り付けがリモートのエージェントにもそのまま通る**（素の `ssh + tmux` ではクリップボードが途切れる問題を解消）。
- **注意**: `herdr --remote vm` ペイン内のシェルは **VM 側のシェル**。Mac 側で定義された後述の `vmfwd` や `vmproxy` は VM 内では実行できないため、手元のローカルターミナルで実行すること。

---

## 2. SSH 接続共有 (ControlMaster)

`~/.ssh/config` の `Host vm` に多重化設定を記述する（このファイルは手動管理）。

```sshconfig
Host vm
  HostName 172.207.57.61
  User azureuser
  Port 22
  # 接続を1本のマスターソケットに集約。フォワードは vmfwd / vmproxy で動的に追加・解除する。
  # 常時の静的 LocalForward は記述しない（VM側サービス未起動時の channel open failed 回避）。
  ControlMaster auto
  ControlPath  ~/.ssh/cm/%r@%h:%p
  ControlPersist 10m
```

初回のみソケット用ディレクトリを作成する:

```console
mkdir -p ~/.ssh/cm && chmod 700 ~/.ssh/cm
```

効果:
- 2本目以降の SSH 接続が認証不要で即時に確立される（Herdr の再接続も高速化）。
- 稼働中のマスターソケットに対して、ポートフォワードを後から動的に追加・削除できる。

接続の確認:

```console
ssh -G vm | grep -i controlmaster   # "controlmaster auto" と出れば有効
ssh -O check vm                     # "Master running (pid=...)" ならマスター接続中
```

---

## 3. 動的ポートフォワード (`vmfwd`)

特定のポートだけを Mac ↔ VM 間で転送したい場合に使用する。Zsh 関数は `nix/home-manager/programs/zsh/vm.zsh` に定義されている。

```console
vmfwd 8090             # localhost:8090 (Mac) -> vm:8090 を動的に追加
vmunfwd 8090           # フォワードを解除
vmfwls                 # マスター接続の生存確認 (ssh -O check vm)
```

- 実体は `ssh -O forward -L <l>:localhost:<r> vm` / `ssh -O cancel ...`。
- ポート番号を省略すると、ローカルとリモートで同じポート番号が使われる。
- 稼働中のマスター接続に対してポートを追加するため、静的な `LocalForward` を config に並べる必要がない。

---

## 4. SOCKS プロキシ (`vmproxy` / `vmbrowse`)

ポートごとの個別転送を行わず、VM 側で立ち上げた任意のポート・サービスへ透過的にアクセスしたい場合に使用する。

```console
vmproxy                # SOCKS プロキシを localhost:1080 に起動
vmbrowse               # SOCKS 経由の専用 Chrome プロファイルを開く
vmunproxy              # SOCKS プロキシを解除
```

### 仕組みと特徴

- **自動マスター起動**: `vmproxy` の実行時、マスター接続が存在しなければ自動的に `ssh -fN vm` をバックグラウンド起動してから `ssh -O forward -D 127.0.0.1:1080 vm` を呼び出す。
- **DNS と Loopback の解決**: SOCKS5 経由の接続は VM 側から発信されるため、ブラウザで開く `localhost:<port>` は「VM 内の localhost」に届く。
- **Loopback 除外の解除**: 一般的なブラウザは `localhost` / `127.0.0.1` をプロキシから除外する。`vmbrowse` は `--proxy-bypass-list="<-loopback>"` を指定して localhost も SOCKS 経由に回し、`--user-data-dir` を分けた隔離プロファイル（`${XDG_CACHE_HOME:-~/.cache}/chrome-vm-proxy`）で起動するため、日常の通常ブラウジングに影響を与えない。
- **動作検証**:
  ```console
  curl --socks5-hostname 127.0.0.1:1080 https://api.ipify.org
  ```
  上記の出力が VM のパブリック IP（`172.207.57.61`）と一致すれば正しく経由できている。

### サブドメインルーティング (portless 等)

VM 側で `portless` 等のサブドメインルーティング（例: `a.localhost:1355`、`b.localhost:1355`）を利用している場合、`vmbrowse` のウィンドウでそのままアクセスできる。名前解決と HTTP `Host` ヘッダーが VM 側で保持されるため、ポートごとの個別設定は不要。

> [!NOTE]
> VM 側で `*.localhost` が IPv6（`::1`）に解決される場合がある。サービス側が IPv4（`127.0.0.1`）のみで listen していると届かないことがあるため、その場合はサービスをデュアルスタック（`::` / 両対応）で listen させる。

---

## 5. T3 Code サーバー (`gem-ai`) との接続

`azureuser@gem-ai` ホストでは、T3 Code の headless server（ポート `3773`）が Home Manager の `programs.t3code.server` により systemd ユーザーサービスとして稼働している。

手元の Mac（GUI クライアント `t3-code`）から接続する方法は2通りある:

1. **T3 Connect（トンネル）経由**:
   - 初回に VM 上で `t3 connect` を実行してサインインしておくと、サービス起動時に自動でトンネルリンクが維持される。
   - 手元の T3 Code アプリから組織の T3 アカウント経由で接続する。
2. **SSH ポートフォワード経由**:
   - `vmfwd 3773` を実行して `localhost:3773` を手元に引き込む。
   - 手元の T3 Code クライアントからローカルサーバーとして接続する。

---

## 6. Windows での手順

| 機能 | macOS | Windows ネイティブ | WSL |
|---|---|---|---|
| `ssh -D` (SOCKS) | ✅ | ✅ | ✅ |
| 専用 Chrome + loopback 解除 | ✅ | ✅ | ✅ |
| ControlMaster / `ssh -O forward` | ✅ | ❌ 未対応 | ✅ |

Windows ネイティブの OpenSSH は接続多重化（ControlMaster）をサポートしていない（[Win32-OpenSSH #1328](https://github.com/PowerShell/Win32-OpenSSH/issues/1328)）。
そのため、ネイティブ環境では SOCKS 用 SSH プロセスを常駐させる方式を用いるか、WSL を利用する。

### 6-A. ネイティブ PowerShell

`%USERPROFILE%\.ssh\config` に `Host vm` を設定し（ControlMaster 設定は除く）、PowerShell プロファイル（`$PROFILE`）に以下を定義する。

```powershell
function vmproxy {
    param([int]$Port = 1080)
    $running = Get-CimInstance Win32_Process -Filter "Name='ssh.exe'" |
        Where-Object { $_.CommandLine -match "-D\s+$Port\b" }
    if ($running) { Write-Host "already up on :$Port"; return }
    Start-Process ssh -ArgumentList "-N","-D","$Port","vm" -WindowStyle Hidden
    Write-Host "SOCKS up: socks5://127.0.0.1:$Port (via vm)"
}

function vmunproxy {
    param([int]$Port = 1080)
    Get-CimInstance Win32_Process -Filter "Name='ssh.exe'" |
        Where-Object { $_.CommandLine -match "-D\s+$Port\b" } |
        ForEach-Object { Stop-Process -Id $_.ProcessId -Force }
    Write-Host "SOCKS down: :$Port"
}

function vmbrowse {
    param([string]$Url = "http://localhost:8090", [int]$Port = 1080)
    $chrome = "${env:ProgramFiles}\Google\Chrome\Application\chrome.exe"
    Start-Process $chrome -ArgumentList `
        "--user-data-dir=$env:LOCALAPPDATA\chrome-vm-proxy", `
        "--proxy-server=socks5://127.0.0.1:$Port", `
        "--proxy-bypass-list=<-loopback>", `
        $Url
}
```

### 6-B. WSL

WSL（Ubuntu 等）は Linux ネイティブの OpenSSH が稼働するため、macOS と全く同一の ControlMaster 構成が利用できる。
本リポジトリの WSL 向け構成（`nosuke@nosuke-windows` / `stko23@stko23-windows`）を適用することで、`vmfwd` や `vmproxy` などの関数がそのまま利用可能になる。
