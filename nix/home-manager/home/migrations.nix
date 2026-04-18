{ lib, ... }:
{
  home.activation.migrateManagedConfigDirs = lib.hm.dag.entryBefore [ "linkGeneration" ] ''
    migrate_config_dir() {
      local path="$1"

      if [ -L "$path" ]; then
        rm "$path"
        mkdir -p "$path"
      elif [ -e "$path" ] && [ ! -d "$path" ]; then
        rm -f "$path"
        mkdir -p "$path"
      fi
    }

    # Older generations linked these paths as whole directories. They now
    # contain individually managed files, so convert old symlinks to real dirs.
    migrate_config_dir "$HOME/.config/git"
    migrate_config_dir "$HOME/.config/tmux"
    migrate_config_dir "$HOME/.config/wget"
    migrate_config_dir "$HOME/.config/zsh"
  '';
}
