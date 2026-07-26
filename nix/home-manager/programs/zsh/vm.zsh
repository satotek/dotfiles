# vm への動的ポートフォワード (VS Code 風)。~/.ssh/config の ControlMaster 接続へ
# 静的な LocalForward を書かずに都度足す/外す。`vmfwd 8090` → localhost:8090。
vmfwd() {
  local l="$1" r="${2:-$1}"
  [[ -z "$l" ]] && {
    echo "usage: vmfwd <local-port> [remote-port]"
    return 1
  }
  ssh -O forward -L "$l:localhost:$r" vm && echo "up   localhost:$l -> vm:$r"
}

vmunfwd() {
  local l="$1" r="${2:-$1}"
  [[ -z "$l" ]] && {
    echo "usage: vmunfwd <local-port> [remote-port]"
    return 1
  }
  ssh -O cancel -L "$l:localhost:$r" vm && echo "down localhost:$l"
}

vmfwls() {
  ssh -O check vm
}

# SOCKS プロキシ (VS Code 風: ポートごとの -L 転送なしに VM の任意ポートへ到達)。
# ブラウザを socks5://127.0.0.1:<port> に向けると localhost が VM 側で解決される。
vmproxy() {
  local p="${1:-1080}"
  ssh -O forward -D "$p" vm && echo "SOCKS up:   socks5://127.0.0.1:$p (via vm)"
}

vmunproxy() {
  local p="${1:-1080}"
  ssh -O cancel -D "$p" vm && echo "SOCKS down: :$p"
}

# SOCKS 経由の隔離 Chrome を開く。loopback バイパスを解除して localhost も VM 側へ回す。
# 例: vmproxy && vmbrowse            (http://localhost:8090 を開く)
#     vmbrowse http://localhost:3000
vmbrowse() {
  local port="${VM_SOCKS_PORT:-1080}"
  open -na "Google Chrome" --args \
    --user-data-dir="${XDG_CACHE_HOME:-$HOME/.cache}/chrome-vm-proxy" \
    --proxy-server="socks5://127.0.0.1:$port" \
    --proxy-bypass-list="<-loopback>" \
    "${1:-http://localhost:8090}"
}
