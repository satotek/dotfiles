{
  config,
  lib,
  pkgs,
  ...
}:
let
  homeDir = config.home.homeDirectory;
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
    trust_level = "trusted";
    web_search = "live";

    analytics.enabled = false;
    feedback.enabled = false;

    tui.status_line = [
      "model-with-reasoning"
      "project-root"
      "context-remaining"
      "git-branch"
      "five-hour-limit"
      "weekly-limit"
    ];

    # model setting
    model = "gpt-5.5";
    model_reasoning_effort = "medium";
    model_reasoning_summary = "auto";
    model_verbosity = "medium";
    service_tier = "fast";

    approval_policy = "on-request";
    features.guardian_approval = true;
    sandbox_mode = "workspace-write";
    sandbox_workspace_write.writable_roots = [
      "/tmp"
      "/var/cache"
    ];
    sandbox_workspace_write.network_access = true;

    # 共有 MCP サーバー定義（Claude Code と共通: ../data/mcp-servers.nix）。
    # TOML では [mcp_servers.<name>] テーブルとして出力される。
    mcp_servers = import ../data/mcp-servers.nix;

    plugins = {
      "computer-use@openai-bundled".enabled = false;
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

  home.activation.generateCodexConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    codex_dir="${homeDir}/.codex"
    output="$codex_dir/config.toml"

    mkdir -p "$codex_dir"
    if [ -L "$output" ]; then
      rm -f "$output"
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
  '';
}
