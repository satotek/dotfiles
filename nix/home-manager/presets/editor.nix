{ pkgs, ... }:
{
  home.packages = [ pkgs.rumdl ];

  imports = [
    ../programs/nvim.nix
  ];
}
