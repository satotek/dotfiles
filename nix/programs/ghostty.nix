{ config, ... }:
let
  homeDirectory = config.home.homeDirectory;
  dotfilesDir = "${homeDirectory}/dotfiles";
in
{
  xdg.configFile."ghostty".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/.config/ghostty";
}
