{ lib, pkgs, ... }:
{
  home.sessionVariables = {
    RUST_SRC_PATH = "${pkgs.rustPlatform.rustLibSrc}";
  };

  home.file = lib.mkIf pkgs.stdenv.isDarwin {
    "Library/Application Support/Code/User/settings.json".text = builtins.toJSON {
      "rust-analyzer.server.extraEnv" = {
        RUST_SRC_PATH = "${pkgs.rustPlatform.rustLibSrc}";
      };
    };
  };

  home.packages = with pkgs; [
    cargo
    rust-analyzer
    rustc
    rustPlatform.rustLibSrc
  ];
}
