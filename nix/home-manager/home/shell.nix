{ config, ... }:
{
  home.file = {
    # zsh は .zshenv / .zprofile で hm-session-vars を読むが、bash や sh には
    # 読み込む経路がないのでここで読む。
    ".profile".text = ''
      . "${config.home.profileDirectory}/etc/profile.d/hm-session-vars.sh"

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
