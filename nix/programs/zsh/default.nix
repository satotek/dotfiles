{ config, ... }:
let
  homeDirectory = config.home.homeDirectory;
  dotfilesDir = "${homeDirectory}/dotfiles";
  mkSource = path: config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/${path}";
in
{
  xdg.configFile."zsh/p10k.zsh" = {
    source = mkSource "nix/programs/zsh/files/p10k.zsh";
    force = true;
  };

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

    initContent = ''
      ### Zinit installer
      ZINIT_HOME="''${XDG_CONFIG_HOME:-$HOME/.config}/zinit"
      if [[ ! -f "$ZINIT_HOME/zinit.zsh" ]]; then
          echo "Installing zinit..."
          mkdir -p "$ZINIT_HOME"
          git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
      fi
      source "$ZINIT_HOME/zinit.zsh"
      autoload -Uz _zinit
      (( ''${+_comps} )) && _comps[zinit]=_zinit

      # Powerlevel10k theme
      zinit ice depth=1; zinit light romkatv/powerlevel10k

      # Command completions
      zinit ice wait'0' silent; zinit light zsh-users/zsh-completions

      # Syntax highlighting
      zinit light zsh-users/zsh-syntax-highlighting

      # Autosuggestions
      zinit light zsh-users/zsh-autosuggestions
      ### End of Zinit installer

      ZSH_COMPDUMP="''${ZSH_COMPDUMP:-''${XDG_CACHE_HOME:-$HOME/.cache}/zsh/.zcompdump}"
      [[ -d "''${ZSH_COMPDUMP:h}" ]] || mkdir -p "''${ZSH_COMPDUMP:h}"
      autoload -Uz compinit
      compinit -d "$ZSH_COMPDUMP"

      zstyle ':completion:*' matcher-list "" "m:{[:lower:]}={[:upper:]}" "+m:{[:upper:]}={[:lower:]}"
      zstyle ':completion:*' format '%B%F{blue}%d%f%b'
      zstyle ':completion:*' group-name ""
      zstyle ':completion:*:default' menu select=2

      source "$XDG_CONFIG_HOME/zsh/p10k.zsh"

      [[ -f $XDG_CONFIG_HOME/zsh.local ]] && source "$XDG_CONFIG_HOME/zsh.local"

      rehash

      [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
    '';
  };
}
