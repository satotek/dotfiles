{ pkgs, ... }:
let
  # gem-ai から tailnet 上の他マシンへ TCP を出すため、kernel TUN で動かす。
  # Home Manager は root のサービスを置けないので、ユーザーユニットから sudo -n で
  # tailscaled を起動する。statedir とソケットはユーザー側のままにし、下の CLI
  # ラッパーが同じソケットを使えるようにする。
  socket = "\${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/tailscale/tailscaled.sock";

  # CLI の既定のソケットは /var/run なので、ユーザーサービスのソケットを渡すラッパーを
  # tailscale として置く。`tailscale serve` などもこれを PATH から呼ぶ。
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
      Description = "Tailscale node agent (kernel TUN)";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };

    Service = {
      Type = "simple";
      # %S は ~/.local/state、%t は $XDG_RUNTIME_DIR。どちらも systemd が作って権限を揃える。
      StateDirectory = "tailscale";
      RuntimeDirectory = "tailscale";
      ExecStart = "/usr/bin/sudo -n ${pkgs.tailscale}/bin/tailscaled --tun=tailscale0 --statedir=%S/tailscale --socket=%t/tailscale/tailscaled.sock";
      Restart = "on-failure";
      RestartSec = 5;
    };

    Install.WantedBy = [ "default.target" ];
  };
}
