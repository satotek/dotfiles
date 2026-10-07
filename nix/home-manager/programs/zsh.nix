{
  config,
  lib,
  pkgs,
  ...
}:
let
  homeDirectory = config.home.homeDirectory;
  deferCompinit = !pkgs.stdenv.hostPlatform.isLinux;
  readZsh = name: builtins.readFile (./zsh + "/${name}.zsh");

  # `${commands[x]}` の初回参照はPATH全体（20+ディレクトリ）を走査してコマンド
  # ハッシュテーブルを構築するため、起動時に数msかかる。これらのツールの実体は
  # Nixが評価時に知っているので、絶対パスを焼き込んで走査そのものを避ける。
  # 無効化されているプログラムは空文字にして、zsh側の `[[ -n ... ]]` で弾く。
  zbin =
    varName: enable: package: exe:
    "typeset -g ${varName}=${lib.optionalString enable "${package}/bin/${exe}"}";

  binPrelude = lib.concatStringsSep "\n" [
    (zbin "_ZBIN_DIRENV" config.programs.direnv.enable config.programs.direnv.package "direnv")
    (zbin "_ZBIN_STARSHIP" config.programs.starship.enable config.programs.starship.package "starship")
    (zbin "_ZBIN_FZF" config.programs.fzf.enable config.programs.fzf.package "fzf")
    (zbin "_ZBIN_ZOXIDE" config.programs.zoxide.enable config.programs.zoxide.package "zoxide")
  ];
in
{
  imports = [ ./zsh/plugins.nix ];

  # Nixで補完が追加・更新されたら次のシェルで再登録する。
  # 通常の起動ではcompinit -Cによるキャッシュ利用を維持する。
  home.activation.invalidateZshCompletionCache = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    run ${pkgs.coreutils}/bin/rm -f \
      ${lib.escapeShellArg "${config.xdg.cacheHome}/zsh/.zcompdump"} \
      ${lib.escapeShellArg "${config.xdg.cacheHome}/zsh/.zcompdump.zwc"}
  '';

  programs.zsh = {
    enable = true;
    dotDir = "${config.xdg.configHome}/zsh";
    autocd = true;
    # 指定しないと EDITOR に "vi" が含まれるかで方式が変わるため、明示する。
    defaultKeymap = "viins";
    enableCompletion = false;
    setOptions = [ "NO_FLOW_CONTROL" ];

    history = {
      path = "${homeDirectory}/.local/state/zsh/history";
      size = 100000;
      save = 100000;
      extended = true;
      ignoreDups = true;
      ignoreAllDups = true;
      ignoreSpace = true;
      share = true;
      expireDuplicatesFirst = true;
    };

    shellAliases = {
      vi = "nvim";
      vim = "nvim";
      code = "code-insiders";
      sudo = "sudo ";
      python = "python3";
      lg = "lazygit";
      "..." = "../../";
      "...." = "../../../";
      "....." = "../../../../";
      nfu = "nix flake update --flake ~/dotfiles";
      nfs = "nix flake show ~/dotfiles";
      ngc = "nh clean user --keep 2 --no-gcroots";
    };

    envExtra = ''
      [ -f "$HOME/.config/profile" ] && . "$HOME/.config/profile"
    '';

    initContent = lib.mkMerge [
      (lib.mkBefore (readZsh "early"))

      ''
        ${readZsh "widgets"}
        ${readZsh "vm"}

        ${binPrelude}
        typeset -g DEFER_COMPINIT=${lib.boolToString deferCompinit}
        ${readZsh "init"}
        ${readZsh "prompt"}
        ${readZsh "vi-mode"}
      ''
    ];
  };

  programs.fzf = {
    enable = true;
    # init.zshで生成結果をキャッシュ・zcompileして読み込む。
    enableZshIntegration = false;
  };
}
