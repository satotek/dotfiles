{
  config,
  lib,
  pkgs,
  ...
}:
let
  homeDirectory = config.home.homeDirectory;
  deferCompinit = !pkgs.stdenv.isLinux;
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
      save = 100000;
      extended = true;
      ignoreDups = true;
      ignoreAllDups = true;
      ignoreSpace = true;
      share = true;
      expireDuplicatesFirst = true;
    };

    shellAliases = {
      vi = "nvim";
      vim = "nvim";
      code = "code-insiders";
      sudo = "sudo ";
      python = "python3";
      ll = "ls -l";
      la = "ls -al";
      lg = "lazygit";
      "..." = "../../";
      "...." = "../../../";
      "....." = "../../../../";
    };

    envExtra = ''
      [ -f "$HOME/.config/profile" ] && . "$HOME/.config/profile"
    '';

    initContent = lib.mkMerge [
      (lib.mkBefore ''
        export ZENO_HOME="$HOME/.config/zeno"
        export ZENO_DISABLE_EXECUTE_CACHE_COMMAND=1
        export ZENO_GIT_CAT="bat --color=always"
        export ZENO_GIT_TREE="eza --tree"
        export FZF_DEFAULT_OPTS="--extended --cycle --select-1 --height 40% --reverse --border"

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

        _ghq_roots_widget() {
          local selected
          selected="$(ghq list --full-path | roots | fzf \
            --height 40% \
            --reverse \
            --border \
            --cycle \
            --select-1 \
            --preview 'eza --tree --level=2 --git-ignore --color=always --icons {} 2>/dev/null || ls -A -- {}')"
          [[ -n "$selected" ]] && cd -- "$selected"
          zle reset-prompt
        }

        _fkill_widget() {
          local pid
          pid="$(ps ax -o pid,time,command | fzf --prompt 'Kill> ' --query "$LBUFFER" | awk '{print $1}')" || {
            zle reset-prompt
            return
          }
          [[ -n "$pid" && "$pid" != "PID" ]] && kill "$pid"
          zle reset-prompt
        }

        _git_switch_branch_widget() {
          if ! git rev-parse --is-inside-work-tree &>/dev/null; then
            zle -M "Not in a Git repository"
            return
          fi

          local branch
          branch="$(git branch -a --format='%(refname:short) %(symref)' | \
            awk 'NF == 1 { print $1 }' | \
            sed 's|^origin/||' | \
            sort -u | \
            fzf --prompt 'Switch to branch: ')" || {
            zle reset-prompt
            return
          }
          [[ -n "$branch" ]] && git switch "$branch"
          zle reset-prompt
        }

        # vm への動的ポートフォワード (VS Code 風)。~/.ssh/config の ControlMaster 接続へ
        # 静的な LocalForward を書かずに都度足す/外す。`vmfwd 8090` → localhost:8090。
        vmfwd() {
          local l="$1" r="''${2:-$1}"
          [[ -z "$l" ]] && { echo "usage: vmfwd <local-port> [remote-port]"; return 1; }
          ssh -O forward -L "$l:localhost:$r" vm && echo "up   localhost:$l -> vm:$r"
        }
        vmunfwd() {
          local l="$1" r="''${2:-$1}"
          [[ -z "$l" ]] && { echo "usage: vmunfwd <local-port> [remote-port]"; return 1; }
          ssh -O cancel -L "$l:localhost:$r" vm && echo "down localhost:$l"
        }
        vmfwls() { ssh -O check vm; }   # マスター接続の生存確認

        # SOCKS プロキシ (VS Code 風: ポートごとの -L 転送なしに VM の任意ポートへ到達)。
        # ブラウザを socks5://127.0.0.1:<port> に向けると localhost が VM 側で解決される。
        vmproxy() {
          local p="''${1:-1080}"
          ssh -O forward -D "$p" vm && echo "SOCKS up:   socks5://127.0.0.1:$p (via vm)"
        }
        vmunproxy() {
          local p="''${1:-1080}"
          ssh -O cancel -D "$p" vm && echo "SOCKS down: :$p"
        }
        # SOCKS 経由の隔離 Chrome を開く。loopback バイパスを解除して localhost も VM 側へ回す。
        # 例: vmproxy && vmbrowse            (http://localhost:8090 を開く)
        #     vmbrowse http://localhost:3000
        vmbrowse() {
          local port="''${VM_SOCKS_PORT:-1080}"
          open -na "Google Chrome" --args \
            --user-data-dir="''${XDG_CACHE_HOME:-$HOME/.cache}/chrome-vm-proxy" \
            --proxy-server="socks5://127.0.0.1:$port" \
            --proxy-bypass-list="<-loopback>" \
            "''${1:-http://localhost:8090}"
        }

        cache_dir="''${XDG_CACHE_HOME:-$HOME/.local/cache}/zsh"
        sheldon_cache="$cache_dir/sheldon.zsh"
        sheldon_toml="''${XDG_CONFIG_HOME:-$HOME/.config}/sheldon/plugins.toml"
        sheldon_lock="''${XDG_DATA_HOME:-$HOME/.local/share}/sheldon/plugins.lock"
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

        if [[ -n $ZENO_LOADED ]]; then
          bindkey ' '    zeno-auto-snippet
          bindkey '^m'   zeno-auto-snippet-and-accept-line
          bindkey '^i'   zeno-completion
          bindkey '^x '  zeno-insert-space
          bindkey '^x^m' accept-line
          bindkey '^x^z' zeno-toggle-auto-snippet
          bindkey '^r'   zeno-smart-history-selection
          bindkey '^x^s' zeno-insert-snippet
          bindkey '^x^f' zeno-snippet-next-placeholder
        fi

        zle -N ghq-roots-widget _ghq_roots_widget
        bindkey '^g' ghq-roots-widget
        zle -N fkill-widget _fkill_widget
        bindkey '^x^k' fkill-widget
        zle -N git-switch-branch-widget _git_switch_branch_widget
        bindkey '^b' git-switch-branch-widget

        _deferred_compinit() {
          autoload -Uz compinit
          _comp_dump="''${XDG_CACHE_HOME:-$HOME/.local/cache}/zsh/.zcompdump"

          if [[ -r "$_comp_dump" ]]; then
            compinit -C -d "$_comp_dump"
          else
            compinit -d "$_comp_dump"
          fi

          ensure_zcompiled "$_comp_dump"
          unset _comp_dump
        }

        if ${lib.boolToString deferCompinit} && (( $+functions[zsh-defer] )); then
          zsh-defer _deferred_compinit
        else
          _deferred_compinit
        fi

        [[ -f $XDG_CONFIG_HOME/zsh.local ]] && source "$XDG_CONFIG_HOME/zsh.local"

        rehash

        _starship_cache="$cache_dir/starship.zsh"
        _starship_config="''${XDG_CONFIG_HOME:-$HOME/.config}/starship.toml"
        _starship_bin="$(command -v starship)"
        # starship init bakes the generator's absolute path into the cache, so a
        # profile-path change (e.g. nix-darwin -> standalone home-manager) leaves a
        # stale, unresolvable path that mtime checks can't catch (nix store mtimes are
        # all 1970). Also regenerate when the current binary path is absent from the cache.
        if [[ -n "$_starship_bin" ]] && { [[ ! -r "$_starship_cache" ]] || { [[ -r "$_starship_config" ]] && [[ "$_starship_config" -nt "$_starship_cache" ]]; } || [[ "$_starship_bin" -nt "$_starship_cache" ]] || ! grep -qF -- "$_starship_bin" "$_starship_cache" 2>/dev/null; }; then
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
