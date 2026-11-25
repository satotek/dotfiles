{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  dsh = pkgs.llm-agents.dsh;
  # コミュニティ flake の TUI preset。bin 名は dsh のままなので、PATH には出さない。
  # Orca はコマンド名 dsh-tui（別名 dst）を探し、dsh-tui . で起動する。
  dshTui = inputs.deepseek-harness.legacyPackages.${pkgs.stdenv.hostPlatform.system}.presets.tui;
  # 空でない DSH_TELEMETRY_DISABLED は session-telemetry-otel 行自体を外す。
  # MODE は行が残ったときの共有方針。製品分析は profile 名が desktop のときだけ動く。
  telemetryEnv = {
    DSH_TELEMETRY_DISABLED = "1";
    DSH_TELEMETRY_MODE = "DISABLED";
  };
  # TUI 内の /update が公式 dsh とランチャーを npm で入れ直すのを止める。
  tuiUpdateEnv = {
    DSH_TUI_UPDATE_ENGINE = "0";
    DSH_TUI_UPDATE_LAUNCHER = "0";
  };
  # preset の dsh は先頭の位置引数をプロファイル名にする。
  # Orca は `dsh-tui .` で起動する。npm ランチャーは存在するパスを
  # DSH_TUI_WORKSPACE_TARGET に移し、プロンプトは `--` の後ろに渡す。
  dshTuiBin = pkgs.writeShellScriptBin "dsh-tui" ''
    export DSH_TELEMETRY_DISABLED=1
    export DSH_TELEMETRY_MODE=DISABLED
    export DSH_TUI_UPDATE_ENGINE=0
    export DSH_TUI_UPDATE_LAUNCHER=0

    is_workspace_token() {
      case "$1" in
        -*) return 1 ;;
        /*) return 0 ;;
        [a-zA-Z]*://*) return 0 ;;
      esac
      [ -e "$1" ]
    }

    host_args=()
    app_args=()
    take_host_value=0
    take_resume_id=0
    seen_dd=0
    took_workspace=0

    for arg in "$@"; do
      if [ "$take_host_value" -eq 1 ]; then
        host_args+=("$arg")
        take_host_value=0
        continue
      fi
      if [ "$take_resume_id" -eq 1 ]; then
        take_resume_id=0
        case "$arg" in
          -*) ;;
          *)
            host_args+=("$arg")
            continue
            ;;
        esac
      fi
      if [ "$seen_dd" -eq 1 ]; then
        app_args+=("$arg")
        continue
      fi
      case "$arg" in
        --)
          seen_dd=1
          app_args+=("--")
          continue
          ;;
        --profile | --from-default-profile | --patch | --backend)
          host_args+=("$arg")
          take_host_value=1
          continue
          ;;
        --profile=* | --from-default-profile=* | --patch=* | --backend=* | --resume=*)
          host_args+=("$arg")
          continue
          ;;
        --dump-config | --dump-default-config | --dump-config-schema | -V | --version | -h | --help)
          host_args+=("$arg")
          continue
          ;;
        --resume)
          host_args+=("$arg")
          take_resume_id=1
          continue
          ;;
        -c | --continue)
          host_args+=("$arg")
          continue
          ;;
      esac
      if [ "$took_workspace" -eq 0 ] && [ -z "''${DSH_TUI_WORKSPACE_TARGET-}" ] && is_workspace_token "$arg"; then
        export DSH_TUI_WORKSPACE_TARGET="$arg"
        took_workspace=1
        continue
      fi
      case "$arg" in
        -*) host_args+=("$arg") ;;
        *) app_args+=("$arg") ;;
      esac
    done

    final=()
    if [ "''${#host_args[@]}" -gt 0 ]; then
      final+=("''${host_args[@]}")
    fi
    if [ "''${#app_args[@]}" -gt 0 ]; then
      case "''${app_args[0]}" in
        --) final+=("''${app_args[@]}") ;;
        *) final+=("--" "''${app_args[@]}") ;;
      esac
    fi

    exec ${lib.getExe dshTui} "''${final[@]}"
  '';
  dshTuiPkg = pkgs.symlinkJoin {
    name = "dsh-tui";
    paths = [ dshTuiBin ];
    postBuild = ''
      ln -s dsh-tui $out/bin/dst
    '';
    meta.mainProgram = "dsh-tui";
  };
  port = 3080;
  webArgs = [
    "--profile"
    "web"
    "--no-open"
    "--host"
    "127.0.0.1"
    "--port"
    (toString port)
  ];

  # $DSH_HOME/cordis.patch.yml は全プロファイルに適用されるホームレイヤー。
  # provider の宣言をここへ集約し、web / acp / dsh-tui で API キーの配線を共有する。
  # キー本体は sops が ~/.dsh/.env に置く。
  homePatch = pkgs.writeText "dsh-home-patch.yml" ''
    # Home layer applied to every dsh profile. Providers live here so web, acp,
    # and dsh-tui share the same API key wiring.
    - id: llm-pi-ai
      name: "@deepseek-ai/dsh-llm-pi-ai"
      config:
        providers:
          opencode-go:
            apiKeyEnv: OPENCODE_GO_API_KEY
    # session-telemetry-otel is in dsh-base, so this id exists on web, headless,
    # acp, and nix-tui. disabled is the hard off; config cannot turn the row off.
    # Desktop product analytics is a web-app row and stays off unless the
    # profile name is desktop, so it is not listed here.
    - id: session-telemetry-otel
      disabled: true
  '';
in
{
  config = {
    # DeepSeek Harness。upstream はリリース成果物を出さないので、
    # llm-agents.nix がソースからビルドしたパッケージを使う。
    # dsh-tui は別 flake の preset を包んだコマンドで、ここの dsh は置き換えない。
    home.packages = [
      dsh
      dshTuiPkg
    ];

    home.sessionVariables = telemetryEnv // tuiUpdateEnv;

    # dsh のホームレイヤーを宣言する。プロファイル側の patch は dsh が
    # 書き戻すので触らず、全プロファイル共通の provider 設定だけを置く。
    home.activation.configureDshHomePatch = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run ${pkgs.coreutils}/bin/install -d -m 0700 ${lib.escapeShellArg "${config.home.homeDirectory}/.dsh"}
      run ${pkgs.coreutils}/bin/install -m 0600 ${homePatch} ${lib.escapeShellArg "${config.home.homeDirectory}/.dsh/cordis.patch.yml"}
    '';

    # ブラウザ UI は前景プロセスなので、ログイン時に常駐させる。
    # URL は起動ログに出る。Linux は journalctl、macOS は ~/Library/Logs を見る。
    systemd.user.services.dsh = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      Unit = {
        Description = "DeepSeek Harness web UI";
        After = [ "network-online.target" ];
        Wants = [ "network-online.target" ];
      };

      Service = {
        Type = "simple";
        Environment = [
          "PATH=${config.systemd.user.sessionVariables.PATH}"
        ]
        ++ lib.mapAttrsToList (name: value: "${name}=${value}") telemetryEnv;
        ExecStart = "${dsh}/bin/dsh ${lib.concatStringsSep " " webArgs}";
        WorkingDirectory = "%h";
        Restart = "always";
        RestartSec = 5;
      };

      Install.WantedBy = [ "default.target" ];
    };

    launchd.agents.dsh = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
      enable = true;
      config = {
        Label = "org.nix-community.home.dsh";
        ProgramArguments = [ "${dsh}/bin/dsh" ] ++ webArgs;
        WorkingDirectory = config.home.homeDirectory;
        RunAtLoad = true;
        KeepAlive = true;
        EnvironmentVariables = telemetryEnv // {
          PATH = lib.concatStringsSep ":" [
            "${config.home.profileDirectory}/bin"
            "/nix/var/nix/profiles/default/bin"
            "/usr/local/bin"
            "/usr/bin"
            "/bin"
            "/usr/sbin"
            "/sbin"
          ];
        };
        StandardOutPath = "${config.home.homeDirectory}/Library/Logs/dsh-web.log";
        StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/dsh-web.err.log";
      };
    };

    # Dock や Orca から起動したプロセスはシェルの sessionVariables を見ない。
    launchd.agents.dsh-telemetry-env = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
      enable = true;
      config = {
        ProgramArguments = [
          "/bin/sh"
          "-c"
          (lib.concatStringsSep "; " (
            lib.mapAttrsToList (name: value: "/bin/launchctl setenv ${name} ${value}") (
              telemetryEnv // tuiUpdateEnv
            )
          ))
        ];
        RunAtLoad = true;
      };
    };
  };
}
