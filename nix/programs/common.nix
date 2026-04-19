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
