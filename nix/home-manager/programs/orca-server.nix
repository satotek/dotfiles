{
  config,
  pkgs,
  ...
}:
let
  orcaServer = pkgs.callPackage ../../packages/orca-server.nix { };

  # tailnet 上の gem-ai のアドレス。Tailscale の IP はノードを登録し直さない限り
  # 変わらない。ホスト名にすると Orca が公開アドレスからの接続も許してしまうので IP で書く。
  tailnetAddress = "100.98.143.23";
in
{
  # `orca-ide pair --address <IP>` で、動いているサーバーから接続用リンクを発行する。
  home.packages = [ orcaServer ];

  # Mac の Orca から Remote Orca Server として接続する常駐サーバー。
  # tailnet の IP だけで待ち受け、Azure の公開 NIC には出さない。
  systemd.user.services.orca-server = {
    Unit = {
      Description = "Orca headless runtime server";
      # 待ち受ける tailnet の IP は tailscaled が上がるまで存在しない。
      After = [
        "network-online.target"
        "tailscaled.service"
      ];
      Wants = [
        "network-online.target"
        "tailscaled.service"
      ];
    };

    Service = {
      ExecStart = builtins.concatStringsSep " " [
        "${orcaServer}/bin/orca-ide serve"
        # bind に失敗しても Orca 自身が間隔を延ばしながら再起動する。
        "--supervise"
        "--bind ${tailnetAddress}"
        "--port 6768"
        "--pairing-address ${tailnetAddress}"
        "--refuse-public"
      ];
      Environment = [
        # エージェントの CLI を探せるよう、セッションへ渡す PATH を明示する。
        "PATH=${config.systemd.user.sessionVariables.PATH}"
        "ORCA_TELEMETRY_DISABLED=1"
        "DO_NOT_TRACK=1"
      ];
      # OpenCode Go の usage 表示用キー。sops が配るリポジトリ管理外のファイルで、
      # 無ければ渡さない。
      EnvironmentFile = [ "-%h/.config/orca/opencode.env" ];
      Restart = "on-failure";
      RestartSec = 10;
    };

    Install.WantedBy = [ "default.target" ];
  };
}
