{
  inputs,
  lib,
  pkgs,
  ...
}:
{
  imports = [ inputs.rex.homeManagerModules.default ];

  programs.rex = {
    enable = true;
    # ガードは programs.ssh 経由で ~/.ssh/config に書かれるが、この dotfiles は
    # ~/.ssh/config を管理していない。ガードが無いとサーバーは TERM=xterm-rex を
    # 名乗らないので、外して警告だけ止める。
    sshGuard = false;
  };

  # macOS では Rex アプリがサーバーを動かすため、常駐サービスは Linux だけ。
  # Mac から接続したときにセッションが無くても待ち受けているよう常駐させる。
  services.rex.enable = lib.mkIf pkgs.stdenv.hostPlatform.isLinux true;
}
