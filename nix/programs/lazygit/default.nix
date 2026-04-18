{ config, pkgs, ... }:
let
  homeDirectory = config.home.homeDirectory;
  dotfilesDir = "${homeDirectory}/dotfiles";
in
{
  home.packages = [ pkgs.lazygit ];

  xdg.configFile."lazygit".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/nix/programs/lazygit/files";
}
