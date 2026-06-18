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
    web_search = "live";

    analytics.enabled = false;
    feedback.enabled = false;

    tui.status_line = [
      "model-with-reasoning"
      "approval-mode"
      "project-root"
      "context-remaining"
      "git-branch"
      "five-hour-limit"
      "weekly-limit"
    ];
    tui.alternate_screen = "never";

    # model setting
    model = "gpt-5.5";
    model_reasoning_effort = "medium";
    model_reasoning_summary = "auto";
    model_verbosity = "medium";
    service_tier = "default";

    approval_policy = "on-request";
    approvals_reviewer = "auto_review";
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
