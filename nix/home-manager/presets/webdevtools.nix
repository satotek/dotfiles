{ pkgs, ... }:
{
  home.packages = with pkgs; [
    nodejs
    pnpm
    pyright
    python3
    typescript-language-server
    uv
  ];
}
