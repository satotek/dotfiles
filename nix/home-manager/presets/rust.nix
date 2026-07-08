{ pkgs, ... }:
{
  home.sessionVariables = {
    RUST_SRC_PATH = "${pkgs.rustPlatform.rustLibSrc}";
  };

  home.packages = with pkgs; [
    cargo
    rust-analyzer
    rustc
    rustPlatform.rustLibSrc
  ];
}
