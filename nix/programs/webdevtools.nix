{ pkgs, ... }:
{
  home.packages = with pkgs; [
    nodejs
    pnpm
    python3
    uv
  ];
}
