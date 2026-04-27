{ config, ... }:
let
  homeDirectory = config.home.homeDirectory;
  dotfilesDir = "${homeDirectory}/dotfiles";
in
{
  xdg.configFile."nix/nix.conf".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/.config/nix/nix.conf";
}
