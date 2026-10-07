{
  system,
  hostname ? system,
}:
{
  inherit system hostname;
  userName = "nosuke";
  homeDirectory = "/home/nosuke";
  extraModules = [
    ../../home-manager/platforms/linux.nix
  ]
  ++ (import ../../home-manager/roles.nix).select [
    "base"
    "dev"
    "rust"
    "ai"
    "secrets"
  ];
}
