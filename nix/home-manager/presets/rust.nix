{ pkgs, ... }:
let
  rustSrcPath = "${pkgs.rustPlatform.rustLibSrc}";
in
{
  home.sessionVariables = {
    RUST_SRC_PATH = rustSrcPath;
  };

  home.packages = with pkgs; [
    cargo
    clippy
    rust-analyzer
    rustc
    rustfmt
    rustPlatform.rustLibSrc
  ];
}
