# Source XDG Base Directory configuration
[ -f "$HOME/.config/profile" ] && . "$HOME/.config/profile"

### Zinit installer
ZINIT_HOME="${XDG_CONFIG_HOME:-$HOME/.config}/zinit"
if [[ ! -f "$ZINIT_HOME/zinit.zsh" ]]; then
    echo "Installing zinit..."
    mkdir -p "$ZINIT_HOME"
    git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi
source "$ZINIT_HOME/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit
### End of Zinit installer

source $XDG_CONFIG_HOME/zsh/plugins.zsh
source $XDG_CONFIG_HOME/zsh/config.zsh
source $XDG_CONFIG_HOME/zsh/aliases.zsh
source $XDG_CONFIG_HOME/zsh/tools.zsh
source $XDG_CONFIG_HOME/zsh/p10k.zsh

# Load local configuration (not tracked by git)
[[ -f $XDG_CONFIG_HOME/zsh/local.zsh ]] && source $XDG_CONFIG_HOME/zsh/local.zsh

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
