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
        "30d"
        "--no-gc"
        "--no-gcroots"
        "/nix/var/nix/profiles/system"
      ];
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
