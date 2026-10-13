{
  config,
  lib,
  pkgs,
  ...
}:
let
  t3code = pkgs.llm-agents.t3code;
  # 既定の番号にしておくと、デスクトップアプリの SSH 接続や手元のトンネルが
  # 同じ番号を前提にできる。手元でサーバーを動かすときは転送元の番号をずらす。
  port = 3773;
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

    # Claude と Codex 以外は既定で無効。
    providers =
      lib.genAttrs
        [
          "antigravity"
          "grok"
          "opencode"
        ]
        (_: {
          enabled = true;
        });

    # t3 のラッパーは同梱のエージェントを PATH の先頭に置くので、名前で探させると
    # OpenCode は同梱の v1 になり、v2 が変換したデータベースを読めずに失敗する。
    # dotfiles で入れたものを実行ファイルのパスで指定する。driver が欠けた
    # インスタンスがあると settings.json 全体が読み込まれないので、必ず書く。
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
          claudeAgent.config.binaryPath = lib.getExe pkgs.llm-agents.claude-code;
          codex.config.binaryPath = lib.getExe pkgs.llm-agents.codex;
          grok.config.binaryPath = lib.getExe pkgs.llm-agents.grok;
          opencode.config.binaryPath = "${pkgs.llm-agents.opencode2}/bin/opencode2";
          # agy (antigravity-cli) は ACP の実行ファイルではないので使えない。
          # ランタイムは T3 Code の設定画面から入れ、Google でサインインする。
          antigravity = { };
        };
  };
  settingsFile = pkgs.writeText "t3code-settings.json" (builtins.toJSON settings);
in
{
  # t3 connect / t3 pair をシェルから使うため、CLI も入れる。
  home.packages = [ t3code ];

  # T3 Code は設定画面から settings.json を丸ごと書き換えるので、リンクにせず
  # 上のキーだけを上書きする。サーバーは設定ディレクトリを監視しているので、
  # 再起動しなくても読み直す。
  home.activation.configureT3codeSettings = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    settings_dir=${lib.escapeShellArg settingsDir}
    settings_file="$settings_dir/settings.json"
    run mkdir -p "$settings_dir"

    if [ -f "$settings_file" ]; then
      tmp="$(${pkgs.coreutils}/bin/mktemp "$settings_dir/.settings.json.XXXXXX")"
      if ! ${lib.getExe pkgs.jq} -s '.[0] * .[1]' "$settings_file" ${settingsFile} > "$tmp"; then
        rm -f "$tmp"
        exit 1
      fi
      chmod 644 "$tmp"
      run mv "$tmp" "$settings_file"
    else
      run ${lib.getExe pkgs.jq} . ${settingsFile} > "$settings_file"
    fi
  '';

  # T3 Connect のトンネルはループバックの origin しか公開しないので、外向きには
  # 待ち受けない。初回だけ `t3 connect` でサインインすると、以後は起動時に
  # リンクを張り直す。社内 NW からは T3 Connect か SSH 転送でつなぐ。
  systemd.user.services.t3code = {
    Unit = {
      Description = "T3 Code server";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };

    Service = {
      Type = "simple";
      # user manager の PATH を継承しないことがあるので、セッションへ渡す PATH を明示する。
      Environment = [ "PATH=${config.systemd.user.sessionVariables.PATH}" ];
      # PR の状態は az repos で引く。DevOps の組織は az login と別テナントなので、
      # PAT を渡す。リポジトリ管理外のファイルで、無ければ渡さない。
      EnvironmentFile = "-%h/.config/azure-devops/env";
      ExecStart = "${t3code}/bin/t3 serve --host 127.0.0.1 --port ${toString port} --no-browser ${config.home.homeDirectory}";
      Restart = "on-failure";
      RestartSec = 5;
    };

    Install.WantedBy = [ "default.target" ];
  };
}
