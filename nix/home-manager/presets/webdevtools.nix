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
    pyright
    python3
    ruff
    tailwindcss-language-server
    taplo
    typescript-go
    uv
    vscode-langservers-extracted
    yaml-language-server
  ];
}
