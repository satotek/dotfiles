{ pkgs, ... }:
{
  home.packages = with pkgs; [
    curl
    delta
    fd
    fzf
    git
    lazygit
    neovim
    ripgrep
    tmux
    wget
    yazi
  ];
}
