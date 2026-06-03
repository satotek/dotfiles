{ pkgs, lib, ... }:
let
  sharedMcpServers = import ../data/mcp-servers.nix;
  claudeStatuslineLine3 = pkgs.writeShellApplication {
    name = "claude-statusline-line3";
    runtimeInputs = [ pkgs.jq ];
    text = ''
      /usr/bin/jq -r 'def bar(pct):(pct*10/100|floor) as $f|(10-$f) as $e|([range($f)]|map("█")|join(""))+([range($e)]|map("░")|join("")); (.rate_limits.five_hour.resets_at // 0) as $resets | (if ($resets > 0) and (($resets - now) > 0) then ($resets - now | floor) as $d | " (+" + ($d/3600|floor|tostring) + "h" + ($d%3600/60|floor|tostring) + "m)" else "" end) as $rt | "5h " + bar(.rate_limits.five_hour.used_percentage // 0) + " " + (.rate_limits.five_hour.used_percentage // 0 | floor | tostring) + "%" + $rt + " | 7d " + bar(.rate_limits.seven_day.used_percentage // 0) + " " + (.rate_limits.seven_day.used_percentage // 0 | floor | tostring) + "% | $" + (.cost.total_cost_usd // 0 | . * 100 | round | . / 100 | tostring)'
    '';
  };
in
{
  home.file.".local/bin/claude-statusline-line3" = {
    source = "${claudeStatuslineLine3}/bin/claude-statusline-line3";
    executable = true;
  };

  programs.claude-code = {
    enable = true;
    package = pkgs.llm-agents.claude-code;

    settings = {
      theme = "dark";
      autoUpdates = false;
      includeCoAuthoredBy = false;
      outputStyle = "Explanatory";
      model = "claude-opus-4-8";
      effortLevel = "high";
      fastMode = true;
      permissions.allow = [
        "Bash(pnpm typecheck)"
        "Bash(pnpm test)"
        "Bash(pnpm lint)"
        "Bash(pnpm test:storybook)"
        "mcp__plugin_claude-code-home-manager_playwright__browser_take_screenshot"
        "mcp__plugin_claude-code-home-manager_playwright__browser_snapshot"
        "mcp__plugin_claude-code-home-manager_context7__query-docs"
        "mcp__plugin_claude-code-home-manager_context7__resolve-library-id"
        # chrome-devtools: 読み取り・検査系のみ許可（遷移/クリック/JS実行など副作用系は都度確認）
        "mcp__plugin_claude-code-home-manager_chrome-devtools__take_snapshot"
        "mcp__plugin_claude-code-home-manager_chrome-devtools__take_screenshot"
        "mcp__plugin_claude-code-home-manager_chrome-devtools__list_pages"
        "mcp__plugin_claude-code-home-manager_chrome-devtools__list_console_messages"
        "mcp__plugin_claude-code-home-manager_chrome-devtools__get_console_message"
        "mcp__plugin_claude-code-home-manager_chrome-devtools__list_network_requests"
        "mcp__plugin_claude-code-home-manager_chrome-devtools__get_network_request"
        "mcp__plugin_claude-code-home-manager_chrome-devtools__performance_analyze_insight"
      ];
      enabledPlugins = {
        "rust-analyzer-lsp@claude-plugins-official" = true;
        "gopls-lsp@claude-plugins-official" = true;
        "pyright-lsp@claude-plugins-official" = true;
        "typescript-lsp@claude-plugins-official" = true;
      };
      statusLine = {
        type = "command";
        command = "${pkgs.bun}/bin/bunx ccstatusline@latest";
        refreshInterval = 5;
        padding = 0;
      };
    };

    # 共有定義（../data/mcp-servers.nix）に Claude 固有の type = "stdio" を付与。
    mcpServers = lib.mapAttrs (_name: server: { type = "stdio"; } // server) sharedMcpServers;

  };
}
