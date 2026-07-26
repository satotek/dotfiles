{ config, pkgs, ... }:
{
  programs.sheldon = {
    enable = true;
    # zsh.nixで生成結果をキャッシュして読み込むため、標準integrationは重複させない。
    enableZshIntegration = false;
    settings = {
      shell = "zsh";

      templates.defer = "{{ hooks?.pre | nl }}{% for file in files %}zsh-defer source \"{{ file }}\"\n{% endfor %}{{ hooks?.post | nl }}";

      plugins = {
        zsh-defer.github = "romkatv/zsh-defer";

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

        zeno = {
          github = "yuki-yano/zeno.zsh";
          branch = "feature/sqlite-history-subsystem";
        };

        fast-syntax-highlighting = {
          github = "zdharma-continuum/fast-syntax-highlighting";
          use = [ "fast-syntax-highlighting.plugin.zsh" ];
          apply = [ "defer" ];
        };
      };
    };
  };

  # Nix storeのmtimeは固定されるため、zsh.nixの`-nt`だけでは設定変更を検出できない。
  # Home Managerの内容比較で変更された場合だけキャッシュを削除し、次回起動時に再生成する。
  xdg.configFile."sheldon/plugins.toml".onChange = ''
    ${pkgs.coreutils}/bin/rm -f "${config.home.homeDirectory}/.local/cache/zsh/sheldon.zsh"
  '';
}
