{ config, pkgs, ... }:
{
  # system / per-user / root の全プロファイルを整理してから、Nix Store の GC と
  # 最適化（同一ファイルのハードリンク化）まで root 権限で毎週実行する。
  # macOS では auto-optimise-store がビルドと競合して失敗し得るため、定期実行にする。
  # 開発用の GC root は保持する。
  launchd.daemons.nh-clean-system-generations = {
    serviceConfig = {
      ProgramArguments = [
        "${pkgs.nh}/bin/nh"
        "clean"
        "all"
        "--keep"
        "2"
        "--keep-since"
        "7d"
        "--no-gcroots"
        "--optimise"
      ];
      # nh は内部で `nix --version` を実行する。launchd はログインシェルの PATH も
      # /etc/paths.d も引き継がないため、nix を明示しないと
      # "No output from nix --version command" で失敗する。
      EnvironmentVariables.PATH = "${config.nix.package}/bin:/usr/bin:/bin:/usr/sbin:/sbin";
      # launchd は標準出力と標準エラーを捨てるため、失敗しても exit code しか残らない。
      # TCC (App Management) の拒否のようにメッセージが重要な失敗を追えるようにする。
      StandardOutPath = "/var/log/nh-clean-system.log";
      StandardErrorPath = "/var/log/nh-clean-system.log";
      RunAtLoad = false;
      StartCalendarInterval = [
        {
          Weekday = 7;
          Hour = 12;
          Minute = 15;
        }
      ];
    };
  };
}
