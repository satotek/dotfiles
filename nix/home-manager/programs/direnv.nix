{ ... }:
{
  programs.direnv = {
    enable = true;
    # init.zshで生成結果をキャッシュ・zcompileして読み込む。
    enableZshIntegration = false;
    nix-direnv.enable = true;

    config.global = {
      # flake の初回評価は数秒かかるので「読み込みが遅い」警告を出さない
      warn_timeout = "0s";
      # cd 毎の `export +FOO +BAR ...` 差分表示を隠す
      hide_env_diff = true;
    };

    # direnv のログ（`direnv: loading ...` 等）を完全に無音化
    stdlib = ''
      export DIRENV_LOG_FORMAT=""
    '';
  };
}
