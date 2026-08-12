{
  config,
  pkgs,
  ...
}:
let
  homeManagerProfile = "${config.home.homeDirectory}/.local/state/nix/profiles/home-manager";

  # nh は内部で `nix --version` を実行するため、nix が PATH に無いと
  # "No output from nix --version command" で失敗する。launchd はログインシェルの
  # PATH も /etc/paths.d も引き継がないので、ジョブ側で明示する必要がある。
  # store パスではなく profile を指し、nix 更新に追随させる。
  launchdPath = "/nix/var/nix/profiles/default/bin:/usr/bin:/bin:/usr/sbin:/sbin";
in
{
  programs.nh.enable = true;

  # Store GC は Determinate Nixd に任せ、Home Manager の古い世代だけを
  # 毎週整理する。7 日以内の世代と、最低 5 世代のロールバック先を残す。
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
        "7d"
        "--no-gc"
        "--no-gcroots"
        homeManagerProfile
      ];
      EnvironmentVariables.PATH = launchdPath;
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
