{
  config,
  inputs,
  pkgs,
  lib,
  ...
}:
let
  homeDir = config.home.homeDirectory;
  sharedMcpServers = import ../data/mcp-servers.nix {
    inherit pkgs;
    isLinux = pkgs.stdenv.hostPlatform.isLinux;
  };
  # ccstatusline の行構成。1行目=モデル/コンテキスト/effort、2行目=git/圧縮内訳、
  # 3行目=ネイティブの5時間/週次使用量+リセット時刻+セッションコスト。
  ccstatuslineSettings = {
    # ccstatusline の設定スキーマ版。パッケージ側の CURRENT_VERSION と揃える。
    # 古いままだと ccstatusline が移行後の書き戻しを試み、nix store 上の
    # read-only な settings.json で EACCES → 既定値へフォールバックし
    # ステータスラインに "⚠ invalid config" が出る。
    version = 4;
    lines = [
      [
        {
          id = "1";
          type = "model";
          color = "hex:89DCEB";
        }
        {
          id = "2";
          type = "separator";
        }
        {
          id = "3";
          type = "context-length";
          color = "hex:89B4FA";
        }
        {
          id = "4";
          type = "separator";
        }
        {
          id = "18";
          type = "context-percentage";
          rawValue = true;
          color = "hex:89B4FA";
        }
        {
          id = "19";
          type = "separator";
        }
        {
          id = "9";
          type = "thinking-effort";
          color = "hex:F5C2E7";
        }
      ]
      [
        {
          id = "5";
          type = "git-branch";
          maxWidth = 28;
          color = "hex:CBA6F7";
        }
        {
          id = "6";
          type = "separator";
        }
        {
          id = "7";
          type = "git-changes";
          color = "hex:F9E2AF";
        }
        {
          id = "10";
          type = "separator";
        }
        {
          id = "11";
          type = "compaction-counter";
          color = "hex:FAB387";
          metadata = {
            hide = "zero";
            showTriggers = "true";
          };
        }
      ]
      [
        {
          id = "8";
          type = "session-usage";
          color = "hex:94E2D5";
          numberFormat = {
            style = "whole";
          };
          metadata = {
            display = "slider";
            hide = "no-data";
            label = "5h ";
          };
        }
        {
          id = "12";
          type = "separator";
        }
        {
          id = "13";
          type = "reset-timer";
          color = "hex:A6ADC8";
          metadata = {
            compact = "true";
            hide = "no-data";
            label = "Reset: ";
          };
        }
        {
          id = "14";
          type = "separator";
        }
        {
          id = "15";
          type = "weekly-usage";
          color = "hex:89B4FA";
          numberFormat = {
            style = "whole";
          };
          metadata = {
            display = "slider";
            hide = "no-data";
            label = "7d ";
          };
        }
        {
          id = "16";
          type = "separator";
        }
        {
          id = "17";
          type = "session-cost";
          rawValue = true;
          color = "hex:A6E3A1";
          metadata = {
            hide = "zero";
          };
        }
      ]
    ];
    flexMode = "full-minus-40";
    compactThreshold = 60;
    colorLevel = 2;
    inheritSeparatorColors = false;
    globalBold = false;
    gitCacheTtlSeconds = 5;
    minimalistMode = false;
    powerline = {
      enabled = false;
      separators = [ "" ];
      separatorInvertBackground = [ false ];
      startCaps = [ ];
      endCaps = [ ];
      autoAlign = false;
      continueThemeAcrossLines = false;
    };
  };
in
{
  # ccstatusline 設定を Home Manager 管理下に置く。
  home.file.".config/ccstatusline/settings.json".text = builtins.toJSON ccstatuslineSettings;

  # statusLine.command は nix store の絶対パス参照なので PATH には入らない。
  # 設定 TUI（ccstatusline コマンド）を手動起動できるよう PATH にも追加する。
  # ccusage は cleanupPeriodDays で残しているセッション履歴を集計するため。
  home.packages = [
    pkgs.llm-agents.ccstatusline
    pkgs.llm-agents.ccusage
  ];

  programs.claude-code = {
    enable = true;
    package = pkgs.llm-agents.claude-code;

    # Claude Code は /permissions や /config で settings.json を書き戻す。
    # Nix store への symlink のままだと書き込みが失敗するため、宣言した値だけを
    # activation でマージし、アプリが書いた未宣言のキーは残す。
    mutableSettings = true;

    settings = {
      theme = "dark";
      autoUpdates = false;
      # Co-author表記はプロジェクトごとに明示的に有効化する。
      attribution = {
        commit = "";
        pr = "";
        # web/Remote Control セッションで付与される Claude-Session トレーラを抑止する。
        sessionUrl = false;
      };
      outputStyle = "Explanatory";
      # 共有 AGENTS.md の「日本語で話す」は他エージェント向けにも残し、
      # Claude Code では設定でも応答言語を固定する。
      language = "japanese";
      # alt-screen 描画でちらつきを抑える。
      tui = "fullscreen";
      # 離席中もスマホから続きを操作できるよう、毎セッション Remote Control に繋ぐ。
      remoteControlAtStartup = true;
      model = "opus";
      # modelSettings.effortLevel に既定を表す値は無い。キーを置かないと
      # モデル自身の既定になり、いまの opus（Opus 5.5）は medium で始まる。
      # ユーザー設定の effortLevel は Opus 5.5 以降には効かない。
      fastMode = false;
      # 1M 窓（Opus 4.7 以降、いまの opus）は既定だと約 967K まで待ってから圧縮する。
      # 50 万トークンで要約し、長いセッションが窓の後半まで膨らまないようにする。
      # 環境変数 CLAUDE_CODE_AUTO_COMPACT_WINDOW を置くと、こちらのキーも
      # /autocompact も上書きされる。
      autoCompactWindow = 500000;
      # ローカルのセッション履歴を ccusage などで長期間集計できるよう保持する（100年分）。
      cleanupPeriodDays = 36500;
      # AskUserQuestion(選択肢プロンプト)の自動タイムアウト。
      # settings キーの askUserQuestionTimeout は 60s/5m/10m/never の固定値のみ（最大10分）なので、
      # 1時間にするには env の CLAUDE_AFK_TIMEOUT_MS（ミリ秒）を使う。要 v2.1.198+。
      env = {
        CLAUDE_AFK_TIMEOUT_MS = "3600000";
        # サブエージェントのモデルはここだけを正にする。変数だけだと
        # 定義の model や起動時の指定が勝ち、Explore と Plan は親のままになる。
        CLAUDE_CODE_SUBAGENT_MODEL = "haiku";
        CLAUDE_CODE_SUBAGENT_MODEL_FORCE = "1";
      };
      # HerdrへClaude Codeのネイティブsession IDを通知し、Herdr server再起動後の
      # `claude --resume <id>` による会話復元を可能にする。
      hooks.SessionStart = [
        {
          matcher = "*";
          hooks = [
            {
              type = "command";
              command = "bash '${homeDir}/.claude/hooks/herdr-agent-state.sh' session";
              timeout = 10;
            }
          ];
        }
      ];
      # auto はユーザー設定でしか有効にならない。プロジェクト側に書くと無視される。
      permissions.defaultMode = "auto";
      autoMode = import ../data/claude-auto-mode.nix;
      enabledPlugins = {
        "rust-analyzer-lsp@claude-plugins-official" = true;
        "gopls-lsp@claude-plugins-official" = true;
        "pyright-lsp@claude-plugins-official" = true;
        "typescript-lsp@claude-plugins-official" = true;
      };
      statusLine = {
        type = "command";
        command = "${pkgs.llm-agents.ccstatusline}/bin/ccstatusline";
        refreshInterval = 5;
        padding = 0;
      };
    };

    # 共有定義（../data/mcp-servers.nix）に Claude 固有の type = "stdio" を付与。
    mcpServers = lib.mapAttrs (_name: server: { type = "stdio"; } // server) sharedMcpServers;

    # OpenAI 公式の Codex プラグイン (/codex:review, /codex:rescue など)。
    # Codex 連携はこれに一本化し、codex mcp-server は使わない。
    # マーケットプレイス経由ではなく flake input で固定し、リポジトリ内の
    # plugins/codex をそのまま読ませる。
    plugins.codex = "${inputs.codex-plugin-cc}/plugins/codex";

  };

  # mutableSettings は Nix store を指す symlink を拒否する。以前の世代が作った
  # symlink を実ファイルへ移行してから、モジュールのマージを走らせる。
  # 併せて、以前の設定が書き戻した allow リストを削除する。宣言を消すだけでは
  # マージが既存の allow を保持してしまうため。
  home.activation.migrateClaudeSettings = lib.mkIf config.programs.claude-code.mutableSettings (
    lib.hm.dag.entryBetween [ "claudeCodeSettings" ] [ "linkGeneration" ] ''
      settings="$HOME/.claude/settings.json"
      if [[ -L "$settings" ]]; then
        target="$(${pkgs.coreutils}/bin/readlink -f -- "$settings")"
        case "$target" in
          ${builtins.storeDir}/*)
            run ${pkgs.coreutils}/bin/rm -f "$settings"
            run ${pkgs.coreutils}/bin/install -m 600 "$target" "$settings"
            ;;
        esac
      fi

      if [[ -f "$settings" ]]; then
        tmp="$(${pkgs.coreutils}/bin/mktemp)"
        if ${pkgs.jq}/bin/jq 'del(.permissions.allow) | del(.autoMode.allow)' "$settings" > "$tmp"; then
          run ${pkgs.coreutils}/bin/install -m 600 "$tmp" "$settings"
        else
          warnEcho "Could not remove allow lists from $settings"
        fi
        rm -f "$tmp"
      fi
    ''
  );

  # 上流のスキーマに追従できているかを確認する。スキーマ取得に失敗しても
  # switch は止めない。--no-cache は Last-Modified のないスキーマで古い定義を
  # 掴み続けるのを避けるため。
  home.activation.validateClaudeSettings = lib.hm.dag.entryAfter [ "claudeCodeSettings" ] ''
    settings="$HOME/.claude/settings.json"
    if [[ -f "$settings" ]]; then
      schema="$(${pkgs.jq}/bin/jq -r '.["$schema"] // empty' "$settings")"
      if [[ -n "$schema" ]]; then
        if ! ${pkgs.check-jsonschema}/bin/check-jsonschema --no-cache --schemafile "$schema" "$settings" >/dev/null 2>&1; then
          warnEcho "Claude Code settings.json did not validate against $schema"
        fi
      fi
    fi
  '';

}
