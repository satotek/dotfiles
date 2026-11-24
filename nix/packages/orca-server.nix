{
  lib,
  stdenvNoCC,
  fetchurl,
}:

let
  # リリースの orca-server-sha256sums.txt の値を SRI に直したもの。
  sources = {
    x86_64-linux = {
      arch = "x64";
      hash = "sha256-vk4gVpbQOHZ3oXYp+cIK4fQyIG6xxOKGTSFunMMzHTU=";
    };
    aarch64-linux = {
      arch = "arm64";
      hash = "sha256-WysQ2mhR23+BVCKyFH6zaXVFZ7M2Jz7ceXFkNFijGlg=";
    };
  };
  source =
    sources.${stdenvNoCC.hostPlatform.system}
      or (throw "orca-server: unsupported system ${stdenvNoCC.hostPlatform.system}");
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "orca-server";
  version = "1.4.273";

  # デスクトップ版を含まないサーバー単体の配布物。同梱の Node と orcad、
  # orca-ide CLI だけで動く。
  src = fetchurl {
    url = "https://github.com/stablyai/orca/releases/download/v${finalAttrs.version}/orca-server-linux-${source.arch}.tar.gz";
    inherit (source) hash;
  };

  # 同梱の Node とネイティブモジュールはホストの glibc とローダーを前提にしたビルド。
  # 中身には手を入れず、FHS のローダーがある非 NixOS ホスト (gem-ai の Ubuntu) で使う。
  dontConfigure = true;
  dontBuild = true;
  dontFixup = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib/orca-server $out/bin
    cp -r . $out/lib/orca-server
    # ランチャーは readlink -f で自分の位置を解決するので、symlink で PATH に出せる。
    ln -s $out/lib/orca-server/bin/orca-ide $out/bin/orca-ide
    runHook postInstall
  '';

  meta = {
    description = "Headless Orca runtime server (orcad) and orca-ide CLI";
    homepage = "https://orca.dev/";
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    mainProgram = "orca-ide";
    platforms = builtins.attrNames sources;
  };
})
