{ pkgs, ... }:
let
  dotbench = pkgs.buildGoModule {
    pname = "dotbench";
    version = "0.1.0";

    src = ../../../tools/dotbench;
    vendorHash = "sha256-BDyg4x042o2XcYRdbkNpX3q3xHssbtgYNTv/LE4zvoQ=";
    nativeBuildInputs = [ pkgs.installShellFiles ];
    # 対話計測のテストは擬似端末で本物の zsh を起動する。無いと skip されて検証されない。
    nativeCheckInputs = [ pkgs.zsh ];
    ldflags = [ "-X main.version=0.1.0" ];
    postInstall = ''
      installShellCompletion --cmd dotbench \
        --bash <($out/bin/dotbench completion bash) \
        --zsh <($out/bin/dotbench completion zsh) \
        --fish <($out/bin/dotbench completion fish)
    '';
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
    ../programs/atuin.nix
    ../programs/bat.nix
    ../programs/btop.nix
    ../programs/eza.nix
    ../programs/gh.nix
    ../programs/herdr.nix
    ../programs/hunk.nix
    ../programs/nix-your-shell.nix
    ../programs/ripgrep.nix
    ../programs/yazi.nix
  ];
}
