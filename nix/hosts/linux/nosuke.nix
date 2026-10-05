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
  ++ import ../../home-manager/presets/select.nix { };
}
