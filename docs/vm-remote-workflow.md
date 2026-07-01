# VM リモート作業ワークフロー (herdr + SSH 動的フォワード / SOCKS)

azureuser の VM (`vm` = `172.207.57.61`) に対する日常のリモート作業まわりのメモ。
herdr の導入、SSH 接続共有、ポートフォワード(必要な時だけ張る方式)をまとめる。

- **ローカル / ホスト** = 手元の Mac(ブラウザがある側)
- **リモート** = azureuser の VM(コード・開発サーバが動く側)

---

## 1. herdr

tmux ライクな「AIエージェント特化ターミナルマルチプレクサ」。既存ターミナル(WezTerm 等)の
中で動き、各ペインのエージェント状態(working/idle/blocked)を表示する。

### 導入(mac のみ)

`nix/nix-darwin/homebrew.nix` の `brews` に宣言済み。反映は system レイヤーなので `darwin-switch`。

```nix
brews = [ "herdr" ];
```

> VM 側には入れていない。`herdr --remote vm` 実行時に、herdr が VM へ**ビルド済みバイナリを
> 自動DL**(`~/.local/bin/herdr`)してくれるため。

### remote 連携

```console
herdr --remote vm            # ローカルを薄いクライアントにして VM の herdr サーバへ接続
```

- ローカルクライアントが残るので、**画像のクリップボード貼り付けが VM のエージェントにも通る**
  (素の `ssh + tmux` では壊れる部分)。
- **注意**: `herdr --remote vm` のペイン内シェルは **VM 側のシェル**。後述の `vmfwd`/`vmproxy` は
  Mac 側のコマンドなので、herdr ペイン内(=VM)では動かない。別途 Mac のローカル端末で打つこと。

### herdr 公式 skill

`~/.claude/skills/herdr/` と `~/.agents/skills/herdr/` に配置(home レイヤー、全ホスト共通)。

- `flake.nix` … `herdr-skill` input(`flake = false`)
- `nix/home-manager/programs/agents-skills.nix` … SKILL.md を抽出する derivation + source + explicit

> upstream の SKILL.md はリポジトリ直下にあり、root の `CLAUDE.md` がファイル symlink のため、
> リポジトリを直接 discovery source にすると scanner が落ちる。SKILL.md だけをクリーンな
> `herdr/` ツリーへ `cp` して回避している。
> skill には `HERDR_ENV=1` ガードがあり、herdr パネル外では何もしない(全ホストに配っても無害)。

---

## 2. SSH 接続共有 (ControlMaster)

`~/.ssh/config` の `Host vm` に設定(**このファイルは git 管理外**なので手動で入れる)。

```sshconfig
Host vm
  HostName 172.207.57.61
  User azureuser
  Port 22
  # 接続を1本のマスターに集約。フォワードは vmfwd/vmproxy で動的に張る。
  # 静的な LocalForward は書かない(VM側サービス未起動時の "channel open failed" 回避)。
  ControlMaster auto
  ControlPath  ~/.ssh/cm/%r@%h:%p
  ControlPersist 10m
```

初回だけ制御ソケット用ディレクトリを作る:

```console
mkdir -p ~/.ssh/cm && chmod 700 ~/.ssh/cm
```

効果:

- `vm` への2本目以降の SSH が**再認証なしで即接続**(herdr の再接続も速くなる)。
- 稼働中のマスターに対して、フォワードを**動的に足す/外す**ことができる(下記)。

確認:

```console
ssh -G vm | grep -i controlmaster   # controlmaster auto と出れば反映済み
ssh -O check vm                     # "Master running (pid=...)" ならマスター生存
```

---

## 3. 動的ポートフォワード (`vmfwd`)

特定ポートだけを Mac ↔ VM で転送したい時。zsh 関数は `nix/home-manager/programs/zsh.nix` に定義。

```console
ssh vm                 # まずマスター接続を1本張る(herdr --remote vm でも可)
vmfwd 8090             # localhost:8090(Mac) -> vm:8090 を動的に追加
vmunfwd 8090           # 外す
vmfwls                 # マスター接続の生存確認 (ssh -O check vm)
```

- 実体は `ssh -O forward -L <l>:localhost:<r> vm` / `ssh -O cancel ...`。
- **稼働中のマスター接続が前提**。無い状態で撃つと `ssh -O forward` は失敗する。
- **VS Code の Ports パネルで足す/消すのに相当**。config に静的 `LocalForward` を書かずに済む。

---

## 4. SOCKS プロキシ (`vmproxy` / `vmbrowse`)

ポートごとの `-L` 転送すら不要にしたい時。SOCKS を1本張れば、以後 VM 側で好きなポートに
サーバを立てるだけで Mac から `localhost:<port>` で届く(VS Code の「勝手に見える」に近い体感)。

```console
vmproxy                       # SOCKS を localhost:1080 に張る(ssh -O forward -D)
vmbrowse                      # SOCKS 経由の隔離 Chrome で http://localhost:8090 を開く
vmbrowse http://localhost:3000
vmunproxy                     # 外す
```

### 仕組みと注意

- `ssh -D 1080 vm` で張った SOCKS を通る接続は **VM 側から発信**される。だからブラウザで
  `localhost:8090` を開くと「**VM の** localhost:8090」に届く。
- **落とし穴**: Chrome/大半のブラウザは `localhost`/`127.0.0.1` を**デフォルトでプロキシ除外**する。
  `vmbrowse` は `--proxy-bypass-list="<-loopback>"` で loopback 除外を解除し、localhost も
  SOCKS 経由に回している。さらに `--user-data-dir` を分けた**専用 Chrome プロファイル**で起動する
  ので、普段のブラウジングは SOCKS を経由しない。
- 検証: `curl --socks5-hostname 127.0.0.1:1080 https://api.ipify.org` が **VM の IP**
  (`172.207.57.61`)を返せば正しく経由できている。

### portless(subdomain 経由)で複数サービスに到達

VM 側で portless 等の subdomain ルーティング(例: `a.localhost:1355` → サービスA、
`b.localhost:1355` → サービスB)を使っている場合、**`vmbrowse` の Chrome でそのまま
`http://a.localhost:1355` を開けば使える**。ポートごとに `vmfwd` を張る必要は無い。

- `vmbrowse` は loopback もプロキシ経由にしているので、`*.localhost` へのアクセスも SOCKS 経由で
  VM に届く。名前解決も VM 側で行われ(`a.localhost` → VM の loopback。systemd-resolved が解決)、
  `Host: a.localhost:1355` ヘッダが保持されるので portless が subdomain を見て振り分ける。
- 実質「vmbrowse のウィンドウ = VM 上のブラウザ」。VM でローカルに開いたのと同じ挙動。
- SOCKS を1本(`vmproxy`)張れば、`a.localhost` / `b.localhost` / … と変えるだけで全サービスに到達。
- 注意: VM では `*.localhost` が `::1`(IPv6 loopback)に解決される。portless が IPv4 `127.0.0.1`
  だけで listen していると届かない場合がある(VM ローカルで開けているなら vmbrowse でも開ける)。
  ダメなら portless を `::` / 両 family で listen させる。

---

## 5. 反映

- **ssh config**(`~/.ssh/config`)… ssh が直読みするので即時反映。
- **zsh 関数**(`zsh.nix`)… home レイヤーなので `nix-switch` 後に有効化。

```console
nix-switch   # = nix run home-manager/master -- switch --flake "path:$PWD#nosuke@nosuke-M5-MBP"
```

---

## 6. トラブルシュート

### `channel N: open failed: connect failed: Connection refused` が定期的に出る

- 原因: 静的な `LocalForward 8090 localhost:8090` が `Host vm` にあり、**VM 側の 8090 で何も
  listen していない**(サーバ未起動)のに、ローカルの何か(開きっぱなしのブラウザタブ等)が
  `localhost:8090` を叩き続けている。herdr の SSH もこの config を継承するので herdr 画面に出る。
- 対処: 静的 `LocalForward` をやめ、**必要な時だけ `vmfwd`/`vmproxy` で張る**方式に移行(本メモの構成)。
  古い herdr セッションが動いている場合は貼り直すと消える。

---

## 7. Windows での手順

| 要素 | Mac | Windows ネイティブ | WSL |
|---|---|---|---|
| `ssh -D`(SOCKS) | ✅ | ✅ | ✅ |
| ブラウザ SOCKS + loopback 解除 | ✅ | ✅(Chrome/Edge 同フラグ) | ✅ |
| ControlMaster / `ssh -O forward` | ✅ | ❌ 未対応 | ✅ |

Windows ネイティブの OpenSSH は**接続多重化(ControlMaster)を実装していない**
([Win32-OpenSSH #1328](https://github.com/PowerShell/Win32-OpenSSH/issues/1328))。
そのため `vmfwd`/`vmproxy` の「稼働中マスターに動的追加」は使えず、**SOCKS 用 ssh を常駐起動**する
方式に置き換える。完全に Mac と同じ体験が欲しい場合は WSL を使う(下記 7-B)。

### 7-A. ネイティブ PowerShell の手順

#### 1) SSH config を置く

`%USERPROFILE%\.ssh\config`(= `C:\Users\<name>\.ssh\config`)に記述。
**ControlMaster 系の3行は入れない**(機能しないため)。

```sshconfig
Host vm
  HostName 172.207.57.61
  User azureuser
  Port 22
  # 1Password を使う場合(Windows は名前付きパイプ):
  # IdentityAgent \\.\pipe\openssh-ssh-agent
```

`ssh vm` で接続できることを先に確認しておく。

#### 2) PowerShell プロファイルに関数を追加

```console
notepad $PROFILE      # 無ければ New-Item -ItemType File -Path $PROFILE -Force で作成
```

以下を貼り付けて保存 → `. $PROFILE` で再読み込み。

```powershell
function vmproxy {
    param([int]$Port = 1080)
    # ControlMaster が無いので SOCKS 用 ssh を常駐起動(-O forward は使えない)
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

> 単一ポートだけ転送したいなら(`vmfwd` 相当)、ControlMaster が無いので同様に常駐 ssh を使う:
> `Start-Process ssh -ArgumentList "-N","-L","8090:localhost:8090","vm" -WindowStyle Hidden`

#### 3) 使い方

```powershell
ssh vm            # 認証を通しておく(1Password の承認が出ることがある)
vmproxy           # SOCKS を localhost:1080 に常駐起動
vmbrowse          # SOCKS 経由の隔離 Chrome で http://localhost:8090 を開く
vmbrowse http://localhost:3000
vmunproxy         # 常駐 ssh を停止
```

- `-N` はコマンド無し(転送専用)、`-f`(バックグラウンド化)は Windows で不安定なので
  `Start-Process ... -WindowStyle Hidden` で裏に回す。
- Edge を使うなら `$chrome` を `"${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe"`
  に変えるだけ(フラグは同じ)。
- 検証: `curl.exe --socks5-hostname 127.0.0.1:1080 https://api.ipify.org` が **VM の IP** を返せばOK。

### 7-B. WSL の手順(Mac と同一)

WSL(Ubuntu 等)内は本物の Linux OpenSSH なので、**Mac と全く同じ ControlMaster ベースの仕組みが
そのまま動く**。このリポジトリには WSL 用の home 構成があるので、そこに乗せるのが素直。

1. WSL 内で home-manager を適用(`nosuke@nosuke-windows` 構成):

   ```console
   nix run home-manager/master -- switch -b backup --flake "path:$PWD#nosuke@nosuke-windows"
   ```

   → `zsh.nix` の `vmfwd`/`vmproxy`/`vmbrowse` が WSL 側にも配られる。

2. WSL 内の `~/.ssh/config` に §2 と同じ `Host vm`(ControlMaster 込み)を置く。以降 `vmproxy`
   等が Mac と同じに使える。

3. **`vmbrowse` だけ要調整**: macOS の `open -na "Google Chrome"` は WSL では動かない。
   Windows 側の Chrome を起動するよう分岐が必要:

   ```zsh
   # WSL から Windows の Chrome を SOCKS 経由で開く例
   "/mnt/c/Program Files/Google/Chrome/Application/chrome.exe" \
     --user-data-dir="C:\\Users\\<name>\\AppData\\Local\\chrome-vm-proxy" \
     --proxy-server="socks5://127.0.0.1:1080" \
     --proxy-bypass-list="<-loopback>" \
     "http://localhost:8090"
   ```

   > SOCKS を張る ssh は WSL 内で動く(`127.0.0.1:1080` は WSL の loopback)。Windows 側 Chrome から
   > その 1080 へ届くかは WSL のネットワークモード次第(WSL2 のミラーモードなら `127.0.0.1` 共有可)。
   > 確実に動かすなら、SOCKS を張る ssh も Windows 側(7-A)で動かし、ブラウザも Windows 側に統一する。

> zsh.nix の `vmbrowse` を全ホスト共通で使いたいなら、`$OSTYPE` や `/proc/version` の "microsoft"
> 判定で Chrome 起動コマンドを OS 別に切り替える形に一般化できる(未実装)。
