# このファイルの内容が変わったときだけ、設定ファイルを配る前に実行される。
# パッケージを足すときはこの一覧を編集する。未導入のものだけ入れるので、再実行しても安全。
# 一覧から消してもアンインストールはしない。

$packages = @(
    'Microsoft.PowerShell'
    'Git.Git'
    'dandavison.delta'
    'JesseDuffield.lazygit'
    'Starship.Starship'
    'Neovim.Neovim'
    'ajeetdsouza.zoxide'
    # PSFzf が使う。
    'junegunn.fzf'
    # nvim の snacks picker が使う。
    'BurntSushi.ripgrep.MSVC'
    'sharkdp.fd'
)

# プロファイルが読み込む PowerShell モジュール。
$modules = @(
    'PSFzf'
    'CompletionPredictor'
)

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Warning 'winget が見つからないため、パッケージの導入をスキップした。'
    exit 0
}

$failed = @()
foreach ($id in $packages) {
    winget list --exact --id $id --accept-source-agreements *> $null
    if ($LASTEXITCODE -eq 0) {
        continue
    }
    Write-Host "Installing $id"
    winget install --exact --id $id --silent --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -ne 0) {
        $failed += $id
    }
}

# herdr-app は winget に無いので公式インストーラで入れる。入れた後はアプリ自身が
# 本体と herdr-core を更新するので、未導入のときだけ実行する。
$herdrApp = Join-Path $env:LOCALAPPDATA 'Programs\herdr-app\herdr-app.exe'
if (-not (Test-Path $herdrApp)) {
    Write-Host 'Installing herdr-app'
    try {
        # インストーラは失敗を exit ではなく throw で返すので、ここで受け止められる。
        Invoke-RestMethod 'https://releases.herdr.dev/app/install.ps1' | Invoke-Expression
    } catch {
        Write-Warning "herdr-app: $_"
        $failed += 'herdr-app'
    }
}

# この処理が Windows PowerShell 5.1 で動いていても、モジュールは PowerShell 7 に入れる。
# 導入直後は PATH に載っていないので、標準の場所も探す。
$pwsh = (Get-Command pwsh -ErrorAction SilentlyContinue).Source
if (-not $pwsh) {
    $default = Join-Path $env:ProgramFiles 'PowerShell\7\pwsh.exe'
    if (Test-Path $default) { $pwsh = $default }
}

if ($pwsh) {
    foreach ($name in $modules) {
        & $pwsh -NoProfile -Command "if (-not (Get-InstalledPSResource -Name $name -ErrorAction SilentlyContinue)) { Install-PSResource -Name $name -TrustRepository -Quiet }"
        if ($LASTEXITCODE -ne 0) {
            $failed += "module:$name"
        }
    }
} else {
    Write-Warning 'pwsh が見つからないため、PowerShell モジュールの導入をスキップした。'
}

# 1 つの失敗で設定の配置まで止めず、最後にまとめて知らせる。
if ($failed.Count -gt 0) {
    Write-Warning "導入に失敗したもの: $($failed -join ', ')"
}
