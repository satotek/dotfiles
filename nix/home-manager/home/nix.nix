{ config, pkgs, ... }:
let
  homeDirectory = config.home.homeDirectory;
  dotfilesDir = "${homeDirectory}/dotfiles";
  nixSwitch = pkgs.writeShellApplication {
    name = "nix-switch";
    text = ''
      cd "${dotfilesDir}"
      exec nix run home-manager/master -- switch --flake ".#$(id -un)@$(hostname)" "$@"
    '';
  };
in
{
  xdg.configFile."nix/nix.conf".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/.config/nix/nix.conf";

  home.packages = [ nixSwitch ];
}
