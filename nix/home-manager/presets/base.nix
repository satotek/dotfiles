{ pkgs, ... }:
let
  dotbench = pkgs.buildGoModule {
    pname = "dotbench";
    version = "0.1.0";

    src = ../../../tools/dotbench;
    vendorHash = null;
  };

  roots = pkgs.buildGoModule rec {
    pname = "roots";
    version = "0.4.1";

    src = pkgs.fetchFromGitHub {
      owner = "k1LoW";
      repo = "roots";
      rev = "v${version}";
      hash = "sha256-ACMRfWY/lhc3C/KVhuUyS1rgkSHGWPxZrmYt+pXupJI=";
    };

    vendorHash = "sha256-uxcT5VzlTCxxnx09p13mot0wVbbas/otoHdg7QSDt4E=";

    ldflags = [
      "-s"
      "-w"
      "-X github.com/k1LoW/roots/version.Version=${version}"
    ];
  };
in
{
  home.packages = with pkgs; [
    # bat / eza は zsh.nix の ZENO_GIT_CAT / ZENO_GIT_TREE が前提とする
    bat
    dotbench
    deno
    eza
    fd
    fzf
    ghq
    ripgrep
    roots
    rumdl # markdown linter & formatter (nvim の markdown LSP)
    yazi
  ];

  imports = [
    ../programs/btop.nix
    ../programs/direnv.nix
    ../programs/ghostty.nix
    ../programs/git.nix
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
