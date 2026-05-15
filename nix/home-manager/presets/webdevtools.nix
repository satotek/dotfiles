{ pkgs, ... }:
{
  home.packages = with pkgs; [
    bun
    nodejs
    pnpm
    pyright
    python3
    typescript-language-server
    uv
  ];
}
