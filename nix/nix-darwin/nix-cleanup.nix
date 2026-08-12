{ pkgs, ... }:
{
  # Determinate Nixd の Store GC と重複させず、nix-darwin の古い
  # system generation だけを root 権限で毎週整理する。
  launchd.daemons.nh-clean-system-generations = {
    serviceConfig = {
      ProgramArguments = [
        "${pkgs.nh}/bin/nh"
        "clean"
        "profile"
        "--keep"
        "5"
        "--keep-since"
        "7d"
        "--no-gc"
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
