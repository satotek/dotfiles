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
# ControlMaster が無ければバックグラウンドで起動してから動的転送を追加する。
# ブラウザを socks5://127.0.0.1:<port> に向けると localhost が VM 側で解決される。
vmproxy() {
  local p="${1:-1080}"
  local ssh_config control_master control_path

  ssh_config="$(ssh -G vm 2>/dev/null)" || {
    echo "vmproxy: unable to resolve SSH config for vm" >&2
    return 1
  }
  control_master="$(print -r -- "$ssh_config" | awk '$1 == "controlmaster" { print $2; exit }')"
  control_path="$(print -r -- "$ssh_config" | awk '$1 == "controlpath" { print $2; exit }')"
  if [[ -z "$control_master" || "$control_master" == "false" || -z "$control_path" || "$control_path" == "none" ]]; then
    echo "vmproxy: Host vm needs ControlMaster and ControlPath in ~/.ssh/config" >&2
    return 1
  fi

  if ! ssh -O check vm >/dev/null 2>&1; then
    echo "vmproxy: starting SSH master for vm"
    if ! ssh -fN vm; then
      echo "vmproxy: failed to start SSH master for vm" >&2
      return 1
    fi
    if ! ssh -O check vm >/dev/null 2>&1; then
      echo "vmproxy: SSH master for vm did not become available" >&2
      return 1
    fi
  fi

  ssh -O forward -D "127.0.0.1:$p" vm && echo "SOCKS up:   socks5://127.0.0.1:$p (via vm)"
}

vmunproxy() {
  local p="${1:-1080}"
  ssh -O cancel -D "$p" vm && echo "SOCKS down: :$p"
}

# SOCKS 経由の隔離 Chrome を起動する。
vmbrowse() {
  local port="${VM_SOCKS_PORT:-1080}"
  open -na "Google Chrome" --args \
    --user-data-dir="${XDG_CACHE_HOME:-$HOME/.cache}/chrome-vm-proxy" \
    --proxy-server="socks5://127.0.0.1:$port" \
    --proxy-bypass-list="<-loopback>"
}
