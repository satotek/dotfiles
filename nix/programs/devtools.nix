{ pkgs, ... }:
{
  home.packages = with pkgs; [
    cargo
    ffmpeg
    gh
    go
    rustc
  ];
}
