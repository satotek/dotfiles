{ pkgs, ... }:
{
  home.packages = with pkgs; [
    ast-grep
    bash-language-server
    clang-tools
    lua-language-server
    markdown-oxide
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
