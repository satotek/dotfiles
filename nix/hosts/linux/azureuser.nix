{
  system,
  hostname ? system,
}:
{
  inherit system hostname;
  userName = "azureuser";
  homeDirectory = "/home/azureuser";
  extraModules = [
    ../../home-manager/platforms/linux.nix
  ]
  ++ import ../../home-manager/presets/select.nix { withRust = false; };
}
