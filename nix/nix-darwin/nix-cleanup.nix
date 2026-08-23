{ pkgs, ... }:
{
  # nix-darwin の古い system generation を整理し、Nix Store の GC も
  # root 権限で毎週実行する。開発用の GC root は保持する。
  launchd.daemons.nh-clean-system-generations = {
    serviceConfig = {
      ProgramArguments = [
        "${pkgs.nh}/bin/nh"
        "clean"
        "profile"
        "--keep"
        "2"
        "--keep-since"
        "7d"
        "--no-gcroots"
        "/nix/var/nix/profiles/system"
      ];
      # nh は内部で `nix --version` を実行する。launchd はログインシェルの PATH も
      # /etc/paths.d も引き継がないため、nix を明示しないと
      # "No output from nix --version command" で失敗する。
      EnvironmentVariables.PATH = "/nix/var/nix/profiles/default/bin:/usr/bin:/bin:/usr/sbin:/sbin";
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
