# 仕事用 PC のプロファイル。chezmoi init で work を選んだ PC にだけ配られ、
# Microsoft.PowerShell_profile.ps1 から読み込まれる。
# 共通設定の後に読むので、ここでエイリアスなども上書きできる。

# Cygwin のコマンドを、Windows 側のコマンドより後ろに足す。
if (Test-Path 'C:\cygwin64\bin') {
    $paths = $env:PATH -split ';'
    if ('C:\cygwin64\bin' -notin $paths) {
        $env:PATH = ($paths + 'C:\cygwin64\bin') -join ';'
    }
}

$msbuild = 'C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\MSBuild\Current\Bin'
if ((Test-Path $msbuild) -and ($env:PATH -notlike "*$msbuild*")) {
    $env:PATH += ";$msbuild"
}

# 証明書の失効確認に失敗する環境向けの回避策。curl だけ失効確認を省く。不要な PC では消す。
function curl {
    curl.exe --ssl-no-revoke @args
}

# --- VM リモート作業 (docs/vm-remote-workflow.md §7-A) ---
# Windows ネイティブの OpenSSH は ControlMaster 非対応のため、SOCKS 用 ssh を常駐起動する。
function vmproxy {
    param([int]$Port = 1080)
    $running = Get-CimInstance Win32_Process -Filter "Name='ssh.exe'" |
    Where-Object {
        $_.CommandLine -match "-D\s*${Port}\b"
    }
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
