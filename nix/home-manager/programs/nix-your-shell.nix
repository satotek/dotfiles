{ config, pkgs, ... }:
let
  cfg = config.programs.nix-your-shell;
  # 出力は nix / nix-shell を包む関数だけで、パッケージで決まる。起動のたびに
  # 実行せず、ビルド時に生成したものを読む。
  zshInit = pkgs.runCommandLocal "nix-your-shell-init.zsh" { } ''
    ${cfg.package}/bin/nix-your-shell zsh > $out
  '';
in
{
  # nix shell / nix develop に入っても bash に落ちず zsh のまま使う。
  programs.nix-your-shell = {
    enable = true;
    enableZshIntegration = false;
  };

  programs.zsh.initContent = ''
    builtin source ${zshInit}
  '';
}
