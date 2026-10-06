{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.atuin;
  # 出力は package と flags だけで決まるので、ビルド時に生成して起動時の
  # `atuin init` を省く。init は設定ファイルを書こうとするので HOME を逃がす。
  zshInit = pkgs.runCommandLocal "atuin-init.zsh" { } ''
    export HOME="$TMPDIR"
    ${lib.getExe cfg.package} init zsh ${lib.escapeShellArgs cfg.flags} > $out
  '';
in
{
  # Ctrl-R の履歴検索だけ atuin に任せ、Ctrl-T / Alt-C / Tab は fzf のまま。
  programs.atuin = {
    enable = true;
    enableZshIntegration = false;
    flags = [ "--disable-up-arrow" ];
    settings = {
      update_check = false;
    };
  };

  # init.zsh が fzf の Ctrl-R を割り当てた後に読み、atuin で上書きする。
  # init は `atuin uuid` などを起動して数 ms かかるので、最初のプロンプトの後に回す。
  programs.zsh.initContent = lib.mkOrder 1100 ''
    if (( $+functions[zsh-defer] )); then
      zsh-defer builtin source ${zshInit}
    else
      builtin source ${zshInit}
    fi
  '';
}
