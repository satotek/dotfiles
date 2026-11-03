{
  config,
  pkgs,
  ...
}:
let
  t3code = pkgs.llm-agents.t3code;
  # 既定の番号にしておくと、デスクトップアプリの SSH 接続や手元のトンネルが
  # 同じ番号を前提にできる。手元でサーバーを動かすときは転送元の番号をずらす。
  port = 3773;
in
{
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
