{
  config,
  lib,
  pkgs,
  ...
}:
let
  homeDir = config.home.homeDirectory;
  sharedMcpServers = import ../data/mcp-servers.nix {
    inherit pkgs;
    isLinux = pkgs.stdenv.hostPlatform.isLinux;
  };
  trustedProjectRoots = [
    "${homeDir}/ghq"
    "${homeDir}/workspaces"
  ];
  extraTrustedProjects = [
    "${homeDir}/dotfiles"
  ];
  codexConfig = {
    personality = "friendly";
    web_search = "live";

    analytics.enabled = false;
    feedback.enabled = false;

    desktop = {
      followUpQueueMode = "queue";
      defaultTerminalLocation = "right";
      "show-context-window-usage" = true;
      appearanceDarkCodeThemeId = "catppuccin";
      appearanceLightCodeThemeId = "catppuccin";
      appearanceTheme = "system";
      "git-branch-prefix" = "codex/";

      open-in-target-preferences.global = "vscodeInsiders";

      appearanceDarkChromeTheme = {
        accent = "#cba6f7";
        contrast = 85;
        ink = "#cdd6f4";
        opaqueWindows = false;
        surface = "#1e1e2e";
        fonts = {
          code = "Moralerspace Neon";
          ui = "Moralerspace Neon";
        };
        semanticColors = {
          diffAdded = "#a6e3a1";
          diffRemoved = "#f38ba8";
          skill = "#cba6f7";
        };
      };

      appearanceLightChromeTheme = {
        accent = "#8839ef";
        contrast = 45;
        ink = "#4c4f69";
        opaqueWindows = false;
        surface = "#eff1f5";
        fonts = {
          code = "Moralerspace Neon";
          ui = "Moralerspace Neon";
        };
        semanticColors = {
          diffAdded = "#40a02b";
          diffRemoved = "#d20f39";
          skill = "#8839ef";
        };
      };
    };

    tui.status_line = [
      "model-with-reasoning"
      "context-used"
      "five-hour-limit"
      "weekly-limit"
      "git-branch"
    ];
    tui.status_line_use_colors = true;
    tui.alternate_screen = "never";

    # model setting
    model = "gpt-6-luna";
    model_reasoning_effort = "xhigh";
    model_reasoning_summary = "auto";
    model_verbosity = "medium";
    service_tier = "default";

    approval_policy = "on-request";
    approvals_reviewer = "auto_review";
    features.guardian_approval = true;
    # Herdr integration hookをCodexで有効化する。
    features.hooks = true;
    features.memories = true;
    features.js_repl = false;
    sandbox_mode = "workspace-write";
    sandbox_workspace_write.writable_roots = [
      "/tmp"
    ];
    sandbox_workspace_write.network_access = true;

    # 共有 MCP サーバー定義（Claude Code と共通: ../data/mcp-servers.nix）。
    # TOML では [mcp_servers.<name>] テーブルとして出力される。
    # agent-browser は Codex の shell sandbox から CLI を直接起動せず、MCP 経由で使う。
    mcp_servers =
      sharedMcpServers
      // {
        "agent-browser" = {
          command = "agent-browser";
          args = [ "mcp" ];
          env = {
            AGENT_BROWSER_SOCKET_DIR = "/tmp/agent-browser";
          };
        };
      }
      // lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
        # Xcode 26.3+ の組み込みMCP bridge。macOSのCodexにだけ生成する。
        # Xcode > Settings > Intelligence > Model Context Protocol で
        # "Allow external agents to use Xcode tools" を有効にし、プロジェクトを
        # Xcodeで開いた状態で利用する。
        xcode = {
          command = "/usr/bin/xcrun";
          args = [ "mcpbridge" ];
        };
      };

    plugins = {
      "computer-use@openai-bundled".enabled = true;
      "sites@openai-bundled".enabled = true;
      "visualize@openai-bundled".enabled = true;
      "browser@openai-bundled".enabled = true;
      "chrome@openai-bundled".enabled = true;
      "github@openai-curated".enabled = true;
      "gmail@openai-curated".enabled = true;
      "google-calendar@openai-curated".enabled = true;
      "google-drive@openai-curated".enabled = true;
    };
  };
  trustedProjectRootsScript = lib.concatMapStringsSep " " (
    root: lib.escapeShellArg root
  ) trustedProjectRoots;
  extraTrustedProjectsScript = lib.concatMapStringsSep " " (
    project: lib.escapeShellArg project
  ) extraTrustedProjects;
in
{
  programs.codex = {
    enable = true;
    # llm-agents の libexec/codex が codex-package.json を含む完全パッケージ。
    # daemon はその store パスを current として参照する。
    package = pkgs.llm-agents.codex;

    # Codex は config.toml に [projects] や [hooks.state] を書き戻す。
    # 宣言した値だけを activation でマージし、実行時の状態は残す。
    mutableSettings = true;
    settings = codexConfig;
  };

  home.file.".codex/rules/default.rules".force = true;

  home.file.".codex/rules/default.rules".text = ''
    # コマンド個別の allow は置かない。承認は auto_review に任せる。
    # Keep operations that publish, rewrite history, or discard work interactive.
    prefix_rule(pattern = ["git", "commit"], decision = "prompt")
    prefix_rule(pattern = ["git", "push"], decision = "prompt")
    prefix_rule(pattern = ["git", "reset"], decision = "prompt")
    prefix_rule(pattern = ["git", "rebase"], decision = "prompt")
    prefix_rule(pattern = ["git", "restore"], decision = "prompt")
    prefix_rule(pattern = ["git", "checkout"], decision = "prompt")
    prefix_rule(pattern = ["git", "clean"], decision = "prompt")
    prefix_rule(pattern = ["git", "merge"], decision = "prompt")
    prefix_rule(pattern = ["rm"], decision = "prompt")
    prefix_rule(pattern = ["sudo"], decision = "prompt")
  '';

  # HerdrへCodexのネイティブsession IDを通知し、Herdr server再起動後の
  # `codex resume <id>` による会話復元を可能にする。
  home.file.".codex/hooks.json".text = builtins.toJSON {
    hooks.SessionStart = [
      {
        hooks = [
          {
            type = "command";
            command = "bash '${homeDir}/.codex/herdr-agent-state.sh' session";
            timeout = 10;
          }
        ];
      }
    ];
  };

  # mutableSettings は Nix store を指す symlink を拒否する。以前の世代が作った
  # symlink を実ファイルへ移行してから、モジュールのマージを走らせる。
  home.activation.migrateCodexConfig = lib.mkIf config.programs.codex.mutableSettings (
    lib.hm.dag.entryBetween [ "codexMutableSettings" ] [ "linkGeneration" ] ''
      config="${homeDir}/.codex/config.toml"
      if [[ -L "$config" ]]; then
        target="$(${pkgs.coreutils}/bin/readlink -f -- "$config")"
        case "$target" in
          ${builtins.storeDir}/*)
            run ${pkgs.coreutils}/bin/rm -f "$config"
            run ${pkgs.coreutils}/bin/install -m 600 "$target" "$config"
            ;;
        esac
      fi
    ''
  );

  # mutableSettings は実行時の [projects] を保持する。新しく見つけたリポジトリ
  # だけを追記し、既存の trust 状態は上書きしない。
  home.activation.addCodexTrustedProjects = lib.mkIf config.programs.codex.mutableSettings (
    lib.hm.dag.entryAfter [ "codexMutableSettings" ] ''
      (
        output="${homeDir}/.codex/config.toml"
        [ -f "$output" ] || exit 0

        append_trusted_project() {
          project="$1"
          [ -d "$project" ] || return 0

          case "$project" in
            *\"*|*\\*)
              echo "WARNING: skipping project path unsafe for TOML quoted keys: $project" >&2
              return 0
              ;;
          esac

          project="''${project%/}"
          if ${pkgs.gnugrep}/bin/grep -Fq "[projects.\"$project\"]" "$output"; then
            return 0
          fi

          printf '\n[projects."%s"]\ntrust_level = "trusted"\n' "$project" >> "$output"
        }

        for root in ${trustedProjectRootsScript}; do
          [ -d "$root" ] || continue

          ${pkgs.fd}/bin/fd --type d --hidden --no-ignore "^\\.git$" "$root" --max-depth 5 2>/dev/null \
            | sort \
            | while IFS= read -r gitdir; do
                append_trusted_project "$(dirname "$gitdir")"
              done
        done

        for project in ${extraTrustedProjectsScript}; do
          append_trusted_project "$project"
        done
      )
    ''
  );

  # ChatGPTデスクトップアプリのペット表示は config.toml ではなく、
  # Codex のグローバル状態ファイルに保存される。アップデートで表示状態が
  # 戻っても、Home Manager の切り替え時に非表示を再適用する。
  home.activation.disableCodexPet = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin (
    lib.hm.dag.entryAfter [ "addCodexTrustedProjects" ] ''
      codex_global_state="${homeDir}/.codex/.codex-global-state.json"

      if [ -f "$codex_global_state" ] && ! ${pkgs.jq}/bin/jq -e \
        '."electron-avatar-overlay-open" == false' \
        "$codex_global_state" >/dev/null 2>&1; then
        codex_global_state_tmp="$(mktemp "''${codex_global_state}.tmp.XXXXXX")"
        if ${pkgs.jq}/bin/jq -c \
          '."electron-avatar-overlay-open" = false' \
          "$codex_global_state" > "$codex_global_state_tmp"; then
          mv -f "$codex_global_state_tmp" "$codex_global_state"
        else
          rm -f "$codex_global_state_tmp"
          echo "WARNING: could not update $codex_global_state" >&2
        fi
      fi
    ''
  );
}
