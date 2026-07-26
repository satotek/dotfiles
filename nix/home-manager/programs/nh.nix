{
  config,
  pkgs,
  ...
}:
let
  homeManagerProfile = "${config.home.homeDirectory}/.local/state/nix/profiles/home-manager";
in
{
  programs.nh.enable = true;

  # Store GC は Determinate Nixd に任せ、Home Manager の古い世代だけを
  # 毎週整理する。30 日以内の世代と、最低 5 世代のロールバック先を残す。
  launchd.agents.nh-clean-home-manager-generations = {
    enable = true;
    config = {
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
        homeManagerProfile
      ];
      RunAtLoad = false;
      StartCalendarInterval = [
        {
          Weekday = 7;
          Hour = 12;
          Minute = 0;
        }
      ];
    };
  };
}
