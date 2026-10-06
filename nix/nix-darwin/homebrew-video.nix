{ ... }:
{
  # SVP でフレーム補間して再生する一式。SVP は VapourSynth 対応の mpv を IPC で
  # 操作するので、mpv は Homebrew 版を使う。mpv の設定は
  # home-manager/programs/mpv.nix。やめるときは両方を消す。
  homebrew = {
    brews = [ "mpv" ];
    casks = [
      "iina"
      "svp"
    ];
  };
}
