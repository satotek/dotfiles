{ pkgs, ... }:
{
  home.packages = with pkgs; [
    bun
    nodejs
    oxfmt
    pnpm
    tailwindcss-language-server
    typescript
    vscode-langservers-extracted
  ];
}
