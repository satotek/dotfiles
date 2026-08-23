{
  config,
  lib,
  pkgs,
  ...
}:
let
  homeDir = config.home.homeDirectory;
  context7ApiKeyFile = "${homeDir}/.config/context7/api-key";
  sharedMcpServers = import ../data/mcp-servers.nix {
    inherit context7ApiKeyFile;
  };
  trustedProjectRoots = [
    "${homeDir}/ghq"
    "${homeDir}/workspaces"
  ];
  extraTrustedProjects = [
    "${homeDir}/dotfiles"
  ];
  tomlFormat = pkgs.formats.toml { };
  codexConfig = {
    personality = "friendly";
    network_access = true;
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
    model = "gpt-5.6-sol";
    model_reasoning_effort = "medium";
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
    mcp_servers = sharedMcpServers // {
      "agent-browser" = {
        command = "agent-browser";
        args = [ "mcp" ];
        env = {
          AGENT_BROWSER_SOCKET_DIR = "/tmp/agent-browser";
        };
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
  baseConfigFile = tomlFormat.generate "codex-config-base.toml" codexConfig;
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
    package = pkgs.llm-agents.codex;
  };

  home.file.".codex/rules/default.rules".force = true;

  home.file.".codex/rules/default.rules".text = ''
    # Allow low-risk inspection commands outside the sandbox without prompting.
    prefix_rule(pattern = ["git", "diff"], decision = "allow")
    prefix_rule(pattern = ["git", "status"], decision = "allow")
    prefix_rule(pattern = ["git", "log"], decision = "allow")
    prefix_rule(pattern = ["git", "show"], decision = "allow")
    prefix_rule(pattern = ["git", "branch"], decision = "allow")
    prefix_rule(pattern = ["git", "rev-parse"], decision = "allow")
    prefix_rule(pattern = ["git", "remote", "-v"], decision = "allow")
    prefix_rule(pattern = ["git", "ls-files"], decision = "allow")
    prefix_rule(pattern = ["git", "for-each-ref"], decision = "allow")
    prefix_rule(pattern = ["git", "cherry", "-v"], decision = "allow")
    prefix_rule(pattern = ["git", "add"], decision = "allow")

    prefix_rule(pattern = ["rg"], decision = "allow")
    prefix_rule(pattern = ["sed", "-n"], decision = "allow")
    prefix_rule(pattern = ["ls"], decision = "allow")
    prefix_rule(pattern = ["pwd"], decision = "allow")
    prefix_rule(pattern = ["wc"], decision = "allow")
    prefix_rule(pattern = ["head"], decision = "allow")
    prefix_rule(pattern = ["tail"], decision = "allow")
    prefix_rule(pattern = ["sort"], decision = "allow")
    prefix_rule(pattern = ["readlink", "-f"], decision = "allow")
    prefix_rule(pattern = ["which"], decision = "allow")
    prefix_rule(pattern = ["date"], decision = "allow")
    prefix_rule(pattern = ["nix-instantiate", "--parse"], decision = "allow")

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

  home.activation.generateCodexConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    codex_dir="${homeDir}/.codex"
    output="$codex_dir/config.toml"
    hooks_state_file="$(mktemp)"

    mkdir -p "$codex_dir"
    if [ -L "$output" ]; then
      rm -f "$output"
    fi

    if [ -f "$output" ]; then
      ${pkgs.gawk}/bin/awk '
        /^\[hooks\.state\]/ { keep = 1 }
        keep { print }
      ' "$output" > "$hooks_state_file"
    fi

    cp -f ${lib.escapeShellArg baseConfigFile} "$output"
    chmod 644 "$output"

    append_trusted_project() {
      project="$1"
      [ -d "$project" ] || return 0

      case "$project" in
        *\"*|*\\*)
          echo "WARNING: skipping project path unsafe for TOML quoted keys: $project" >&2
          return 0
          ;;
      esac

      printf '\n[projects."%s"]\ntrust_level = "trusted"\n' "''${project%/}" >> "$output"
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

    if [ -s "$hooks_state_file" ]; then
      # Codexは実行時に [projects."..."] などを config.toml の末尾（= [hooks.state] より
      # 後ろ）へ書き足すため、保存した尻尾をそのまま復元すると上で生成済みのテーブルと
      # 衝突し、TOMLのduplicate keyでconfig全体が読めなくなる。既に出力済みの見出しと、
      # 尻尾の中で重複する見出しを落としてから復元する（宣言側の定義を優先）。
      filtered_state_file="$(mktemp)"
      ${pkgs.gawk}/bin/awk '
        NR == FNR {
          if ($0 ~ /^\[/) seen[$0] = 1
          next
        }
        /^\[/ {
          skip = ($0 in seen)
          seen[$0] = 1
        }
        !skip
      ' "$output" "$hooks_state_file" > "$filtered_state_file"

      if [ -s "$filtered_state_file" ]; then
        printf '\n' >> "$output"
        cat "$filtered_state_file" >> "$output"
      fi
      rm -f "$filtered_state_file"
    fi
    rm -f "$hooks_state_file"
  '';
}
