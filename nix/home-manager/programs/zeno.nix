{ config, ... }:
let
  homeDirectory = config.home.homeDirectory;
  dotfilesDir = "${homeDirectory}/dotfiles";
in
{
  xdg.configFile."zeno".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/.config/zeno";
}
