{ lib, ... }:
{
  home.activation.createBaseDirectories = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p \
      "$HOME/.local/bin" \
      "$HOME/.local/cache" \
      "$HOME/.local/cache/less" \
      "$HOME/.local/cache/zsh" \
      "$HOME/.local/share" \
      "$HOME/.local/state" \
      "$HOME/.local/state/git" \
      "$HOME/.local/state/zsh" \
      "$HOME/bin" \
      "$HOME/ghq" \
      "$HOME/workspaces/develop" \
      "$HOME/workspaces/education" \
      "$HOME/workspaces/sandbox" \
      "$HOME/workspaces/temp" \
      "$HOME/src" \
      "$HOME/tmp"
  '';
}
