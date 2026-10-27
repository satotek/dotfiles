{
  config,
  lib,
  pkgs,
  ...
}:
let
  secretsDir = "${config.home.homeDirectory}/.config/opencode/secrets";

  sharedMcpServers = import ../data/mcp-servers.nix {
    inherit pkgs;
    isLinux = pkgs.stdenv.hostPlatform.isLinux;
  };

  # 組み込み provider に apiKey だけを足す。"!" 始まりはリクエスト時にシェルで
  # 実行され、stdout が鍵になる。環境変数に載せないので子プロセスへ漏れない。
  # models.yml の鍵は /login で保存した鍵より優先される。
  modelsConfig = {
    providers =
      lib.recursiveUpdate
        (lib.genAttrs [ "deepseek" "google" "opencode-go" "commandcode" ] (name: {
          apiKey = "!tr -d '\\n\\r' < \"${secretsDir}/${name}.key\"";
        }))
        {
          # ZDR（保持・学習なし）を全リクエストで要求する。ZDR 対応 upstream が
          # ないモデルは 422 (cmd_zdr_no_providers) で失敗する。
          commandcode.headers."x-cmd-zdr" = "1";
        };
  };

  mcpConfig = {
    "$schema" =
      "https://raw.githubusercontent.com/can1357/oh-my-pi/main/packages/coding-agent/src/config/mcp-schema.json";
    mcpServers = lib.mapAttrs (_name: server: {
      type = "stdio";
      command = server.command;
      args = server.args or [ ];
    }) sharedMcpServers;
  };

  # modelRoles は models.yml ではなく config.yml に置く。
  settingsFile = pkgs.writers.writeJSON "omp-config.json" {
    modelRoles.default = "opencode-go/deepseek-v4.1-flash";
    # 同梱の reviewer サブエージェントは @slow を使い、advisor も未指定なら slow に従う。
    # smol などは裏で頻繁に動くので default と同じ安いモデルのまま。
    modelRoles.slow = "openai-codex/gpt-6.1-sol";
    modelRoles.plan = "@slow";
    # 会話モデルの provider に検索機能があればそれを使う。無い provider
    # （deepseek / opencode-go / commandcode）は既定の順（parallel 以降）に落ちる。
    modelRoles.web = "web/hosted";
    theme.dark = "dark-catppuccin";
    symbolPreset = "nerd";
    composer = {
      shape = "claude";
      tokenRate = true;
    };
    display.showTokenUsage = true;
    terminal.showProgress = true;
    # 鍵の形をした文字列を伏せて送り、ツール実行前に戻す。sops の鍵ファイルは
    # 環境変数ではないので、既知の形（Google の AIza… など）だけが対象になる。
    secrets.enabled = true;
    # ast-grep スキルは CLI のルール記述向け。こちらは組み込みの単純検索で、
    # 既定で有効な ast_edit と対になる。
    astGrep.enabled = true;
    # 書き込み後の診断は既定で有効。部分編集の後にも LSP の診断を返させる。
    lsp.diagnosticsOnEdit = true;
    # default プリセットに cache_hit を足したもの。custom はプリセットの
    # 部品構成も segmentOptions も引き継がないので、両方を書き写す。
    statusLine = {
      preset = "custom";
      separator = "powerline-thin";
      transparent = true;
      leftSegments = [
        "pi"
        "vim"
        "model"
        "mode"
        "collab"
        "stream"
        "path"
        "git"
        "pr"
        "context_pct"
        "cache_hit"
        "cost"
      ];
      rightSegments = [ "session_name" ];
      segmentOptions = {
        model.showThinkingLevel = true;
        path = {
          abbreviate = true;
          maxLength = 40;
          stripWorkPrefix = true;
        };
        git = {
          showBranch = true;
          showStaged = true;
          showUnstaged = true;
          showUntracked = true;
        };
      };
    };
  };
in
{
  home.packages = [ pkgs.llm-agents.omp ];

  # agent.db / sessions は omp が書き戻すため触らない。
  # mcp.json は symlink なので /mcp add などの保存は失敗する。サーバーは
  # mcp-servers.nix に足す。AGENTS.md は agents-context.nix。
  home.file.".omp/agent/models.yml".source =
    (pkgs.formats.yaml { }).generate "omp-models.yml"
      modelsConfig;
  home.file.".omp/agent/mcp.json".source = pkgs.writers.writeJSON "omp-mcp.json" mcpConfig;

  # ccusage は omp を自動検出しない。pi と同じ形式なので、名前付きの pi ストアとして
  # 足すと unified レポートに omp という別エージェントで出る。
  home.file.".claude/ccusage.json".source = pkgs.writers.writeJSON "ccusage.json" {
    "$schema" = "https://ccusage.com/config-schema.json";
    pi.stores = [
      {
        name = "omp";
        path = "~/.omp/agent/sessions";
      }
    ];
  };

  # config.yml は /settings やモデルピッカーが書き戻すので symlink にしない。
  # 宣言した値だけをマージし、テーマなど omp が書いたキーは残す。ピッカーで
  # 変えた既定モデルは次の switch で戻る。
  home.activation.configureOmpConfig = lib.hm.dag.entryAfter [ "linkGeneration" ] (
    lib.hm.generators.mkImpureConfigMerger {
      inherit pkgs;
      format = "yaml";
      empty = "{}";
      jqOperation = "$dynamic * $static";
      path = "${config.home.homeDirectory}/.omp/agent/config.yml";
      staticSettings = settingsFile;
      mode = "600";
    }
  );
}
