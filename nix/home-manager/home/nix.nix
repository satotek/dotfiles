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
          # 未管理ファイルと衝突しても、エラーで止めず自動で .hm-bak に退避してから
          # symlink を張る（standalone HM には declarative オプションが無いので env で指定）。
          export HOME_MANAGER_BACKUP_EXT="''${HOME_MANAGER_BACKUP_EXT:-hm-bak}"
          exec nix run home-manager/master -- switch --flake ".#$(id -un)@$(scutil --get LocalHostName)" "$@"
        ''
      else
        ''
          cd "${dotfilesDir}"
          # 未管理ファイルと衝突しても、エラーで止めず自動で .hm-bak に退避してから
          # symlink を張る（standalone HM には declarative オプションが無いので env で指定）。
          export HOME_MANAGER_BACKUP_EXT="''${HOME_MANAGER_BACKUP_EXT:-hm-bak}"
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
