# Windows のセットアップ

Windows ではNixが使えないため、[chezmoi](https://www.chezmoi.io/)で設定ファイルだけを配る。
macOS・Linux・WSLはこれまで通りNixが管理し、chezmoiは使わない。

リポジトリ直下の`.chezmoiroot`が`windows/`を指しているので、chezmoiは
`windows/`の中だけを管理対象にする。Windows以外で`chezmoi apply`を実行しても、
`windows/.chezmoiignore`が何も配らないようにしている。

## 管理するもの

| 配置先 | ソース |
|---|---|
| `~\.config\git\config` | `windows/dot_config/git/config` |
| `~\.config\git.local` | 初回だけ雛形を作る。名前・メール・プロキシを書く |
| `~\.config\starship.toml` | `windows/dot_config/starship.toml` |
| `%LOCALAPPDATA%\lazygit\config.yml` | `windows/AppData/Local/lazygit/config.yml` |
| `%LOCALAPPDATA%\nvim` | このリポジトリの`.config/nvim`へのシンボリックリンク |
| `~\Documents\PowerShell\Microsoft.PowerShell_profile.ps1` | PowerShell 7の既定プロファイル |
| `~\Documents\PowerShell\profile.work.ps1` | 仕事用PCにだけ配る。cygwin・MSBuildのPATH、`curl`のラッパー、`vmproxy`系の関数 |

## 初回セットアップ

1. Windowsの設定で開発者モードを有効にする。nvimのシンボリックリンクに必要。
2. chezmoiを入れる。

   ```powershell
   winget install --exact --id twpayne.chezmoi
   ```

3. リポジトリを取得して適用する。

   ```powershell
   chezmoi init --apply <このリポジトリのURL>
   ```

   途中で「この PC のプロファイル」を`personal`か`work`で聞かれる（既定は`personal`）。
   答えは`~\.config\chezmoi\chezmoi.toml`に保存され、以後は聞かれない。

   `windows/run_onchange_before_install-packages.ps1`が、設定を配る前にgit・delta・lazygit・
   starship・nvimなどをwingetで入れる。導入したコマンドをPATHに載せるため、
   完了後にターミナルを開き直す。
4. `~\.config\git.local`に名前とメールを書く。以後chezmoiは上書きしない。

lazygitは0.64以降が必要。それより古いと`git.diffRenderers`が無視され、deltaが効かない。
プロンプトのアイコンにはNerd Fontが必要で、wingetでは入れていない。
使うフォントを別途インストールし、ターミナルの設定で指定する。

## PCごとの違い

### プロファイル（personal / work）

`chezmoi init`で選んだプロファイルによって、配るファイルが変わる。

| プロファイル | 配るもの |
|---|---|
| `personal`（既定） | 共通の設定だけ |
| `work` | 共通の設定に加えて、`profile.work.ps1` |

`profile.work.ps1`は共通のプロファイルの後に読まれるので、エイリアスなども上書きできる。
中身は共有のファイルなので、変更すると`work`のPC全部に`chezmoi apply`で届く。
プロファイルを変えたいときは`chezmoi init`をやり直す。`work`から`personal`に変えても、
配布済みの`profile.work.ps1`は消えないので、手で削除する。

### 1台だけの設定

名前・メール・プロキシなど、1台ごとに違う値は`~\.config\git.local`に書く。
chezmoiは無ければ雛形を作るだけで、以後は上書きしない。

### 既存のプロファイルがあるPC

`$PROFILE`が既にあるPCでは、先にバックアップを取り、`chezmoi diff`で差分を確認してから
`chezmoi apply`する。chezmoiは初回、既存のファイルを確認なしで上書きする。

プロファイルの末尾にあるIntelligent Terminalのブロックは、ツールが管理する自動生成部分。
マーカーごとそのままソースに含めてあり、編集しない。

## パッケージを足す

`windows/run_onchange_before_install-packages.ps1`の一覧を編集して`chezmoi apply`する。
ファイルの内容が変わったときだけ実行され、導入済みのものはスキップする。
一覧から消してもアンインストールはしないので、不要になったものは手で消す。

## 日常の操作

```powershell
chezmoi diff     # 適用前に差分を確認する
chezmoi apply    # 設定を反映する
chezmoi update   # git pullしてから反映する
```

## Nix側の設定との同期

`starship.toml`はNixが生成したものをコピーしている。Nix側を変えたら、Linuxで次を実行して
取り込む。`python_binary`はWindowsに`python3`がないため削除している。

```sh
G=$(nix build --no-link --print-out-paths '.#checks.x86_64-linux.home-azureuser-linux-x86_64')
cp -L "$G/home-files/.config/starship.toml" windows/dot_config/starship.toml
chmod u+w windows/dot_config/starship.toml
sed -i '/^python_binary/d' windows/dot_config/starship.toml
```

gitとlazygitの設定は手で対応させている。lazygitのコミット種別は
`nix/home-manager/programs/lazygit/default.nix`の`commitTypes`と揃えること。

## 注意

- `Documents`をOneDriveに移している環境では、プロファイルの配置先がずれる。
  `$PROFILE`で実際のパスを確認し、必要なら`windows/`の配置を合わせる。
- Windows PowerShell 5.1は`Documents\WindowsPowerShell`を使う。ここではPowerShell 7だけを管理している。
