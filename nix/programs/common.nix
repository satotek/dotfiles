{ pkgs, ... }:
{
  home.packages = with pkgs; [
    btop
    curl
    deno
    fd
    fzf
    ripgrep
    yazi
  ];

  imports = [
    ./codex.nix
    ./ghostty.nix
    ./git.nix
    ./lazygit.nix
    ./nvim.nix
    ./sheldon.nix
    ./starship.nix
    ./tmux.nix
    ./wezterm.nix
    ./wget.nix
    ./zeno.nix
    ./zoxide.nix
    ./zsh.nix
  ];
}
