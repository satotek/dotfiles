{ pkgs, ... }:
{
  home.packages = with pkgs; [
    ast-grep
    bash-language-server
    efm-langserver
    lua-language-server
    marksman
    nixd
    nixfmt
    shellcheck
    shfmt
    stylua
    taplo
    tree-sitter
    yaml-language-server
  ];
}
