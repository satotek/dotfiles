# 共有 MCP サーバー定義（純データ）。
# Claude Code (settings.json の mcpServers) と Codex (config.toml の [mcp_servers])
# の両方からこの 1 ファイルを import して使う。
# ここには起動方法（command / args）だけを書き、エージェント固有の項目
# （Claude の type = "stdio" など）は各 import 側で付与する。
{
  context7 = {
    command = "npx";
    args = [
      "-y"
      "@upstash/context7-mcp"
    ];
  };

  playwright = {
    command = "npx";
    args = [
      "-y"
      "@playwright/mcp@latest"
    ];
  };

  chrome-devtools = {
    command = "npx";
    args = [
      "-y"
      "chrome-devtools-mcp@latest"
      # ヘッドレスサーバ（X server なし）で動かすため headless 必須。
      "--headless=true"
      # セッション毎に使い捨てプロファイルを使い、共有プロファイルの
      # SingletonLock 堆積で "Target closed" になる事故を防ぐ。
      "--isolated=true"
    ];
  };
}
