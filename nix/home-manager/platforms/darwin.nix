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

  # nixpkgs の 1.6.2 は Apple のサインイン変更に追従しておらず、ログインが
  # DecodingError で失敗する。修正は 2.1.0 から。nixpkgs 版は SwiftPM の依存を
  # 生成し直さないと上げられないので、公式の署名済みバイナリをそのまま使う。
  # nixpkgs が 2.1.0 以上になったら pkgs.xcodes に戻す。
  xcodes = pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
    pname = "xcodes";
    version = "2.1.0";

    src = pkgs.fetchzip {
      url = "https://github.com/XcodesOrg/xcodes/releases/download/${finalAttrs.version}/xcodes.zip";
      stripRoot = false;
      hash = "sha256-yffHopseb030I95h0aTwlTk5Qbsmz5AB7ZjHnrX2wD4=";
    };

    nativeBuildInputs = [ pkgs.makeWrapper ];

    # strip などで署名を壊さないよう、バイナリには手を加えない。
    dontFixup = true;

    installPhase = ''
      runHook preInstall
      install -Dm755 xcodes $out/bin/xcodes
      wrapProgram $out/bin/xcodes --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.aria2 ]}
      runHook postInstall
    '';

    meta.platforms = pkgs.lib.platforms.darwin;
  });
in
{
  imports = [
    ../programs/aerospace.nix
    ../programs/karabiner.nix
    ../programs/nh.nix
    ../presets/terminal.nix
  ];

  # Xcode.app は Nix にも Homebrew にも載せず、xcodes で導入と切り替えを行う。
  home.packages = [
    xcodes
    pkgs.xcodegen
    pkgs.llm-agents.orca
    # 常駐させず、使うときに ollama serve する。モデルは ~/.ollama に残る。
    pkgs.ollama
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
