{ ... }:
{
  imports = [
    ./home/profile.nix
    ./home/migrations.nix
    ./home/shell.nix
    ./home/directories.nix
    ../programs/common.nix
  ];
}
