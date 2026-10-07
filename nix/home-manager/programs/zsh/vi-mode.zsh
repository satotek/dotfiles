# 既定の 0.4 秒だと Esc からコマンドモードへの切り替えが遅い。
# 1 まで縮めると ssh 越しで Home などのキー列が途切れ、Esc と誤解されやすい。
KEYTIMEOUT=5

# vi 標準の Backspace は、今回の入力モードで打った文字しか消せない。
bindkey -M viins '^?' backward-delete-char
bindkey -M viins '^H' backward-delete-char

# 割り当てのないキー列は先頭の Esc でコマンドモードに入り、残りが vi コマンドとして
# 実行されて行を書き換える。端末やモードで送る列が違うため、主な形をすべて登録する。
for _vi_keymap in viins vicmd; do
  bindkey -M "$_vi_keymap" '^[[H' beginning-of-line '^[OH' beginning-of-line '^[[1~' beginning-of-line
  bindkey -M "$_vi_keymap" '^[[F' end-of-line '^[OF' end-of-line '^[[4~' end-of-line
  bindkey -M "$_vi_keymap" '^[[3~' delete-char
done
unset _vi_keymap

autoload -Uz edit-command-line
zle -N edit-command-line
bindkey -M vicmd 'v' edit-command-line

# Starship が zle-keymap-select を包み直すため、その後でフックとして足す。
_vi_cursor_shape() {
  if [[ $KEYMAP == vicmd ]]; then
    printf '\e[2 q'
  else
    printf '\e[6 q'
  fi
}
autoload -Uz add-zle-hook-widget
add-zle-hook-widget keymap-select _vi_cursor_shape
add-zle-hook-widget line-init _vi_cursor_shape
