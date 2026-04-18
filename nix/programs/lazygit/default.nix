{ config, ... }:
let
  homeDirectory = config.home.homeDirectory;
  dotfilesDir = "${homeDirectory}/dotfiles";
in
{
  xdg.configFile."lazygit".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/nix/programs/lazygit/files";
}
