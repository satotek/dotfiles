{ ... }:
{
  # RIPGREP_CONFIG_PATH 経由なので、rg を呼ぶエージェントの検索にも効く。
  programs.ripgrep = {
    enable = true;
    arguments = [ "--smart-case" ];
  };
}
