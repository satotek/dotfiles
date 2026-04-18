{ config, lib, username, ... }:
let
  homeDirectory = "/Users/${username}";
  dotfilesDir = "${homeDirectory}/dotfiles";
  mkSource = path: config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/${path}";
in
{
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
      [ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"
      [ -f "$HOME/.local/share/ghcup/env" ] && . "$HOME/.local/share/ghcup/env"
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
      "$HOME/.local/cache/zsh" \
      "$HOME/.local/share" \
      "$HOME/.local/state" \
      "$HOME/.local/state/git" \
      "$HOME/bin" \
      "$HOME/src" \
      "$HOME/tmp"
  '';
}
