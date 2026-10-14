{
  config,
  lib,
  pkgs,
  ...
}:
{
  # linger 有効時は VM 起動時、それ以外は初回ログイン時に履歴を検証する。
  systemd.user.services.zsh-history-check = {
    Unit.Description = "Check and repair zsh history";
    Service = {
      Type = "oneshot";
      RemainAfterExit = true;
      UMask = "0077";
      ExecStart = "${pkgs.python3}/bin/python3 ${./zsh/repair-history.py} ${lib.escapeShellArg config.programs.zsh.history.path} ${config.programs.zsh.package}/bin/zsh";
    };
    Install.WantedBy = [ "default.target" ];
  };
}
