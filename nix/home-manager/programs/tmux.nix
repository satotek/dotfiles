{ ... }:
{
  programs.tmux = {
    enable = true;
    prefix = "C-a";
    keyMode = "vi";
    mouse = true;
    terminal = "tmux-256color";
    extraConfig = ''
      set -as terminal-overrides ',*:Tc'
      set -g status-bg '#9A88CB'

      bind \\ split-window -h
      bind - split-window -v

      bind -r h select-pane -L
      bind -r j select-pane -D
      bind -r k select-pane -U
      bind -r l select-pane -R

      bind-key -T copy-mode-vi 'v' send -X begin-selection
      bind-key -T copy-mode-vi 'C-v' send -X rectangle-toggle
      bind-key -T copy-mode-vi 'y' send -X copy-selection-and-cancel

      bind-key -T edit-mode-vi WheelUpPane send-keys -X scroll-up
      bind-key -T edit-mode-vi WheelDownPane send-keys -X scroll-down

      bind m run-shell '
        if [ "$(tmux show -g -v mouse)" = "on" ]; then
          tmux set -g mouse off
        else
          tmux set -g mouse on
        fi
      '

      set -g status-right 'Mouse: #{?mouse,on,off} | %Y-%m-%d %H:%M '

      # Shift+Enter and other extended key sequences.
      set -s extended-keys always
      set -as terminal-features 'xterm*:extkeys'
    '';
  };
}
