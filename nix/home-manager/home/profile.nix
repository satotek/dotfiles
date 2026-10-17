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
  # ラベルは LaunchAgent の既定（org.nix-community.home.<name>）と kickstart で揃える。
  sessionEnvironmentLabel = "org.nix-community.home.session-environment";
  sessionVarsFile = "${config.home.sessionVariablesPackage}/etc/profile.d/hm-session-vars.sh";
  # null は「設定しない」なので、systemd や launchctl には渡さない。
  exportedSessionVariables = lib.mapAttrs (_: value: toString value) (
    lib.filterAttrs (_: value: value != null) config.home.sessionVariables
  );
  # user manager はシェルを読まない。シェルは継承した PATH の末尾へ手元の bin を足すので、
  # 同じ並びにはできない。Nix を先に、手元の bin をシステムの前に置く。
  # Ubuntu の既定 PATH も残し、snap などを潰さない。
  servicePath = lib.concatStringsSep ":" [
    "${config.home.profileDirectory}/bin"
    "/nix/var/nix/profiles/default/bin"
    binHome
    "${homeDirectory}/.cargo/bin"
    "${homeDirectory}/bin"
    "${pnpmHome}/bin"
    "/usr/local/sbin"
    "/usr/local/bin"
    "/usr/sbin"
    "/usr/bin"
    "/sbin"
    "/bin"
    "/usr/games"
    "/usr/local/games"
    "/snap/bin"
  ];
  setenvCalls = lib.concatMapStrings (name: "setenv_if_set ${lib.escapeShellArg name}\n") (
    [
      "PATH"
      "NIX_PROFILES"
      "NIX_SSL_CERT_FILE"
      "XDG_DATA_DIRS"
      "INFOPATH"
      "MANPATH"
    ]
    ++ lib.attrNames exportedSessionVariables
  );
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

  # XDG_* と LOCALE_ARCHIVE だけが既定で environment.d に入る。残りと PATH も
  # ユーザーサービスへ渡す。ファイルは user manager の起動時にしか読まれないので、
  # 起動中のセッションへは下の activation が set-environment する。
  systemd.user.sessionVariables = lib.mkIf pkgs.stdenv.hostPlatform.isLinux (
    exportedSessionVariables // { PATH = servicePath; }
  );

  # environment.d は $VAR を展開するが set-environment はそのまま入れるので、
  # 参照を含む値は起動直後と switch 後で食い違う。入れる前に評価で止める。
  assertions = lib.optionals pkgs.stdenv.hostPlatform.isLinux (
    lib.mapAttrsToList (name: value: {
      assertion = !lib.hasInfix "$" value;
      message = "home.sessionVariables.${name} references another variable; systemctl set-environment would store it unexpanded.";
    }) exportedSessionVariables
  );

  # launchctl setenv は呼んだドメインにしか残らず、再起動で消える。GUI ドメインの
  # LaunchAgent がログイン時と、plist が変わった switch 時にセットし直す。
  launchd.agents.session-environment = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
    enable = true;
    config = {
      Label = sessionEnvironmentLabel;
      RunAtLoad = true;
      ProgramArguments = [
        "/bin/sh"
        "-c"
        ''
          # setenv した値は次の起動に引き継がれる。nix-daemon.sh と Homebrew の
          # INFOPATH は重複を避けないので、組み立て直す変数は消してから読む。
          # FPATH は出さない。Homebrew だけの値だと zsh が組み込み関数を読み込まない。
          unset PATH FPATH INFOPATH MANPATH XDG_DATA_DIRS NIX_PROFILES NIX_SSL_CERT_FILE
          unset __ETC_PROFILE_NIX_SOURCED __HM_SESS_VARS_SOURCED
          /bin/launchctl unsetenv FPATH
          export PATH="/usr/bin:/bin:/usr/sbin:/sbin"

          . ${lib.escapeShellArg sessionVarsFile}
          if [ -f ${lib.escapeShellArg "${configHome}/profile"} ]; then
            . ${lib.escapeShellArg "${configHome}/profile"}
          fi

          setenv_if_set() {
            # eval の間接展開は /bin/sh では bad substitution になる。printenv なら
            # 値に空白やクォートがあってもそのまま渡せる。
            value="$(/usr/bin/printenv "$1" || true)"
            [ -n "$value" ] || return 0
            /bin/launchctl setenv "$1" "$value"
          }

          ${setenvCalls}
        ''
      ];
    };
  };

  home.activation.restrictSecretsFile = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    secrets_file=${lib.escapeShellArg secretsFile}
    if [ -f "$secrets_file" ]; then
      run ${pkgs.coreutils}/bin/chmod 0600 "$secrets_file"
    fi
  '';

  home.activation.applySystemdSessionEnvironment = lib.mkIf pkgs.stdenv.hostPlatform.isLinux (
    # reloadSystemd が再起動するサービスに新しい環境を渡すため、その前にセットする。
    lib.hm.dag.entryBetween [ "reloadSystemd" ] [ "linkGeneration" ] ''
      runtime_dir="''${XDG_RUNTIME_DIR:-/run/user/$(${pkgs.coreutils}/bin/id -u)}"
      if [ -S "$runtime_dir/systemd/private" ]; then
        run env XDG_RUNTIME_DIR="$runtime_dir" ${pkgs.systemd}/bin/systemctl --user set-environment ${
          lib.concatStringsSep " " (
            lib.mapAttrsToList (name: value: "${name}=${lib.escapeShellArg value}") (
              exportedSessionVariables // { PATH = servicePath; }
            )
          )
        } || true
      fi
    ''
  );

  home.activation.refreshGuiSessionEnvironment = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin (
    lib.hm.dag.entryAfter
      [
        "linkGeneration"
        "setupLaunchAgents"
      ]
      ''
        # linkGeneration より先に RunAtLoad しても、リンク後の profile で GUI ドメインに
        # もう一度セットする。SSH からの switch でも gui ドメインのエージェントが走る。
        uid="$(/usr/bin/id -u)"
        if /bin/launchctl print "gui/$uid" >/dev/null 2>&1; then
          run /bin/launchctl kickstart -k "gui/$uid/${sessionEnvironmentLabel}" || true
        fi
      ''
  );
}
