{ pkgs, ... }:
{
  home.packages = with pkgs; [
    btop
    curl
    fd
    fzf
    ripgrep
    yazi
  ];

  imports = [
    ./ghostty
    ./git
    ./lazygit
    ./nvim
    ./sheldon
    ./starship
    ./tmux
    ./wezterm
    ./wget
    ./zoxide
    ./zsh
  ];
}
