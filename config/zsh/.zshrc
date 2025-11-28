# Source XDG Base Directory configuration
[ -f "$HOME/.config/profile" ] && . "$HOME/.config/profile"

# Auto-move additions to local.zsh
_zshrc_cleanup() {
    local zshrc="$XDG_CONFIG_HOME/zsh/.zshrc"
    local localzsh="$XDG_CONFIG_HOME/zsh/local.zsh"

    # Find the marker line number (must start at beginning of line)
    local line_num=$(grep -n "^### DO NOT ADD ANYTHING BELOW THIS LINE ###$" "$zshrc" 2>/dev/null | tail -1 | cut -d: -f1)
    [[ -z "$line_num" ]] && return

    local total_lines=$(wc -l < "$zshrc" | tr -d ' ')
    local marker_comment_line=$((line_num + 1))

    # Check if there's content after the comment line (line_num + 1)
    if (( total_lines > marker_comment_line )); then
        # Extract lines after the comment and append to local.zsh
        tail -n +$((marker_comment_line + 1)) "$zshrc" >> "$localzsh"
        # Keep only up to the comment line
        head -n "$marker_comment_line" "$zshrc" > "${zshrc}.tmp"
        mv "${zshrc}.tmp" "$zshrc"
        echo "Moved new configurations to local.zsh"
    fi
}
_zshrc_cleanup

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

### DO NOT ADD ANYTHING BELOW THIS LINE ###
# Any lines added below will be moved to local.zsh automatically
