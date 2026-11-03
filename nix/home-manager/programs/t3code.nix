{
  config,
  lib,
  pkgs,
  ...
}:
let
  t3code = pkgs.llm-agents.t3code;
  settingsDir = "${config.home.homeDirectory}/.t3/userdata";

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

    # t3 のラッパーは同梱のエージェントを PATH の先頭に置くので、名前で探させると
    # OpenCode は同梱の v1 になり、v2 が変換したデータベースを読めずに失敗する。
    # dotfiles で入れたものを実行ファイルのパスで指定する。driver が欠けた
    # インスタンスがあると settings.json 全体が読み込まれないので、必ず書く。
    #
    # displayName も省かない。解決済みのバイナリパスがラベルとして保存され、
    # UI に /nix/store/... が出たままマージで残る。
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
          # agy (antigravity-cli) は ACP の実行ファイルではないので使えない。
          # ランタイムは T3 Code の設定画面から入れ、Google でサインインする。
          antigravity = {
            displayName = "Antigravity";
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
  settingsFile = pkgs.writeText "t3code-settings.json" (builtins.toJSON settings);
in
{
  # t3 connect / t3 pair をシェルから使うため、CLI も入れる。
  # デスクトップアプリは別 output なので、これで GUI が二重に入ることはない。
  home.packages = [ t3code ];

  # T3 Code は設定画面から settings.json を丸ごと書き換えるので、リンクにせず
  # 上のキーだけを上書きする。サーバーは設定ディレクトリを監視しているので、
  # 再起動しなくても読み直す。デスクトップアプリも同じ場所を読む。
  #
  # マージは上書きと追加だけで、宣言から消したキーは既存ファイルに残る。
  # プロバイダーを廃止したときは、各環境の settings.json から手で消すこと。
  home.activation.configureT3codeSettings = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    umask 077
    settings_dir=${lib.escapeShellArg settingsDir}
    settings_file="$settings_dir/settings.json"
    run mkdir -p "$settings_dir"

    if [ -f "$settings_file" ]; then
      tmp="$(${pkgs.coreutils}/bin/mktemp "$settings_dir/.settings.json.XXXXXX")"
      if ! ${lib.getExe pkgs.jq} -s '.[0] * .[1]' "$settings_file" ${settingsFile} > "$tmp"; then
        rm -f "$tmp"
        exit 1
      fi
      chmod 600 "$tmp"
      run mv "$tmp" "$settings_file"
    else
      run ${lib.getExe pkgs.jq} . ${settingsFile} > "$settings_file"
    fi
  '';
}
