{ ... }:
{
  # zsh 連携の y で起動すると、終了時に最後に開いていたディレクトリへ cd する。
  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
  };
}
