{ config, ... }:
let
  homeDirectory = config.home.homeDirectory;
  dotfilesDir = "${homeDirectory}/dotfiles";
in
{
  xdg.enable = true;

  xdg.configFile."profile".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/nix/home-manager/home/profile.sh";
}
