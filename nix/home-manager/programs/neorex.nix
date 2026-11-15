{ inputs, pkgs, ... }:
{
  # Rex のクライアントは今のところ macOS にしか無いため、
  # 読み込み側（platforms/darwin.nix）で macOS のホストにだけ適用する。
  home.packages = [
    inputs.neorex.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
