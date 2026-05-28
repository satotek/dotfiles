{ pkgs, ... }:
let
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
      model = "claude-opus-4-7";
      effortLevel = "medium";
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

    mcpServers = {
      context7 = {
        type = "stdio";
        command = "npx";
        args = [
          "-y"
          "@upstash/context7-mcp"
        ];
      };

      playwright = {
        type = "stdio";
        command = "npx";
        args = [
          "-y"
          "@playwright/mcp@latest"
        ];
      };
    };

  };
}
