{
  system,
  hostname ? system,
}:
{
  inherit system hostname;
  userName = "stko23";
  homeDirectory = "/home/stko23";
  extraModules = [
    ../../home-manager/platforms/linux.nix
    ../../home-manager/presets/base.nix
    ../../home-manager/presets/devtools.nix
    ../../home-manager/presets/rust.nix
    ../../home-manager/presets/webdevtools.nix
  ];
}
