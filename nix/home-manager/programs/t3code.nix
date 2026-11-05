{
  lib,
  pkgs,
  ...
}:
let
  # 同梱 provider は llm-agents の別バージョンで、特に OpenCode は v1 なので、
  # PATH 経由で起動すると v2 が変換したデータベースを読めずに失敗する。
  # 実行ファイルは下の binaryPath で明示するため、同梱は丸ごと外す。
  t3code = pkgs.llm-agents.t3code.override { providerPackages = [ ]; };

  # T3 の Antigravity プロバイダは公式の ACP ランタイム（agy_acp_server.par と
  # 同じディレクトリの localharness_external）を期待する。agy CLI は 1.4 以降
  # `agy acp` を持つので、337 MB のランタイムを別途入れずにそれを包む。
  # T3 は Linux で --uid= を渡すため、引数は捨てる。
  antigravityAcp = pkgs.runCommand "antigravity-acp" { } ''
    mkdir -p $out/bin
    printf '%s\n' '#!/bin/sh' 'exec ${pkgs.llm-agents.antigravity-cli}/bin/agy acp' > $out/bin/agy_acp_server.par
    chmod +x $out/bin/agy_acp_server.par
    printf '#!/bin/sh\nexit 0\n' > $out/bin/localharness_external
    chmod +x $out/bin/localharness_external
  '';

  settings = {
    defaultModelSelection = {
      instanceId = "claudeAgent";
      model = "claude-opus-5-5";
      options = [
        {
          id = "effort";
          value = "medium";
        }
      ];
    };
    defaultRuntimeMode = "auto";

    # エージェントのバージョンは llm-agents で揃えるので、更新の通知は要らない。
    enableProviderUpdateChecks = false;

    # driver が欠けたインスタンスがあると settings.json 全体が読み込まれないので、
    # 必ず書く。displayName も省かない。解決済みのバイナリパスがラベルとして
    # 保存され、UI に /nix/store/... が出たままマージで残る。
    providerInstances =
      lib.mapAttrs
        (
          driver: instance:
          {
            inherit driver;
            enabled = true;
          }
          // instance
        )
        {
          claudeAgent = {
            displayName = "Claude";
            config.binaryPath = lib.getExe pkgs.llm-agents.claude-code;
          };
          codex = {
            displayName = "Codex";
            config.binaryPath = lib.getExe pkgs.llm-agents.codex;
          };
          # grok の agent と名前が衝突するので、cursor-agent をパスで指定する。
          cursor = {
            displayName = "Cursor";
            config.binaryPath = lib.getExe pkgs.llm-agents.cursor-agent;
          };
          grok = {
            displayName = "Grok";
            config.binaryPath = lib.getExe pkgs.llm-agents.grok;
          };
          opencode = {
            displayName = "OpenCode";
            config.binaryPath = "${pkgs.llm-agents.opencode2}/bin/opencode2";
          };
          # T3 の Antigravity は公式 ACP ランタイムを要求する。agy CLI の acp を
          # 包んだ実行ファイルを指定し、337 MB のランタイム取得を避ける。
          antigravity = {
            displayName = "Antigravity";
            config.binaryPath = "${antigravityAcp}/bin/agy_acp_server.par";
          };
        }
      // {
        # dsh は ACP の local コマンドとして登録する。キーは T3 Code の
        # 設定画面が生成する acpRegistry の ID に合わせる。
        acpRegistry_local_acp = {
          driver = "acpRegistry";
          displayName = "Deepseek Harness";
          accentColor = "#4d6bfe";
          enabled = true;
          config = {
            source = "local";
            commandPath = "${pkgs.llm-agents.dsh}/bin/dsh";
            commandArgs = [
              "--profile"
              "acp"
            ];
          };
        };
      };
  };
in
{
  # 設定は Home Manager のモジュールが、アプリが書き戻したキーを残したまま
  # マージする。CLI の t3 もモジュールが入れる。
  programs.t3code = {
    enable = true;
    package = t3code;
    mutableUserSettings = true;
    userSettings = settings;
  };
}
