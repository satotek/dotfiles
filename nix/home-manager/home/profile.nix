{ config, lib, ... }:
let
  homeDirectory = config.home.homeDirectory;
  inherit (config.xdg) configHome dataHome;
  pnpmHome = "${dataHome}/pnpm";
in
{
  xdg = {
    enable = true;
    cacheHome = "${homeDirectory}/.local/cache";
  };

  # XDG_* は xdg.enable が、ZDOTDIR は programs.zsh.dotDir が、HISTFILE は
  # programs.zsh.history.path がそれぞれ設定する。
  home.sessionVariables = {
    LESSHISTFILE = "${config.xdg.cacheHome}/less/history";
    WGETRC = "${configHome}/wget/wgetrc";
    INPUTRC = "${configHome}/readline/inputrc";
    PNPM_HOME = pnpmHome;
    # OpenCode の /editor は EDITOR が空だと起動せず戻る。
    EDITOR = "nvim";
  };

  # PATH の順番は sessionPath（常に先頭へ追加）では表せないので、シェルで組む。
  # zsh のログインシェルでは .zshenv のこのファイルが .zprofile の
  # hm-session-vars より先に読まれるため、パスは評価時に埋め込んでおく。
  # 並び: 関数定義(500) → OS 固有の前置(800) → 共通の後置(1000)
  #       → OS 固有の後置(1200) → export(1500)
  xdg.configFile."profile".text = lib.mkMerge [
    (lib.mkBefore ''
      # Update PATH only when the entry is missing so repeated sourcing stays clean.
      path_prepend() {
        case ":$PATH:" in
          *":$1:"*) ;;
          *) PATH="$1''${PATH:+:$PATH}" ;;
        esac
      }

      path_append() {
        case ":$PATH:" in
          *":$1:"*) ;;
          *) PATH="''${PATH:+$PATH:}$1" ;;
        esac
      }
    '')

    ''
      # Keep user-local bins available, but let Nix-managed tools win first.
      path_append "${homeDirectory}/.local/bin"
      path_append "${homeDirectory}/.cargo/bin"
      path_append "${homeDirectory}/bin"
      path_append "${pnpmHome}"
    ''

    (lib.mkAfter ''
      export PATH
      unset -f path_prepend path_append

      # Load local secrets (not tracked by git)
      [ -f "${configHome}/secrets" ] && . "${configHome}/secrets"
    '')
  ];
}
