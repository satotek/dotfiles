{ system, hostname ? system }:
{
  inherit system hostname;
  userName = "nosuke";
  homeDirectory = "/home/nosuke";
  extraModules = [
    ../../home-manager/platforms/linux.nix
    ../../home-manager/presets/base.nix
    ../../home-manager/presets/devtools.nix
    ../../home-manager/presets/webdevtools.nix
  ];
}
