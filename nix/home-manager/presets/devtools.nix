{ pkgs, ... }:
{
  home.packages = with pkgs; [
    cargo
    ffmpeg
    gh
    go
    gopls
    rust-analyzer
    rustc
  ];
}
