{
  context7ApiKeyFile ? null,
  # 呼び出し側から pkgs.stdenv.hostPlatform.isLinux を渡す。
  # Linux ホスト（WSL 含む）はいずれもヘッドレス運用で、接続先になる
  # デスクトップ Chrome が存在しないため一部サーバーを出し分ける。
  isLinux ? false,
}:

# 共有 MCP サーバー定義（純データ）。
# Claude Code (settings.json の mcpServers) と Codex (config.toml の [mcp_servers])
# の両方からこの 1 ファイルを import して使う。
# ここには起動方法（command / args）だけを書き、エージェント固有の項目
# （Claude の type = "stdio" など）は各 import 側で付与する。
{
  context7 = {
    command = "sh";
    args = [
      "-c"
      ''
        api_key_file="$1"
        if [ -n "$api_key_file" ] && [ -r "$api_key_file" ]; then
          api_key="$(cat "$api_key_file")"
          if [ -n "$api_key" ]; then
            export CONTEXT7_API_KEY="$api_key"
          fi
        fi

        exec bunx -y @upstash/context7-mcp
      ''
      "context7-mcp"
      (if context7ApiKeyFile == null then "" else context7ApiKeyFile)
    ];
  };

  playwright = {
    command = "bunx";
    args = [
      "-y"
      "@playwright/mcp@latest"
    ];
  };

  chrome-devtools = {
    command = "bunx";
    args = [
      "-y"
      "chrome-devtools-mcp@latest"
      # ヘッドレスサーバ（X server なし）で動かすため headless 必須。
      "--headless=true"
      # セッション毎に使い捨てプロファイルを使い、共有プロファイルの
      # SingletonLock 堆積で "Target closed" になる事故を防ぐ。
      "--isolated=true"
      # 既定で Google に利用統計が送られるため無効化する。
      "--no-usage-statistics"
    ];
  };
}
// (
  if isLinux then
    { }
  else
    {
      # 現在起動中のChromeへ接続し、ページのWebMCPツールを検証するための設定。
      # 通常のchrome-devtools（ヘッドレス・isolated）は既存用途のため残す。
      #
      # 動作には Chrome 側の準備が要る。未達でもサーバー自体は正常に起動し、
      # ツール呼び出し時に初めて失敗するので原因が分かりにくい:
      #   1. Chrome 150+ を --enable-features=WebMCP 付きで起動する
      #      (--autoConnect は 144+、--categoryExperimentalWebmcp は 150+ が要件)
      #   2. chrome://inspect/#remote-debugging でリモートデバッグサーバを有効化する
      # Chrome 144+ は従来の http://127.0.0.1:9222/json 探索を塞いでいるため、
      # --browserUrl ではなく user data dir を読む --autoConnect を使う。
      #
      # Linux では接続先のデスクトップ Chrome がいないので生成しない。
      chrome-devtools-live = {
        command = "bunx";
        args = [
          "-y"
          "chrome-devtools-mcp@latest"
          "--autoConnect"
          "--categoryExperimentalWebmcp"
          # 既定で Google に利用統計が送られるため無効化する。
          "--no-usage-statistics"
        ];
      };
    }
)
