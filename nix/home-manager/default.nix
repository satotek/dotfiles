{ ... }:
{
  imports = [
    ./home/nix.nix
    ./home/profile.nix
    ./home/migrations.nix
    ./home/shell.nix
    ./home/directories.nix
    ./programs/sops.nix
  ];
}
