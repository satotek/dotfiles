{
  config,
  lib,
  pkgs,
  ...
}:
let
  homeDirectory = config.home.homeDirectory;
  dotfilesDir = "${homeDirectory}/dotfiles";
  # nh は内部で `nix --version` を実行するため、nix が PATH に無いと
  # "No output from nix --version command" で失敗する。launchd も systemd の
  # user manager もログインシェルの PATH を引き継がないので、ジョブ側で明示する。
  # store パスではなく profile を指し、nix 更新に追随させる。
  nhCleanPath = "/nix/var/nix/profiles/default/bin:/usr/bin:/bin:/usr/sbin:/sbin";
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
  # dotfiles を参照できる。
  programs.nh = {
    enable = true;
    flake = dotfilesDir;
    # standalone HM は home-manager と profile (home-manager-path) の 2 プロファイルに
    # 世代を積むため、片方だけでなく `nh clean user` で両方を整理する。
    # 7 日以内の世代と最低 2 世代のロールバック先を残し、direnv などの開発用
    # GC root は保持する。macOS は Store GC を system 側の job に集約している。
    # GC 後に同一内容のファイルをハードリンクでまとめ、store を 15% ほど縮める。
    clean = {
      enable = true;
      dates = "weekly";
      extraArgs = [
        "--keep"
        "2"
        "--keep-since"
        "7d"
        "--no-gcroots"
      ]
      ++ (if pkgs.stdenv.hostPlatform.isDarwin then [ "--no-gc" ] else [ "--optimise" ]);
    };
  };
  systemd.user.services.nh-clean.Service.Environment = lib.mkIf pkgs.stdenv.hostPlatform.isLinux [
    "PATH=${nhCleanPath}"
  ];
  launchd.agents.nh-clean.config.EnvironmentVariables.PATH =
    lib.mkIf pkgs.stdenv.hostPlatform.isDarwin nhCleanPath;

  xdg.configFile."nix/nix.conf".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/.config/nix/nix.conf";

  home.packages = [ nixSwitch ] ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [ darwinSwitch ];
}
