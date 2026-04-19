{ config, lib, ... }:
let
  homeDirectory = config.home.homeDirectory;
in
{
  programs.zsh = {
    enable = true;
    dotDir = "${config.xdg.configHome}/zsh";
    autocd = true;
    enableCompletion = false;
    setOptions = [ "NO_FLOW_CONTROL" ];

    history = {
      path = "${homeDirectory}/.local/state/zsh/history";
      size = 100000;
      save = 1000000;
      share = true;
    };

    shellAliases = {
      vi = "nvim";
      vim = "nvim";
      sudo = "sudo ";
      python = "python3";
      ll = "ls -l";
      la = "ls -al";
      lg = "lazygit";
    };

    envExtra = ''
      [ -f "$HOME/.config/profile" ] && . "$HOME/.config/profile"
    '';

    initContent = lib.mkMerge [
      (lib.mkBefore ''
        ensure_zcompiled() {
          local src="$1"
          local zwc="$src.zwc"
          local dir="''${src:h}"

          if [[ ! -r "$src" || ! -w "$dir" ]]; then
            return
          fi

          if [[ ! -r "$zwc" || "$src" -nt "$zwc" ]]; then
            zcompile "$src" 2>/dev/null || true
          fi
        }

        source() {
          ensure_zcompiled "$1"
          builtin source "$1"
        }
      '')

      ''
        zstyle ':completion:*' matcher-list "" "m:{[:lower:]}={[:upper:]}" "+m:{[:upper:]}={[:lower:]}"
        zstyle ':completion:*' format '%B%F{blue}%d%f%b'
        zstyle ':completion:*' group-name ""
        zstyle ':completion:*:default' menu select=2

        cache_dir="''${XDG_CACHE_HOME:-$HOME/.local/cache}/zsh"
        sheldon_cache="$cache_dir/sheldon.zsh"
        sheldon_toml="''${XDG_CONFIG_HOME:-$HOME/.config}/sheldon/plugins.toml"
        sheldon_lock="''${XDG_CONFIG_HOME:-$HOME/.config}/sheldon/plugins.lock"
        _sheldon_bin="$(command -v sheldon)"

        if [[ -n "$_sheldon_bin" && ( ! -r "$sheldon_cache" || "$sheldon_toml" -nt "$sheldon_cache" || ( -r "$sheldon_lock" && "$sheldon_lock" -nt "$sheldon_cache" ) ) ]]; then
          mkdir -p "$cache_dir"
          _sheldon_tmp="$sheldon_cache.tmp.$$"
          if "$_sheldon_bin" --quiet source >| "$_sheldon_tmp"; then
            mv -f "$_sheldon_tmp" "$sheldon_cache"
          else
            rm -f "$_sheldon_tmp"
          fi
        fi

        [[ -r "$sheldon_cache" ]] && source "$sheldon_cache"
        unset _sheldon_tmp _sheldon_bin sheldon_toml sheldon_lock

        _deferred_compinit() {
          autoload -Uz compinit
          _comp_dump="''${XDG_CACHE_HOME:-$HOME/.local/cache}/zsh/.zcompdump"
          _comp_zwc="$_comp_dump.zwc"

          if [[ -r "$_comp_zwc" && "$_comp_zwc" -nt "$_comp_dump" ]]; then
            source "$_comp_dump"
          elif [[ -r "$_comp_dump" ]]; then
            source "$_comp_dump"
            ensure_zcompiled "$_comp_dump"
          else
            compinit -d "$_comp_dump"
            ensure_zcompiled "$_comp_dump"
          fi

          unset _comp_dump _comp_zwc
        }

        if (( $+functions[zsh-defer] )); then
          zsh-defer _deferred_compinit
        else
          _deferred_compinit
        fi

        [[ -f $XDG_CONFIG_HOME/zsh.local ]] && source "$XDG_CONFIG_HOME/zsh.local"

        rehash

        _starship_cache="$cache_dir/starship.zsh"
        _starship_config="''${XDG_CONFIG_HOME:-$HOME/.config}/starship.toml"
        _starship_bin="$(command -v starship)"
        if [[ -n "$_starship_bin" && ( ! -r "$_starship_cache" || ( -r "$_starship_config" && "$_starship_config" -nt "$_starship_cache" ) || "$_starship_bin" -nt "$_starship_cache" ) ]]; then
          "$_starship_bin" init zsh >| "$_starship_cache"
        fi
        [[ -r "$_starship_cache" ]] && source "$_starship_cache"

        _zoxide_cache="$cache_dir/zoxide.zsh"
        _zoxide_bin="$(command -v zoxide)"
        if [[ -n "$_zoxide_bin" && ( ! -r "$_zoxide_cache" || "$_zoxide_bin" -nt "$_zoxide_cache" ) ]]; then
          "$_zoxide_bin" init zsh >| "$_zoxide_cache"
        fi
        [[ -r "$_zoxide_cache" ]] && source "$_zoxide_cache"

        if (( $+functions[zsh-defer] )); then
          zsh-defer unfunction source ensure_zcompiled _deferred_compinit
        else
          unfunction source ensure_zcompiled _deferred_compinit 2>/dev/null
        fi

        unset cache_dir sheldon_cache _starship_bin _starship_cache _starship_config _zoxide_bin _zoxide_cache
      ''
    ];
  };
}
