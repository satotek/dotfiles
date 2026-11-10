{
  config,
  ...
}:
{
  # 既定の番号にしておくと、デスクトップアプリの SSH 接続や手元のトンネルが
  # 同じ番号を前提にできる。手元でサーバーを動かすときは転送元の番号をずらす。
  #
  # T3 Connect のトンネルはループバックの origin しか公開しないので、外向きには
  # 待ち受けない。初回だけ `t3 connect` でサインインすると、以後は起動時に
  # リンクを張り直す。社内 NW からは T3 Connect か SSH 転送でつなぐ。
  programs.t3code.server = {
    enable = true;
    extraArgs = [
      "--host"
      "127.0.0.1"
      "--port"
      "3773"
      "--no-browser"
      config.home.homeDirectory
    ];
  };

  # モジュールの service に、このホスト固有の起動条件だけを足す。
  systemd.user.services.t3code = {
    Unit = {
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };

    Service = {
      # user manager の PATH を継承しないことがあるので、セッションへ渡す PATH を明示する。
      Environment = [ "PATH=${config.systemd.user.sessionVariables.PATH}" ];
      # PR の状態は az repos で引く。DevOps の組織は az login と別テナントなので、
      # PAT を渡す。リポジトリ管理外のファイルで、無ければ渡さない。
      EnvironmentFile = [
        "-%h/.config/azure-devops/env"
        # T3 Code の usage limits は環境変数のキーを読むため、sops から配る。
        "-%h/.config/t3code/opencode.env"
      ];
    };
  };
}
