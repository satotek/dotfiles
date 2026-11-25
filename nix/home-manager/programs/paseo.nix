{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  isLinux = pkgs.stdenv.hostPlatform.isLinux;
  paseo = inputs.paseo.packages.${pkgs.stdenv.hostPlatform.system}.paseo;
  paseoHome = "${config.home.homeDirectory}/.paseo";
  mergeConfig = import ../lib/merge-config.nix { inherit pkgs lib; };
in
{
  # macOS は homebrew cask の Paseo.app が daemon と CLI を同梱する。
  # Linux にはデスクトップ版が無いので、上流 flake の daemon/CLI を入れる。
  home.packages = lib.mkIf isLinux [ paseo ];

  # Mac やスマホのクライアントから繋ぐための常駐デーモン。起動方法と停止手順は
  # 上流の NixOS モジュールに合わせる（paseo-server を直接動かし SIGTERM で止める）。
  # config.json の大半は Paseo 自身が書き戻すため触らず、スキル選択だけをマージする。
  systemd.user.services.paseo = lib.mkIf isLinux {
    Unit = {
      Description = "Paseo self-hosted daemon for AI coding agents";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };

    Service = {
      ExecStart = "${paseo}/bin/paseo-server";
      Restart = "on-failure";
      RestartSec = 5;
      KillSignal = "SIGTERM";
      TimeoutStopSec = 15;
      Environment = [
        "PASEO_HOME=${paseoHome}"
        # エージェントの CLI を探せるよう、セッションと同じ PATH を渡す。
        "PATH=${config.systemd.user.sessionVariables.PATH}"
      ];
    };

    Install.WantedBy = [ "default.target" ];
  };

  home.activation.createPaseoHome = lib.mkIf isLinux (
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run mkdir -p ${lib.escapeShellArg paseoHome}
      run chmod 700 ${lib.escapeShellArg paseoHome}
    ''
  );

  # 同梱スキルは agent-skills が配る。Paseo のインストーラは実ファイルを
  # ~/.claude などへコピーし、そちらの rsync --delete と衝突するので、
  # 選択を空にして常に何も入れさせない。config.json の他のキーはアプリが持つ。
  # 宣言したプロバイダーも同じく上書きマージし、アプリで足した分は残す。
  home.activation.configurePaseo =
    lib.hm.dag.entryAfter ([ "linkGeneration" ] ++ lib.optional isLinux "createPaseoHome")
      (mergeConfig {
        name = "paseo-config.json";
        path = "${paseoHome}/config.json";
        settings.agents = {
          skills.selection = {
            mode = "custom";
            skills = [ ];
          };
          # 組み込みの claude を CLAUDE_CONFIG_DIR だけ変えて複製し、アカウントを
          # プロバイダーとして選べるようにする。ログインは各ディレクトリのものを使う。
          providers.claude-work = {
            extends = "claude";
            label = "Claude (Work)";
            description = "Work account (~/.claude_work)";
            env.CLAUDE_CONFIG_DIR = "${config.home.homeDirectory}/.claude_work";
          };
        };
      });
}
