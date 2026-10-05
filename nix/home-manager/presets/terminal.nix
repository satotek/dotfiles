# GUI のターミナル。ヘッドレスなサーバでは select.nix の withTerminal を外す。
{ ... }:
{
  imports = [
    ../programs/ghostty.nix
    ../programs/wezterm.nix
  ];
}
