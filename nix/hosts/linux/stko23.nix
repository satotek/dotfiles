{
  system,
  hostname ? system,
}:
{
  inherit system hostname;
  userName = "stko23";
  homeDirectory = "/home/stko23";
  extraModules = [
    {
      dotfiles.sops.enable = false;
    }
    ../../home-manager/platforms/linux.nix
    ../../home-manager/presets/base.nix
    ../../home-manager/presets/agents.nix
    (
      { lib, ... }:
      {
        # WSL では React Aria の外部取得に依存しない。
        programs.agent-skills.enable = lib.mkForce false;
      }
    )
    ../../home-manager/presets/cloud.nix
    ../../home-manager/presets/devtools.nix
    ../../home-manager/presets/rust.nix
    ../../home-manager/presets/webdevtools.nix
  ];
}
