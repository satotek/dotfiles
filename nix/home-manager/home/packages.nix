{ pkgs, ... }:
{
  home.packages = with pkgs; [
    cargo
    curl
    delta
    fd
    fzf
    lazygit
    neovim
    nodejs
    pnpm
    python3
    ripgrep
    rustc
    uv
    wget
    yazi
  ];
}
