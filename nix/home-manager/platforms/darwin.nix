{
  config,
  lib,
  pkgs,
  ...
}:
let
  homebrewPrefix = "/opt/homebrew";
  # Android Studio の SDK Manager が管理する SDK。adb を Studio と揃えるため Nix では入れない。
  androidHome = "${config.home.homeDirectory}/Library/Android/sdk";
in
{
  imports = [
    ../programs/aerospace.nix
    ../programs/karabiner.nix
    ../programs/nh.nix
  ];

  # Xcode.app は Nix にも Homebrew にも載せず、xcodes で導入と切り替えを行う。
  home.packages = [
    pkgs.xcodes
    pkgs.llm-agents.orca
  ];

  home.sessionVariables = {
    ANDROID_HOME = androidHome;
    # `brew shellenv` は読み込むたびに path_helper を呼ぶので、prefix を直接宣言する。
    HOMEBREW_PREFIX = homebrewPrefix;
    HOMEBREW_CELLAR = "${homebrewPrefix}/Cellar";
    HOMEBREW_REPOSITORY = homebrewPrefix;
  };

  # 並びの意味は home/profile.nix を参照。
  xdg.configFile."profile".text = lib.mkMerge [
    (lib.mkOrder 800 ''
      if [ -x "${homebrewPrefix}/bin/brew" ]; then
        path_prepend "${homebrewPrefix}/sbin"
        path_prepend "${homebrewPrefix}/bin"

        if [ -n "''${ZSH_VERSION:-}" ]; then
          fpath=("${homebrewPrefix}/share/zsh/site-functions" $fpath)
          typeset -U fpath
          export FPATH
        else
          export FPATH="${homebrewPrefix}/share/zsh/site-functions''${FPATH:+:$FPATH}"
        fi

        [ -z "''${MANPATH-}" ] || export MANPATH=":''${MANPATH#:}"
        export INFOPATH="${homebrewPrefix}/share/info:''${INFOPATH:-}"
      fi

      # /etc/paths.d is where pkg installers (.NET, TeX, Wireshark, ...) register
      # their bin directories. nix-darwin's /etc/zprofile does not run path_helper,
      # and path_helper would reorder PATH ahead of Nix, so append the entries here.
      for paths_file in $(command ls /etc/paths.d 2>/dev/null); do
        while IFS= read -r paths_entry || [ -n "$paths_entry" ]; do
          case "$paths_entry" in "" | "#"*) continue ;; esac
          # dotnet-cli-tools registers "~/.dotnet/tools", which path_helper never expands.
          case "$paths_entry" in "~"*) paths_entry="$HOME''${paths_entry#\~}" ;; esac
          [ -d "$paths_entry" ] && path_append "$paths_entry"
        done < "/etc/paths.d/$paths_file"
      done
      unset paths_file paths_entry
    '')

    (lib.mkOrder 1200 ''
      if [ -d "${androidHome}" ]; then
        path_append "${androidHome}/platform-tools"
        path_append "${androidHome}/cmdline-tools/latest/bin"
        path_append "${androidHome}/emulator"
      fi
    '')
  ];
}
