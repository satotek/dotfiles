{ pkgs, ... }:
let
  # Home Manager は root のデーモンを置けないので、tailscaled を userspace networking で
  # ユーザーサービスとして動かす。TUN を作らない代わりに、tailnet から来た接続は
  # このマシンの localhost へ届くので、127.0.0.1 で待ち受けるサーバーもそのまま使える。
  # 逆にこのマシンから tailnet へ出る通信は SOCKS5 などのプロキシが要るが、今は使わない。
  socket = "\${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/tailscale/tailscaled.sock";

  # CLI の既定のソケットは /var/run なので、ユーザーサービスのソケットを渡すラッパーを
  # tailscale として置く。t3 serve --tailscale-serve などもこれを PATH から呼ぶ。
  tailscaleCli = pkgs.writeShellScriptBin "tailscale" ''
    exec ${pkgs.tailscale}/bin/tailscale --socket="${socket}" "$@"
  '';
in
{
  home.packages = [ tailscaleCli ];

  # 初回だけ `tailscale up` でブラウザから承認する。ノードの鍵は statedir に残るので、
  # 以後は起動するだけでつながる。
  systemd.user.services.tailscaled = {
    Unit = {
      Description = "Tailscale node agent (userspace networking)";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };

    Service = {
      Type = "simple";
      # %S は ~/.local/state、%t は $XDG_RUNTIME_DIR。どちらも systemd が作って権限を揃える。
      StateDirectory = "tailscale";
      RuntimeDirectory = "tailscale";
      ExecStart = "${pkgs.tailscale}/bin/tailscaled --tun=userspace-networking --statedir=%S/tailscale --socket=%t/tailscale/tailscaled.sock";
      Restart = "on-failure";
      RestartSec = 5;
    };

    Install.WantedBy = [ "default.target" ];
  };
}
