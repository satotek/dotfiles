{ pkgs, ... }:
{
  imports = [
    ../programs/aerospace.nix
    ../programs/karabiner.nix
    ../programs/nh.nix
  ];

  # Xcode.app は Nix にも Homebrew にも載せず、xcodes で導入と切り替えを行う。
  home.packages = [
    pkgs.xcodes
  ];
}
