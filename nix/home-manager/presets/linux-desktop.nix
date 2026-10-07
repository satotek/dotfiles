# Wayland と X11 のクリップボード操作。画面のないホストでは接続先がなく動かないため、
# Linux のデスクトップでだけ読む。ssh 越しのコピーは Neovim と同じく OSC 52 で足りる。
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    wl-clipboard
    xclip
  ];
}
