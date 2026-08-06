{
  config,
  lib,
  pkgs,
  ...
}:
let
  homeDirectory = config.home.homeDirectory;
  deferCompinit = !pkgs.stdenv.isLinux;
  readZsh = name: builtins.readFile (./zsh + "/${name}.zsh");
in
{
  programs.zsh = {
    enable = true;
    dotDir = "${config.xdg.configHome}/zsh";
    autocd = true;
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
      nvchad = "NVIM_APPNAME=nvchad nvim";
      code = "code-insiders";
      sudo = "sudo ";
      python = "python3";
      ll = "ls -l";
      la = "ls -al";
      lg = "lazygit";
      "..." = "../../";
      "...." = "../../../";
      "....." = "../../../../";
      nfu = "nix flake update --flake ~/dotfiles";
      nfs = "nix flake show ~/dotfiles";
      ngc = "nix-collect-garbage -d";
    };

    envExtra = ''
      [ -f "$HOME/.config/profile" ] && . "$HOME/.config/profile"
    '';

    initContent = lib.mkMerge [
      (lib.mkBefore (readZsh "early"))

      ''
        ${readZsh "widgets"}
        ${readZsh "vm"}

        typeset -g DEFER_COMPINIT=${lib.boolToString deferCompinit}
        ${readZsh "init"}
        ${readZsh "prompt"}
      ''
    ];
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };
}
