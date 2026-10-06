{ ... }:
{
  # zsh 連携で ls / ll / la / lt / lla が eza の alias になる。lt が tree の代わり。
  programs.eza = {
    enable = true;
    git = true;
  };

  # 既定の la は eza -a だが、以前の ls -al と同じ長形式を保つ。
  programs.zsh.shellAliases.la = "eza -la";
}
