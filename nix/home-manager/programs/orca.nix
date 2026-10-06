{
  config,
  pkgs,
  ...
}:
let
  # llm-agents の deb パッケージ。orca は Node の CLI、orca-ide が Electron 本体。
  # serve は本体側で、wrapper が xvfb と Electron のライブラリを通す。
  orca = pkgs.llm-agents.orca;
  # アプリにはループバックを広告する。社内 NW からは直接届かないので、手元の ssh に
  # -L 127.0.0.1:16768:127.0.0.1:16768 を足し、Orca の「SSH トンネルを使用」でペアリングする。
  pairingAddress = "127.0.0.1";
  # 既定の 6768 は手元のデスクトップ Orca 自身が掴むので、トンネルの口と衝突しない番号にする。
  port = 16768;
in
{
  # ヘッドレスのランタイム。操作は SSH トンネル越しのデスクトップアプリ。
  home.packages = [ orca ];

  systemd.user.services.orca = {
    Unit = {
      Description = "Orca runtime server";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };

    Service = {
      Type = "simple";
      Environment = [
        "LIBGL_ALWAYS_SOFTWARE=1"
        # profile の bin は Orca が claude や codex を探すため。
        "PATH=${config.home.profileDirectory}/bin:/usr/local/bin:/usr/bin:/bin"
      ];
      ExecStart = "${orca}/bin/orca-ide serve --port ${toString port} --pairing-address ${pairingAddress} --json";
      Restart = "on-failure";
      RestartSec = 5;
      # 同じプロフィールを別プロセスが掴んでいるときは再起動しない。
      RestartPreventExitStatus = [ 3 ];
    };

    Install.WantedBy = [ "default.target" ];
  };
}
