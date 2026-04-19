{ config, pkgs, ... }:
let
  homeDirectory = config.home.homeDirectory;
  dotfilesDir = "${homeDirectory}/dotfiles";
in
{
  home.packages = [ pkgs.sheldon ];

  xdg.configFile."sheldon/plugins.toml".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/nix/programs/sheldon/files/plugins.toml";
}
