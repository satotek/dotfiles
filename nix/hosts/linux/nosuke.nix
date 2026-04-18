{ system, hostname ? system }:
{
  inherit system hostname;
  userName = "nosuke";
  homeDirectory = "/home/nosuke";
  extraModules = [
    ../../home-manager/linux.nix
  ];
}
