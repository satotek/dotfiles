{ pkgs, ... }:
{
  home.packages = with pkgs; [
    bash-language-server
    ast-grep
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
