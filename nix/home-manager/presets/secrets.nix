{ pkgs, ... }:
{
  imports = [
    ../programs/sops.nix
  ];

  home.packages = [ pkgs.sops ];
}
