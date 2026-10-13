{
  config,
  lib,
  pkgs,
  ...
}:
let
  homeDirectory = config.home.homeDirectory;
  inherit (config.xdg) configHome dataHome;
  pnpmHome = "${dataHome}/pnpm";
  binHome = "${homeDirectory}/.local/bin";
  nixDaemon = "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh";
  secretsFile = "${configHome}/secrets";
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
    # 手で入れるコマンドは uv と同じ ~/.local/bin に集め、PATH に足す場所を増やさない。
    # cargo は rustup 本体が ~/.cargo/bin にあるため、pnpm は 11 以降の配置に任せるため対象外。
    GOBIN = binHome;
    NPM_CONFIG_PREFIX = "${homeDirectory}/.local";
    BUN_INSTALL_BIN = binHome;
    DENO_INSTALL_ROOT = "${homeDirectory}/.local";
    # OpenCode の /editor は EDITOR が空だと起動せず戻る。
    # git 以外のツールは VISUAL を EDITOR より先に見るので、両方を nvim にする。
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

  # PATH の順番は sessionPath（常に先頭へ追加）では表せないので、シェルで組む。
  # zsh のログインシェルでは .zshenv のこのファイルが .zprofile の
  # hm-session-vars より先に読まれるため、パスは評価時に埋め込んでおく。
  # 並び: 関数定義(500) → OS 固有の前置(800) → 共通の後置(1000)
  #       → OS 固有の後置(1200) → nix-daemon.sh の前置(Linux のみ)と export(1500)
  # macOS は nix-darwin の /etc/zshenv が PATH と NIX_PROFILES を組むので読まない。
  # nix-daemon.sh は default profile を /run/current-system/sw より前へ出してしまう。
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
      path_append "${binHome}"
      path_append "${homeDirectory}/.cargo/bin"
      path_append "${homeDirectory}/bin"
      path_append "${pnpmHome}/bin"
    ''

    (lib.mkAfter ''
      ${lib.optionalString pkgs.stdenv.hostPlatform.isLinux ''
        # The Nix installer only sources this from interactive zshrc. Read it here so
        # non-interactive zsh and login bash get the profile, SSL certs, and
        # NIX_PROFILES. The script exports a guard, so a later /etc/zsh/zshrc source
        # does not prepend the nix profiles again.
        if [ -r "${nixDaemon}" ]; then
          . "${nixDaemon}"
        fi
      ''}
      export PATH
      unset -f path_prepend path_append
    '')
  ];

  home.activation.restrictSecretsFile = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    secrets_file=${lib.escapeShellArg secretsFile}
    if [ -f "$secrets_file" ]; then
      run ${pkgs.coreutils}/bin/chmod 0600 "$secrets_file"
    fi
  '';

}
