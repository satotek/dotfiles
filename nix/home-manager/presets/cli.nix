{ pkgs, ... }:
let
  zshBench = pkgs.stdenvNoCC.mkDerivation {
    pname = "zsh-bench";
    version = "unstable-2026-04-27";
    src = pkgs.fetchFromGitHub {
      owner = "romkatv";
      repo = "zsh-bench";
      rev = "28b1b1bc888159f0a2cf50f9d29381758341aba1";
      hash = "sha256-dsHGpDTweDqJdLhO/9th2kDt56crfjqkTKBilEi9RaY=";
    };
    nativeBuildInputs = [ pkgs.makeWrapper ];
    installPhase = ''
      mkdir -p $out/share/zsh-bench $out/bin
      cp -r zsh-bench internal $out/share/zsh-bench/
      patchShebangs $out/share/zsh-bench
      makeWrapper $out/share/zsh-bench/zsh-bench $out/bin/zsh-bench \
        --prefix PATH : ${
          pkgs.lib.makeBinPath (
            [
              pkgs.zsh
              pkgs.coreutils
              pkgs.git
            ]
            ++ pkgs.lib.optional pkgs.stdenv.hostPlatform.isLinux pkgs.util-linux
          )
        }
    '';
  };
  dotbench = pkgs.buildGoModule {
    pname = "dotbench";
    version = "0.1.0";

    src = ../../../tools/dotbench;
    vendorHash = "sha256-7K17JaXFsjf163g5PXCb5ng2gYdotnZ2IDKk8KFjNj0=";
    nativeBuildInputs = [ pkgs.installShellFiles ];
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
    zshBench
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
