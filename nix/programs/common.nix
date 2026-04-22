{ pkgs, ... }:
{
  home.packages = with pkgs; [
    btop
    curl
    deno
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
    ./zeno
    ./zoxide
    ./zsh
  ];
}
