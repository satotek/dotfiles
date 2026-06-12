{
  config,
  lib,
  pkgs,
  ...
}:
let
  homeDirectory = config.home.homeDirectory;
  dotfilesDir = "${homeDirectory}/dotfiles";
  # ホーム層の切り替え。両 OS とも standalone Home Manager なので sudo 不要。
  nixSwitch = pkgs.writeShellApplication {
    name = "nix-switch";
    text =
      if pkgs.stdenv.isDarwin then
        ''
          cd "${dotfilesDir}"
          exec nix run home-manager/master -- switch --flake ".#$(id -un)@$(scutil --get LocalHostName)" "$@"
        ''
      else
        ''
          cd "${dotfilesDir}"
          exec nix run home-manager/master -- switch --flake ".#$(id -un)@$(hostname)" "$@"
        '';
  };
  # システム層 (nix-darwin: Homebrew casks, fonts, macOS 設定) の切り替え。
  # こちらだけ sudo が必要。
  darwinSwitch = pkgs.writeShellApplication {
    name = "darwin-switch";
    text = ''
      cd "${dotfilesDir}"
      exec sudo darwin-rebuild switch --flake ".#$(scutil --get LocalHostName)" "$@"
    '';
  };
in
{
  xdg.configFile."nix/nix.conf".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/.config/nix/nix.conf";

  home.packages = [ nixSwitch ] ++ lib.optionals pkgs.stdenv.isDarwin [ darwinSwitch ];
}
