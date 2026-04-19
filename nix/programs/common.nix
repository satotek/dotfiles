{ pkgs, ... }:
{
  home.packages = with pkgs; [
    btop
    cargo
    curl
    fd
    ffmpeg
    fzf
    gh
    go
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
    ./sheldon
    ./starship
    ./tmux
    ./wezterm
    ./wget
    ./zsh
  ];
}
