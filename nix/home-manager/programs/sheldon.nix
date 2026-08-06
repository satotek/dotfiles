{
  config,
  lib,
  pkgs,
  ...
}:
{
  programs.sheldon = {
    enable = true;
    # zsh.nixで生成結果をキャッシュして読み込むため、標準integrationは重複させない。
    enableZshIntegration = false;
    settings = {
      shell = "zsh";

      templates.defer = "{{ hooks?.pre | nl }}{% for file in files %}zsh-defer source \"{{ file }}\"\n{% endfor %}{{ hooks?.post | nl }}";

      plugins = {
        # NixのTOML生成は属性名順になるため、遅延対象より先にsourceする。
        "00-zsh-defer".github = "romkatv/zsh-defer";

        zsh-completions = {
          github = "zsh-users/zsh-completions";
          use = [ "zsh-completions.plugin.zsh" ];
        };

        zsh-autosuggestions = {
          github = "zsh-users/zsh-autosuggestions";
          use = [ "zsh-autosuggestions.zsh" ];
          apply = [ "defer" ];
          hooks.pre = "ZSH_AUTOSUGGEST_USE_ASYNC=1";
        };

        fast-syntax-highlighting = {
          github = "zdharma-continuum/fast-syntax-highlighting";
          use = [ "fast-syntax-highlighting.plugin.zsh" ];
          apply = [ "defer" ];
        };
      };
    };
  };

  # plugins.tomlだけ変更すると既存のplugins.lockから削除済みプラグインが
  # 復活するため、設定かSheldon本体が変わった時にlockとキャッシュを同期する。
  home.activation.syncSheldonPlugins = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    export SHELDON_CONFIG_DIR="${config.xdg.configHome}/sheldon"
    export SHELDON_DATA_DIR="${config.xdg.dataHome}/sheldon"

    cache_dir="${config.xdg.cacheHome}/zsh"
    cache_file="$cache_dir/sheldon.zsh"
    cache_tmp="$cache_file.tmp.$$"
    cache_stamp="$cache_dir/sheldon.signature"
    config_hash="$(${pkgs.coreutils}/bin/sha256sum "$SHELDON_CONFIG_DIR/plugins.toml")"
    signature="${pkgs.sheldon}|''${config_hash%% *}"
    mkdir -p "$cache_dir"

    if [[ -r "$cache_file" && -r "$cache_file.zwc" && -r "$cache_stamp" && "$(<"$cache_stamp")" == "$signature" ]]; then
      verboseEcho "Sheldon plugins are up to date"
    else
      verboseEcho "Synchronizing Sheldon plugins"
      run ${pkgs.sheldon}/bin/sheldon --non-interactive lock

      if ${pkgs.sheldon}/bin/sheldon --quiet source >| "$cache_tmp"; then
        mv -f "$cache_tmp" "$cache_file"
      else
        rm -f "$cache_tmp"
        exit 1
      fi
      run ${pkgs.zsh}/bin/zsh -fc 'zcompile "$1"' _ "$cache_file"
      printf '%s\n' "$signature" >| "$cache_stamp"
    fi
  '';
}
