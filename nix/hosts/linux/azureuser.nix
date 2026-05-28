{ system, hostname ? system }:
{
  inherit system hostname;
  userName = "azureuser";
  homeDirectory = "/home/azureuser";
  extraModules = [
    ../../home-manager/platforms/linux.nix
    ../../home-manager/presets/base.nix
    ../../home-manager/presets/devtools.nix
    ../../home-manager/presets/webdevtools.nix
  ];
}
