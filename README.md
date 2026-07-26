# dotfiles

macOSとLinuxの開発環境を、Nix Flakes・nix-darwin・Home Managerで管理する個人用dotfilesです。

- macOSは「nix-darwinのsystem layer」と「standalone Home Managerのhome layer」を分離
- LinuxとWSLはstandalone Home Managerで管理
- CLI、shell、editor、AI agent環境をNixで再現
- NeovimやWezTermなど頻繁に編集する設定は、リポジトリへのout-of-store symlinkで管理
- machine固有設定と平文secretはリポジトリ外に保持

## Architecture

```text
                            flake.nix
                                │
                 ┌──────────────┴──────────────┐
                 │                             │
        darwinConfigurations             homeConfigurations
           (macOS only)                   (macOS / Linux)
                 │                             │
        nix/nix-darwin/                 nix/home-manager/
                 │                             │
     Homebrew casks / fonts /         shell / editor / CLI /
     macOS defaults / Touch ID        agents / repo-backed config
                 │                             │
          darwin-switch                    nix-switch
           sudo required                  no sudo
```

Determinate NixがNix daemonとstore GCを担当します。nix-darwinでは
`nix.enable = false`とし、同じNix installationを二重管理しません。

### macOS system layer

nix-darwinが次を管理します。

- Homebrew casks: 1Password、1Password CLI、Karabiner-Elements、WezTerm Nightly
- fonts: HackGen NF、Moralerspace
- Dock、Finder、keyboard、trackpad、screenshotなどのmacOS defaults
- sudoのTouch ID認証
- login shellとしてのZsh
- 古いnix-darwin system generationsの定期整理

### Home Manager layer

macOSとLinuxで共有するhome layerです。

- XDG Base Directory
- Zsh、Sheldon、Starship、Zeno、zoxide、direnv
- Git、delta、lazygit、tmux
- Neovim、Ghostty、WezTerm、Karabiner設定
- development toolchainsとlanguage servers
- Claude Code、Codex、Antigravity CLI、Grok、Herdr、Hunk
- agent skills、MCP server設定、Herdr agent integrations
- sops + GCP Cloud KMSによるsecret復号

## Supported configurations

| Flake output | Platform | User / host |
|---|---|---|
| `darwinConfigurations.nosuke-M5-MBP` | `aarch64-darwin` | macOS system layer |
| `homeConfigurations."nosuke@nosuke-M5-MBP"` | `aarch64-darwin` | macOS home layer |
| `homeConfigurations."nosuke@linux-x86_64"` | `x86_64-linux` | generic Linux |
| `homeConfigurations."nosuke@linux-aarch64"` | `aarch64-linux` | generic Linux |
| `homeConfigurations."nosuke@nosuke-windows"` | `x86_64-linux` | WSL |
| `homeConfigurations."stko23@stko23-windows"` | `x86_64-linux` | WSL |
| `homeConfigurations."azureuser@linux-x86_64"` | `x86_64-linux` | Azure / generic Linux |
| `homeConfigurations."azureuser@linux-aarch64"` | `aarch64-linux` | Azure / generic Linux |
| `homeConfigurations."azureuser@gem-ai"` | `x86_64-linux` | `gem-ai` |

すべてのoutputは次で確認できます。

```bash
nix flake show
```

この構成はリポジトリを`~/dotfiles`へcloneする前提です。別のuser、host、
clone先を使う場合は、`flake.nix`、host definition、またはHome Manager
module内の`dotfilesDir`を調整してください。

## Install Nix

[Determinate Nix](https://docs.determinate.systems/)を使用します。
`llm-agents.nix`のbinary cacheをtrusted substituterとして登録し、Codexなどの
大きなRust packageを毎回source buildしないようにします。

```bash
curl -fsSL https://install.determinate.systems/nix | sh -s -- install \
  --extra-conf "trusted-users = root $(id -un)" \
  --extra-conf "extra-substituters = https://cache.numtide.com" \
  --extra-conf "extra-trusted-substituters = https://cache.numtide.com" \
  --extra-conf "extra-trusted-public-keys = niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
```

インストール後にshellを開き直し、確認します。

```bash
nix --version
nix config show | grep experimental-features
nix config show | grep cache.numtide.com
```

Determinate Nixは通常`nix-command`と`flakes`を有効化します。fresh install直後に無効と表示される場合だけ、fallbackとして次を設定します。

```bash
mkdir -p ~/.config/nix
grep -qxF 'experimental-features = nix-command flakes' \
  ~/.config/nix/nix.conf 2>/dev/null \
  || printf '%s\n' 'experimental-features = nix-command flakes' >> ~/.config/nix/nix.conf
```

初回のHome Manager適用後は、リポジトリ内の`.config/nix/nix.conf`が管理対象になります。

## First setup

### macOS

```bash
git clone https://github.com/satotek/dotfiles.git ~/dotfiles
cd ~/dotfiles

# System layer
sudo nix run nix-darwin/master#darwin-rebuild -- \
  switch --flake "path:$PWD#nosuke-M5-MBP"

# Home layer
nix run home-manager/master -- \
  switch --flake "path:$PWD#nosuke@nosuke-M5-MBP"
```

system layerにはsudoが必要ですが、home layerには不要です。

### Linux / WSL

```bash
git clone https://github.com/satotek/dotfiles.git ~/dotfiles
cd ~/dotfiles

nix run home-manager/master -- \
  switch -b backup --flake "path:$PWD#<home-configuration>"
```

例:

```bash
nix run home-manager/master -- \
  switch -b backup --flake "path:$PWD#azureuser@gem-ai"
```

`-b backup`は、初回適用時に既存ファイルとHome Manager linkが衝突した場合の退避用です。

## Daily workflow

初回適用後は次のwrapperがインストールされます。

```bash
nix-switch
```

現在のuserとhostに対応するstandalone Home Manager configurationを適用します。macOSでもLinuxでもsudoは不要です。

macOSのsystem layerを変更した場合だけ次を実行します。

```bash
darwin-switch
```

使い分け:

| 変更 | Command |
|---|---|
| shell、CLI、Neovim、Ghostty、agents、Lazygit | `nix-switch` |
| Homebrew cask、font、macOS defaults、system Zsh | `darwin-switch` |
| 両方 | `darwin-switch`の後に`nix-switch` |

flakeはGit管理対象だけをsourceとして扱います。新しいNix moduleや`.zsh`
snippetを追加した場合は、switchまたは通常のflake評価より先に`git add`
してください。未追跡ファイルを含めて一時的に評価するときは
`path:$PWD#...`を使用できます。

## Configuration ownership

### Home Manager native settings

可能なものはHome Manager optionから生成します。

- Git
- Zsh historyとaliases
- Sheldon plugins
- Starship
- direnv / nix-direnv
- zoxide
- tmux
- Ghostty
- Lazygit

Lazygitの`config.yml`は`programs.lazygit.settings`から生成され、activation時に
upstream schemaで検証されます。pagerのdeltaはNix storeの絶対パスで参照します。

### Repo-backed settings

頻繁に直接編集したい設定は、Home Managerがリポジトリへout-of-store symlinkを作ります。

- `.config/nvim`
- `.config/nvchad`
- `.config/wezterm`
- `.config/zeno`
- `.config/hunk/config.toml`
- `.config/karabiner/karabiner.json`
- `.config/nix/nix.conf`
- `nix/home-manager/home/profile.sh`

これらは編集直後にアプリケーションから読めるものと、再起動・reload・`nix-switch`が必要なものがあります。各moduleの管理方法を確認してください。

### Local-only files

次はGit管理しません。

- `~/.config/git.local`
- `~/.config/zsh.local`
- `~/.config/secrets`
- `~/.ssh/azure-devops`
- `~/.ssh/azure-devops.pub`
- `$XDG_CACHE_HOME/zsh/`

Git identity:

```bash
cp ~/dotfiles/.config/git.local.example ~/.config/git.local
```

任意のZsh override:

```bash
cp ~/dotfiles/.config/zsh.local.example ~/.config/zsh.local
```

## Secrets

repositoryで管理するsecretは`secrets/*.yaml`をsopsで暗号化し、GCP Cloud KMSで復号します。

```text
projects/nosuke-net/locations/global/keyRings/sops/cryptoKeys/dotfiles
```

各hostで一度、Application Default Credentialsを設定します。

```bash
gcloud config set project nosuke-net
gcloud auth application-default login
gcloud auth application-default set-quota-project nosuke-net
```

現在の出力先:

| Encrypted source | Decrypted target | Scope |
|---|---|---|
| `secrets/cloudflare.yaml` | `~/.config/cloudflare/cloudflare-infra.env` | macOS only |
| `secrets/context7.yaml` | `~/.config/context7/api-key` | agents presetを使うhost |

既存ファイルへKMS recipientを追加した場合は、復号可能なmachineでrewrapします。

```bash
sops updatekeys secrets/*.yaml
```

repo管理外のshell secretは`~/.config/secrets`へ置けます。

## Shell

Zsh pluginはSheldon、promptはStarship、snippetとhistory UIはZenoが担当します。

Zshコードは役割ごとに分割し、Nix評価時に最終`.zshrc`へ埋め込みます。runtimeで分割ファイルを追加sourceしないため、ファイル分割による起動時I/Oは増えません。

```text
nix/home-manager/programs/
├── zsh.nix
└── zsh/
    ├── early.zsh
    ├── widgets.zsh
    ├── vm.zsh
    └── init.zsh
```

Sheldon、Starship、zoxideの生成結果は`$XDG_CACHE_HOME/zsh`へatomicに保存し、
Zsh bytecodeへcompileします。Nix storeのmtimeに依存せず、package実体や
設定変更からcacheを更新します。

主なkeybinding:

| Key | Action |
|---|---|
| `Ctrl-B` | Git branchをfzfで選択 |
| `Ctrl-G` | ghq / rootsのprojectへ移動 |
| `Ctrl-R` | Zeno history検索 |
| `Ctrl-X` → `Ctrl-K` | processをfzfで選択して終了 |
| `Tab` | Zeno completion |

詳細は[Zsh keybindings](docs/zsh-keybindings.md)を参照してください。

## Agents and Herdr

agent packageは主に`llm-agents.nix` overlayから導入します。設定はHome Managerで
生成し、共通MCP definitionsは`nix/home-manager/data/mcp-servers.nix`に置きます。

- Claude Code
- Codex
- Antigravity CLI
- Grok
- Herdr
- Hunk
- agent-browser
- curated agent skills

Herdr本体はNix packageとして管理しています。Home Manager activationは
Claude CodeとCodexのHerdr integrationを生成し、session restoreに必要なhookを
設定します。

Herdrのremote workflowとSSH forwardingは[VM remote workflow](docs/vm-remote-workflow.md)を参照してください。

## Tool presets

Home Manager packageは用途別presetに分けています。

| Preset | Purpose |
|---|---|
| `base` | shell、editor、Git、常用CLI |
| `agents` | AI agents、skills、MCP、Herdr、sops |
| `cloud` | Azure CLI、Google Cloud SDK、SOPS、Terraform/OpenTofu tooling |
| `devtools` | Go、shell/Lua/Markdown tooling、Mermaid、ffmpeg |
| `rust` | rustc、cargo、clippy、rustfmt、rust-analyzer |
| `webdevtools` | Node.js、Bun、pnpm、Python、NixとWeb系language servers |

hostごとのpreset組み合わせは`flake.nix`と`nix/hosts/`で定義します。

## Validation and maintenance

よく使う検証:

```bash
# Nix format
nix fmt

# Current platformのchecks
nix flake check

# 特定Home Manager outputをbuild
nix build --no-link \
  '.#homeConfigurations."nosuke@linux-x86_64".activationPackage'

# Zsh snippetの構文
for file in nix/home-manager/programs/zsh/*.zsh; do
  zsh -n "$file"
done
```

詳細なmaintenance commandは[Maintenance Commands](docs/maintenance.md)を参照してください。

### Startup benchmark

`dotbench`はinteractive Zshとheadless Neovimを1回warm-upした後、デフォルト10回測定し、min・median・mean・maxを表示します。

```bash
dotbench
dotbench 30
```

環境間または変更前後の比較には、background activityの影響を受けにくいmedianを使います。macOSでは一部Zsh初期化を`zsh-defer`へ渡しているため、`dotbench`のZsh値はprompt表示までの同期処理を中心に測ります。

### Generation cleanup

macOSでは毎週日曜に次を整理します。

- 12:00: Home Manager generationsを最低5世代、直近30日分残して整理
- 12:15: nix-darwin system generationsを最低5世代、直近30日分残して整理

store GCはDeterminate Nixdへ任せ、`nh clean profile`には`--no-gc --no-gcroots`を指定しています。

## Automation

GitHub Actionsがflake inputsを更新し、Linux Home Manager configurationのbuildに成功した場合だけPRを作成してauto-mergeします。

| Workflow | Schedule | Inputs |
|---|---|---|
| `update-flake-ai.yml` | daily | `llm-agents`、agent browser、agent skills |
| `update-flake-stable.yml` | every 3 days | `nixpkgs`、`nix-darwin`、`home-manager` |

両workflowとも`cache.numtide.com`を利用し、
`homeConfigurations."nosuke@linux-x86_64".activationPackage`を検証します。
更新はrepositoryへmergeされるだけなので、各machineでは`git pull`後に必要な
switchを実行します。

## Repository layout

```text
dotfiles/
├── flake.nix
├── flake.lock
├── nix/
│   ├── hosts/
│   │   ├── darwin/
│   │   └── linux/
│   ├── nix-darwin/
│   │   ├── system.nix
│   │   ├── homebrew.nix
│   │   ├── macos-defaults.nix
│   │   └── nix-cleanup.nix
│   └── home-manager/
│       ├── home/
│       ├── platforms/
│       ├── presets/
│       ├── programs/
│       └── data/
├── .config/
│   ├── nvim/
│   ├── nvchad/
│   ├── wezterm/
│   └── zeno/
├── docs/
├── secrets/
├── tools/
│   └── dotbench/
└── .github/
    └── workflows/
```

## Related documentation

- [Maintenance Commands](docs/maintenance.md)
- [Zsh keybindings](docs/zsh-keybindings.md)
- [Neovim cheatsheet](docs/nvim-cheatsheet.md)
- [VM remote workflow](docs/vm-remote-workflow.md)

## Insight

<!-- rumdl-disable MD013 MD033 -->

### Activity

<a href="https://next.ossinsight.io/widgets/official/compose-last-28-days-stats?repo_id=1105658656" target="_blank" align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://next.ossinsight.io/widgets/official/compose-last-28-days-stats/thumbnail.png?repo_id=1105658656&image_size=auto&color_scheme=dark" width="655" height="auto">
    <img alt="Performance Stats of satotek/dotfiles - Last 28 days" src="https://next.ossinsight.io/widgets/official/compose-last-28-days-stats/thumbnail.png?repo_id=1105658656&image_size=auto&color_scheme=light" width="655" height="auto">
  </picture>
</a>

### Changes

<a href="https://next.ossinsight.io/widgets/official/analyze-repo-loc-per-month?repo_id=1105658656" target="_blank" align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://next.ossinsight.io/widgets/official/analyze-repo-loc-per-month/thumbnail.png?repo_id=1105658656&image_size=auto&color_scheme=dark" width="721" height="auto">
    <img alt="Lines of Code Changes of satotek/dotfiles" src="https://next.ossinsight.io/widgets/official/analyze-repo-loc-per-month/thumbnail.png?repo_id=1105658656&image_size=auto&color_scheme=light" width="721" height="auto">
  </picture>
</a>

<!-- Made with [OSS Insight](https://ossinsight.io/) -->

<!-- rumdl-enable MD013 MD033 -->
