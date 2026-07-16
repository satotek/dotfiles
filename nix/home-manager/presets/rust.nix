{ lib, pkgs, ... }:
let
  rustSrcPath = "${pkgs.rustPlatform.rustLibSrc}";
in
{
  home.sessionVariables = {
    RUST_SRC_PATH = rustSrcPath;
  };

  home.activation.setRustSrcPathForLaunchd = lib.mkIf pkgs.stdenv.isDarwin (
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      /bin/launchctl setenv RUST_SRC_PATH ${lib.escapeShellArg rustSrcPath}
    ''
  );

  home.packages = with pkgs; [
    cargo
    clippy
    rust-analyzer
    rustc
    rustfmt
    rustPlatform.rustLibSrc
  ];
}
