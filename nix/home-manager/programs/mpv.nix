{ ... }:
{
  # 本体は nix-darwin/homebrew-video.nix の Homebrew 版 mpv。ここでは設定だけ書く。
  programs.mpv = {
    enable = true;
    package = null;
    # SVP が mpv を操作するための推奨設定。
    config = {
      input-ipc-server = "/tmp/mpvsocket";
      hwdec-codecs = "all";
      hwdec = "auto-copy";
      opengl-early-flush = "no";
      hr-seek-framedrop = "no";
    };
  };
}
