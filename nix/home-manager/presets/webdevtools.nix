{ pkgs, ... }:
{
  home.packages = with pkgs; [
    bun
    efm-langserver
    nixd
    nixfmt
    nodejs
    oxfmt
    pnpm
    basedpyright
    python3
    ruff
    tailwindcss-language-server
    taplo
    tree-sitter
    typescript-go
    uv
    vscode-langservers-extracted
    yaml-language-server
  ];
}
