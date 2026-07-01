{ ... }:
{
  homebrew = {
    enable = true;
    brews = [
      "herdr" # agent multiplexer (tmux-like TUI for AI coding agents)
    ];
    casks = [
      "karabiner-elements"
      "wezterm@nightly"
    ];
  };
}
