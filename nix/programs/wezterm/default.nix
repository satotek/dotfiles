{ config, ... }:
let
  homeDirectory = config.home.homeDirectory;
  dotfilesDir = "${homeDirectory}/dotfiles";
in
{
  xdg.configFile."wezterm".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/nix/programs/wezterm/files";
}
