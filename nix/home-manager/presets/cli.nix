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
    aria2
    dotbench
    fd
    ghq
    roots
    xh
  ];

  imports = [
    ../programs/bat.nix
    ../programs/btop.nix
    ../programs/eza.nix
    ../programs/gh.nix
    ../programs/nix-your-shell.nix
    ../programs/ripgrep.nix
    ../programs/yazi.nix
  ];
}
