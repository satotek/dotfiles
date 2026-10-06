{
  config,
  lib,
  pkgs,
  ...
}:
let
  homeDirectory = config.home.homeDirectory;
  dotfilesDir = "${homeDirectory}/dotfiles";
  # nix-output-monitor は TUI を描き直し続けるため、エージェントの実行ログや
  # パイプに流れると読めなくなる。端末でないときは通常のビルドログに切り替える。
  nomFlag = ''
    nom_flag=()
    if [ ! -t 1 ]; then
      nom_flag=(--no-nom)
    fi
  '';
  # ホーム層の切り替え。両 OS とも standalone Home Manager なので sudo 不要。
  # macOS の hostname はネットワーク次第で変わるため、設定上の名前を使う。
  nixSwitch = pkgs.writeShellApplication {
    name = "nix-switch";
    runtimeInputs = [ config.programs.nh.package ];
    text = ''
      ${nomFlag}
      # 未管理ファイルと衝突しても、エラーで止めず自動で .hm-bak に退避してから
      # symlink を張る。
      exec nh home switch "${dotfilesDir}" \
        -c "$(id -un)@${
          if pkgs.stdenv.hostPlatform.isDarwin then "$(scutil --get LocalHostName)" else "$(hostname)"
        }" \
        -b "''${HOME_MANAGER_BACKUP_EXT:-hm-bak}" \
        "''${nom_flag[@]}" "$@"
    '';
  };
  # システム層 (nix-darwin: Homebrew casks, fonts, macOS 設定) の切り替え。
  # 有効化の段階だけ nh が sudo で昇格するので、全体を sudo で包まない。
  darwinSwitch = pkgs.writeShellApplication {
    name = "darwin-switch";
    runtimeInputs = [ config.programs.nh.package ];
    text = ''
      ${nomFlag}
      exec nh darwin switch "${dotfilesDir}" -H "$(scutil --get LocalHostName)" "''${nom_flag[@]}" "$@"
    '';
  };
in
{
  # switch は nh に任せる。NH_FLAKE も設定されるので、素の `nh home switch` でも
  # dotfiles を参照できる。世代の自動整理は macOS 側の programs/nh.nix にある。
  programs.nh = {
    enable = true;
    flake = dotfilesDir;
  };

  xdg.configFile."nix/nix.conf".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/.config/nix/nix.conf";

  home.packages = [ nixSwitch ] ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [ darwinSwitch ];
}
