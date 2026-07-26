{ pkgs, ... }:
{
  home.packages = with pkgs; [
    curl
    wl-clipboard
    xclip
  ];
}
