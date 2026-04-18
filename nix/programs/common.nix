{ pkgs, ... }:
{
  home.packages = with pkgs; [
    cargo
    curl
    fd
    fzf
    nodejs
    pnpm
    python3
    ripgrep
    rustc
    uv
    yazi
  ];

  imports = [
    ./git
    ./lazygit
    ./nvim
    ./tmux
    ./wezterm
    ./wget
    ./zsh
  ];
}
