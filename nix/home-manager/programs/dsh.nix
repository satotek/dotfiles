{
  config,
  lib,
  pkgs,
  ...
}:
let
  dsh = pkgs.llm-agents.dsh;
  port = 3080;
  web = config.dotfiles.dsh.web;
  # Tailscale Serve など HTTP のリバースプロキシ越しに使うときは、
  # ホスト設定から publicUrl と trustedHosts を渡す。
  webArgs = [
    "--profile"
    "web"
    "--no-open"
    "--host"
    "127.0.0.1"
    "--port"
    (toString port)
  ]
  ++ lib.optionals (web.publicUrl != null) [
    "--public-url"
    web.publicUrl
  ]
  ++ lib.concatMap (host: [
    "--trusted-host"
    host
  ]) web.trustedHosts;
in
{
  options.dotfiles.dsh.web = {
    publicUrl = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "dsh web がリバースプロキシ越しに広告する URL。";
    };
    trustedHosts = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "dsh web の browser-trust fence が追加で受け入れる authority。";
    };
  };

  config = {
    # DeepSeek Harness。upstream はリリース成果物を出さないので、
    # llm-agents.nix がソースからビルドしたパッケージを使う。
    home.packages = [ dsh ];

    # ブラウザ UI は前景プロセスなので、ログイン時に常駐させる。
    # URL は起動ログに出る。Linux は journalctl、macOS は ~/Library/Logs を見る。
    systemd.user.services.dsh = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      Unit = {
        Description = "DeepSeek Harness web UI";
        After = [ "network-online.target" ];
        Wants = [ "network-online.target" ];
      };

      Service = {
        Type = "simple";
        Environment = [ "PATH=${config.systemd.user.sessionVariables.PATH}" ];
        ExecStart = "${dsh}/bin/dsh ${lib.concatStringsSep " " webArgs}";
        WorkingDirectory = "%h";
        Restart = "always";
        RestartSec = 5;
      };

      Install.WantedBy = [ "default.target" ];
    };

    launchd.agents.dsh = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
      enable = true;
      config = {
        Label = "org.nix-community.home.dsh";
        ProgramArguments = [ "${dsh}/bin/dsh" ] ++ webArgs;
        WorkingDirectory = config.home.homeDirectory;
        RunAtLoad = true;
        KeepAlive = true;
        EnvironmentVariables.PATH = lib.concatStringsSep ":" [
          "${config.home.profileDirectory}/bin"
          "/nix/var/nix/profiles/default/bin"
          "/usr/local/bin"
          "/usr/bin"
          "/bin"
          "/usr/sbin"
          "/sbin"
        ];
        StandardOutPath = "${config.home.homeDirectory}/Library/Logs/dsh-web.log";
        StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/dsh-web.err.log";
      };
    };
  };
}
