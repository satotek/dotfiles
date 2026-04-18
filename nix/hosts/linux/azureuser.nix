{ system, hostname ? system }:
{
  inherit system hostname;
  userName = "azureuser";
  homeDirectory = "/home/azureuser";
  extraModules = [
    ../../home-manager/linux.nix
  ];
}
