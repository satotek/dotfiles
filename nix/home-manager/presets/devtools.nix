{ pkgs, ... }:
{
  home.packages = with pkgs; [
    bash-language-server
    ffmpeg
    gh
    go
    gopls
    lua-language-server
    marksman
    mermaid-cli
    shellcheck
    shfmt
    stylua
  ];
}
