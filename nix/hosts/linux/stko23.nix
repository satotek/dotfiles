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
    (
      { lib, ... }:
      {
        # WSL では agent-skills の外部取得に依存しない。
        programs.agent-skills.enable = lib.mkForce false;
      }
    )
  ]
  ++ (import ../../home-manager/roles.nix).select [
    "base"
    "dev"
    "rust"
    "ai"
    "secrets"
  ];
}
