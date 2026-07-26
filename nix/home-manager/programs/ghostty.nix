{
  lib,
  pkgs,
  ...
}:
let
  commonSettings = {
    "font-family" = "Moralerspace Neon";
    "font-size" = 12.5;
    theme = "light:Catppuccin Macchiato, dark:Catppuccin Mocha";

    "cursor-style" = "bar";
    "mouse-scroll-multiplier" = 1;

    "background-opacity" = 0.97;
    "background-blur" = 16;
    "unfocused-split-opacity" = 0.9;

    "scrollback-limit" = 10000000;
    "window-padding-balance" = true;
    "quit-after-last-window-closed" = true;

    "shell-integration-features" = "cursor,no-sudo,title,ssh-env,ssh-terminfo";

    keybind = [
      "shift+enter=text:\\n"
      "super+bracket_left=goto_split:previous"
      "super+bracket_right=goto_split:next"
      "super+comma=open_config"
      "super+ctrl+equal=equalize_splits"
      "super+digit_9=last_tab"
      "super+equal=increase_font_size:1"
      "super+minus=decrease_font_size:1"
      "super+shift+bracket_left=previous_tab"
      "super+shift+bracket_right=next_tab"
      "super+shift+comma=reload_config"
    ];
  };

  darwinSettings = {
    "macos-titlebar-style" = "tabs";
    "macos-option-as-alt" = "left";
    "auto-update" = "download";
    "auto-update-channel" = "tip";
  };

  linuxSettings = {
    "freetype-load-flags" = "hinting,force-autohint,monochrome,autohint";
    "linux-cgroup" = "single-instance";
  };
in
{
  programs.ghostty = {
    enable = true;

    # macOS は公式 DMG の再パッケージ、Linux は GTK 版を使う。
    package = if pkgs.stdenv.isDarwin then pkgs.ghostty-bin else pkgs.ghostty;
    systemd.enable = false;

    # Ghostty の自動 shell integration を使い、Home Manager からは
    # 同じスクリプトを二重に注入しない。
    enableBashIntegration = false;
    enableFishIntegration = false;
    enableZshIntegration = false;

    settings =
      commonSettings
      // lib.optionalAttrs pkgs.stdenv.isDarwin darwinSettings
      // lib.optionalAttrs pkgs.stdenv.isLinux linuxSettings;

    themes = {
      "Catppuccin Macchiato" = {
        palette = [
          "0=#494d64"
          "1=#ed8796"
          "2=#a6da95"
          "3=#eed49f"
          "4=#8aadf4"
          "5=#f5bde6"
          "6=#8bd5ca"
          "7=#a5adcb"
          "8=#5b6078"
          "9=#ec7486"
          "10=#8ccf7f"
          "11=#e1c682"
          "12=#78a1f6"
          "13=#f2a9dd"
          "14=#63cbc0"
          "15=#b8c0e0"
        ];
        background = "#24273a";
        foreground = "#cad3f5";
        "cursor-color" = "#f4dbd6";
        "cursor-text" = "#24273a";
        "selection-background" = "#5b6078";
        "selection-foreground" = "#cad3f5";
      };

      "Catppuccin Mocha" = {
        palette = [
          "0=#45475a"
          "1=#f38ba8"
          "2=#a6e3a1"
          "3=#f9e2af"
          "4=#89b4fa"
          "5=#f5c2e7"
          "6=#94e2d5"
          "7=#a6adc8"
          "8=#585b70"
          "9=#f37799"
          "10=#89d88b"
          "11=#ebd391"
          "12=#74a8fc"
          "13=#f2aede"
          "14=#6bd7ca"
          "15=#bac2de"
        ];
        background = "#1e1e2e";
        foreground = "#cdd6f4";
        "cursor-color" = "#f5e0dc";
        "cursor-text" = "#1e1e2e";
        "selection-background" = "#585b70";
        "selection-foreground" = "#cdd6f4";
      };
    };
  };
}
