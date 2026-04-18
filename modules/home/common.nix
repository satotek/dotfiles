{ config, lib, pkgs, username, ... }:
let
  homeDirectory = config.home.homeDirectory;
  dotfilesDir = "${homeDirectory}/dotfiles";
  mkSource = path: config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/${path}";
in
{
  home.packages = with pkgs; [
    cargo
    curl
    delta
    fd
    fzf
    git
    lazygit
    neovim
    nodejs
    pnpm
    python3
    ripgrep
    rustc
    tmux
    uv
    wget
    yazi
  ];

  xdg.configFile = {
    "git".source = mkSource "config/git";
    "lazygit".source = mkSource "config/lazygit";
    "nvim".source = mkSource "config/nvim";
    "profile".source = mkSource "config/profile";
    "tmux".source = mkSource "config/tmux";
    "wezterm".source = mkSource "config/wezterm";
    "wget".source = mkSource "config/wget";
    "zsh" = {
      source = mkSource "config/zsh";
      force = true;
    };
  };

  home.file = {
    ".profile".text = ''
      [ -f "$HOME/.config/profile" ] && . "$HOME/.config/profile"
    '';

    ".tmux.conf".source = mkSource "config/tmux/tmux.conf";

    ".zshenv".text = ''
      export ZDOTDIR="$HOME/.config/zsh"
    '';
  };

  home.activation.createBaseDirectories = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p \
      "$HOME/.local/bin" \
      "$HOME/.local/cache" \
      "$HOME/.local/cache/less" \
      "$HOME/.local/cache/zsh" \
      "$HOME/.local/share" \
      "$HOME/.local/state" \
      "$HOME/.local/state/git" \
      "$HOME/bin" \
      "$HOME/workspaces/develop" \
      "$HOME/workspaces/education" \
      "$HOME/workspaces/sandbox" \
      "$HOME/workspaces/temp" \
      "$HOME/src" \
      "$HOME/tmp"
  '';
}
