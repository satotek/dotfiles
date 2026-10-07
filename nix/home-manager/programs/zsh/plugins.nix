{
  config,
  lib,
  pkgs,
  ...
}:
let
  # 読み込み順と遅延対象は明示し、取得・更新はNixだけで管理する。
  loader = pkgs.writeText "zsh-plugins.zsh" ''
    builtin source "${pkgs.zsh-defer}/share/zsh-defer/zsh-defer.plugin.zsh"
    ZSH_AUTOSUGGEST_USE_ASYNC=1
    fpath+=("${pkgs.zsh-completions}/share/zsh/site-functions")

    # fzf-tabはcompinit後、ZLEをラップするプラグインより前に読み込む。
    _load_zsh_interactive_plugins() {
      zstyle ':completion:*' menu no
      zstyle ':completion:*:descriptions' format '[%d]'
      # 通常のfzf設定とは分け、説明欄とプレビューの幅を確保する。
      zstyle ':fzf-tab:*' use-fzf-default-opts no
      zstyle ':fzf-tab:*' show-group full
      zstyle ':fzf-tab:*' switch-group '<' '>'
      zstyle ':fzf-tab:*' fzf-flags \
        '--height=45%' '--border=rounded' '--padding=0,1' \
        '--layout=reverse' '--info=inline-right' '--prompt=❯ ' \
        '--color=fg:-1,bg:-1,fg+:153,bg+:237,hl:110,hl+:117,border:60,prompt:110,pointer:117,marker:150,header:110,info:244' \
        '--preview-window=right,45%,border-left,<80(down,40%,border-top)'
      zstyle ':fzf-tab:complete:(cd|pushd):*' fzf-preview \
        '${pkgs.eza}/bin/eza --all --color=always --group-directories-first --oneline -- "$realpath"'
      builtin source "${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh"
      zsh-defer source "${pkgs.zsh-fast-syntax-highlighting}/share/zsh/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh"
      ${lib.optionalString (!config.programs.zsh.autosuggestion.enable) ''
        zsh-defer source "${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
      ''}
    }
  '';
  # 起動時のキャッシュ検査や外部コマンドを避け、ビルド時にコンパイルする。
  compiled = pkgs.runCommand "zsh-plugins" { } ''
    mkdir -p "$out"
    cp ${loader} "$out/plugins.zsh"
    ${pkgs.zsh}/bin/zsh -fc 'zcompile "$1"' _ "$out/plugins.zsh"
  '';
in
{
  programs.zsh.initContent = lib.mkOrder 550 ''
    builtin source "${compiled}/plugins.zsh"
  '';
}
