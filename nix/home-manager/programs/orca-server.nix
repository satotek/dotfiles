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

  # Mac の Orca とスマホから Remote Orca Server として接続する常駐サーバー。
  systemd.user.services.orca-server = {
    Unit = {
      Description = "Orca headless runtime server";
      # リンクに載せる tailnet の IP は tailscaled が上がるまで存在しない。
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
        # 落ちても Orca 自身が間隔を延ばしながら再起動する。
        "--supervise"
        # スマホ向けのペアリングは待ち受けを全インターフェースへ広げるので、
        # 特定の IP に固定すると network_exposure_failed で断られる。公開 IP は
        # Azure の NAT の外にあり、届く公開アドレスも --refuse-public で断る。
        "--bind 0.0.0.0"
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
      # どちらもリポジトリ管理外のファイルで、無ければ渡さない。
      EnvironmentFile = [
        # エージェントが az repos / az boards を使う。DevOps の組織は az login と
        # 別テナントなので、T3 と同じ PAT を渡す。
        "-%h/.config/azure-devops/env"
        # OpenCode Go の usage 表示用キー。sops が配る。
        "-%h/.config/orca/opencode.env"
      ];
      Restart = "on-failure";
      RestartSec = 10;
    };

    Install.WantedBy = [ "default.target" ];
  };
}
