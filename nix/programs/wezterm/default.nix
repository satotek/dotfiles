{ config, pkgs, ... }:
let
  homeDirectory = config.home.homeDirectory;
  dotfilesDir = "${homeDirectory}/dotfiles";
in
{
  home.packages = [ pkgs.wezterm ];

  xdg.configFile."wezterm".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/nix/programs/wezterm/files";
}
