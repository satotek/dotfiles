#################################  HISTORY  #################################
HISTFILE=${HISTFILE:-$XDG_STATE_HOME/zsh/history}
[[ -d "$(dirname "$HISTFILE")" ]] || mkdir -p "$(dirname "$HISTFILE")"
HISTSIZE=100000
SAVEHIST=1000000

setopt inc_append_history   # Append history incrementally
setopt share_history        # Share history between sessions

#################################  COMPLETION  #################################
autoload -Uz compinit && compinit

# Case-insensitive completion
zstyle ':completion:*' matcher-list '' 'm:{[:lower:]}={[:upper:]}' '+m:{[:upper:]}={[:lower:]}'

# Group completions by type
zstyle ':completion:*' format '%B%F{blue}%d%f%b'
zstyle ':completion:*' group-name ''

# Menu selection for completions
zstyle ':completion:*:default' menu select=2

#################################  OPTIONS  #################################
setopt auto_cd          # cd by typing directory name
setopt no_flow_control  # Disable ctrl+s, ctrl+q
