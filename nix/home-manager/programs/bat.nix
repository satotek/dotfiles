{ pkgs, ... }:
{
  programs.bat = {
    enable = true;
    # ターミナル(Ghostty)と btop に合わせる。
    config.theme = "Catppuccin Mocha";
    extraPackages = with pkgs.bat-extras; [
      batman # man を bat で色付けして読む
      batdiff
    ];
  };
}
