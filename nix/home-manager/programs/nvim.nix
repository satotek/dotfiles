{ config, pkgs, ... }:
let
  homeDirectory = config.home.homeDirectory;
  dotfilesDir = "${homeDirectory}/dotfiles";
in
{
  home.packages = [ pkgs.neovim ];

  xdg.configFile."nvim".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/.config/nvim";
}
