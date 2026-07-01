{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # bat / eza は zsh.nix の ZENO_GIT_CAT / ZENO_GIT_TREE が前提とする
    bat
    curl
    deno
    eza
    fd
    fzf
    ghq
    ripgrep
    rumdl # markdown linter & formatter (nvim の markdown LSP)
    yazi
  ];

  imports = [
    ../programs/agents-skills.nix
    ../programs/btop.nix
    ../programs/claude-code.nix
    ../programs/codex.nix
    ../programs/direnv.nix
    ../programs/ghostty.nix
    ../programs/git.nix
    ../programs/herdr.nix
    ../programs/lazygit.nix
    ../programs/nvim.nix
    ../programs/sheldon.nix
    ../programs/starship.nix
    ../programs/tmux.nix
    ../programs/wezterm.nix
    ../programs/wget.nix
    ../programs/zeno.nix
    ../programs/zoxide.nix
    ../programs/zsh.nix
  ];
}
