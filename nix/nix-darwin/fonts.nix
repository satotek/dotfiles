{ pkgs, ... }:
{
  # /Library/Fonts/Nix Fonts に入る。Homebrew の font cask と併用すると
  # Font Book に同じファミリーが重複するので、フォントはここだけで入れる。
  fonts.packages = with pkgs; [
    hackgen-nf-font # HackGen Console NF
    moralerspace # Moralerspace Neon: Ghostty, Codex
  ];
}
