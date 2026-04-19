{ ... }:
{
  home.file = {
    ".profile".text = ''
      if [ -n "$BASH_VERSION" ] && [ -f "$HOME/.bashrc" ]; then
        . "$HOME/.bashrc"
      fi

      [ -f "$HOME/.config/profile" ] && . "$HOME/.config/profile"
    '';

    ".tmux.conf".text = ''
      source-file "$HOME/.config/tmux/tmux.conf"
    '';
  };
}
