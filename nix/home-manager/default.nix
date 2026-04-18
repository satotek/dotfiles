{ ... }:
{
  imports = [
    ./home/packages.nix
    ./home/profile.nix
    ./home/migrations.nix
    ./home/shell.nix
    ./home/directories.nix
    ../programs/git
    ../programs/lazygit
    ../programs/nvim
    ../programs/tmux
    ../programs/wezterm
    ../programs/wget
    ../programs/zsh
  ];
}
