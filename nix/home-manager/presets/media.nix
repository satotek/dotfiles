{ pkgs, ... }:
{
  home.packages = with pkgs; [
    ffmpeg
    mermaid-cli
  ];
}
