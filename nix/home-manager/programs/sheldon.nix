{ ... }:
{
  programs.sheldon = {
    enable = true;
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
}
