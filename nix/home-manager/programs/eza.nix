{ ... }:
{
  # zsh 連携で ls / ll / la / lt / lla が eza の alias になる。lt が tree の代わり。
  programs.eza = {
    enable = true;
    git = true;
  };
}
