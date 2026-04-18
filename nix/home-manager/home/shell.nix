{ ... }:
{
  home.file = {
    ".profile".text = ''
      [ -f "$HOME/.config/profile" ] && . "$HOME/.config/profile"
    '';

    ".tmux.conf".text = ''
      source-file "$HOME/.config/tmux/tmux.conf"
    '';
  };
}
