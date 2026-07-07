{
  config,
  pkgs,
  lib,
  ...
}:
let
  homeDir = config.home.homeDirectory;
  context7ApiKeyFile = "${homeDir}/.config/context7/api-key";
  sharedMcpServers = import ../data/mcp-servers.nix {
    inherit context7ApiKeyFile;
  };
  claudeStatuslineLine3 = pkgs.writeShellApplication {
    name = "claude-statusline-line3";
    runtimeInputs = [ pkgs.jq ];
    text = ''
      jq -r 'def bar(pct):(pct*10/100|floor) as $f|(10-$f) as $e|([range($f)]|map("█")|join(""))+([range($e)]|map("░")|join("")); (.rate_limits.five_hour.resets_at // 0) as $resets | (if ($resets > 0) and (($resets - now) > 0) then ($resets - now | floor) as $d | " (+" + ($d/3600|floor|tostring) + "h" + ($d%3600/60|floor|tostring) + "m)" else "" end) as $rt | "5h " + bar(.rate_limits.five_hour.used_percentage // 0) + " " + (.rate_limits.five_hour.used_percentage // 0 | floor | tostring) + "%" + $rt + " | 7d " + bar(.rate_limits.seven_day.used_percentage // 0) + " " + (.rate_limits.seven_day.used_percentage // 0 | floor | tostring) + "% | $" + (.cost.total_cost_usd // 0 | . * 100 | round | . / 100 | tostring)'
    '';
  };

  # ccstatusline の行構成。1行目=モデル/コンテキスト/git、3行目=レート上限バー+コスト。
  # commandPath は nix store の絶対パスにして全ホスト(azureuser 含む)で有効にする。
  # 空の 2 行目は ccstatusline が畳むため、実表示は 2 行になる。
  ccstatuslineSettings = {
    version = 3;
    lines = [
      [
        {
          id = "1";
          type = "model";
          color = "cyan";
        }
        {
          id = "2";
          type = "separator";
        }
        {
          id = "3";
          type = "context-length";
          color = "brightBlack";
        }
        {
          id = "4";
          type = "separator";
        }
        {
          id = "5";
          type = "git-branch";
          color = "magenta";
        }
        {
          id = "6";
          type = "separator";
        }
        {
          id = "7";
          type = "git-changes";
          color = "yellow";
        }
      ]
      [ ]
      [
        {
          id = "8";
          type = "custom-command";
          commandPath = "${claudeStatuslineLine3}/bin/claude-statusline-line3";
          preserveColors = true;
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
  home.file.".local/bin/claude-statusline-line3" = {
    source = "${claudeStatuslineLine3}/bin/claude-statusline-line3";
    executable = true;
  };

  # ccstatusline 設定を home-manager 管理下に（スクリプトと配線をセットで再現可能にする）。
  home.file.".config/ccstatusline/settings.json".text = builtins.toJSON ccstatuslineSettings;

  # statusLine.command は nix store の絶対パス参照なので PATH には入らない。
  # 設定 TUI（ccstatusline コマンド）を手動起動できるよう PATH にも追加する。
  home.packages = [ pkgs.llm-agents.ccstatusline ];

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
      fastMode = false;
      # AskUserQuestion(選択肢プロンプト)の自動タイムアウト。
      # settings キーの askUserQuestionTimeout は 60s/5m/10m/never の固定値のみ（最大10分）なので、
      # 1時間にするには env の CLAUDE_AFK_TIMEOUT_MS（ミリ秒）を使う。要 v2.1.198+。
      env = {
        CLAUDE_AFK_TIMEOUT_MS = "3600000";
      };
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
        "frontend-design@claude-plugins-official" = true;
      };
      statusLine = {
        type = "command";
        command = "${pkgs.llm-agents.ccstatusline}/bin/ccstatusline";
        refreshInterval = 5;
        padding = 0;
      };
    };

    # 共有定義（../data/mcp-servers.nix）に Claude 固有の type = "stdio" を付与。
    # Codex は Claude Code から専門エージェントとして呼ぶため、Claude 専用に追加する。
    mcpServers = (lib.mapAttrs (_name: server: { type = "stdio"; } // server) sharedMcpServers) // {
      codex = {
        type = "stdio";
        command = "codex";
        args = [ "mcp-server" ];
      };
    };

  };
}
