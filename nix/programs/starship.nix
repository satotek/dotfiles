{ config, ... }:
let
  homeDirectory = config.home.homeDirectory;
  dotfilesDir = "${homeDirectory}/dotfiles";
in
{
  programs.starship = {
    enable = true;
    enableZshIntegration = false;
  };

  xdg.configFile."starship.toml".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/.config/starship.toml";
}
