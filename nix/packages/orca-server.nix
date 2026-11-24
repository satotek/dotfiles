{
  lib,
  stdenvNoCC,
  fetchurl,
  dpkg,
}:

let
  # .deb にはチェックサムが公開されていないので、取得したファイルから計算した値。
  sources = {
    x86_64-linux = {
      arch = "amd64";
      hash = "sha256-jjo0l8IIvA1TwM/Dzm/vfxz2WTYSRu7k09oMz3PrTRU=";
    };
    aarch64-linux = {
      arch = "arm64";
      hash = "sha256-lLvEEKfyhwG4uekoFnTAQYpHMaXNetlimsqQCItMhmw=";
    };
  };
  source =
    sources.${stdenvNoCC.hostPlatform.system}
      or (throw "orca-server: unsupported system ${stdenvNoCC.hostPlatform.system}");
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "orca-server";
  version = "1.4.273";

  # サーバー単体の配布物 (orca-server-linux-*.tar.gz) は、ブラウザから使う
  # web client (out/renderer/web-index.html) を含まない。Orca を入れられない端末から
  # ブラウザで使えるよう、デスクトップ版の .deb を使う。serve は Electron を
  # Node モードで動かすだけで、ウィンドウは開かない。
  src = fetchurl {
    url = "https://github.com/stablyai/orca/releases/download/v${finalAttrs.version}/orca-ide_${finalAttrs.version}_${source.arch}.deb";
    inherit (source) hash;
  };

  nativeBuildInputs = [ dpkg ];

  unpackPhase = ''
    runHook preUnpack
    dpkg-deb -x $src .
    runHook postUnpack
  '';

  # 同梱の Electron とネイティブモジュールはホストの glibc とローダー、GTK などの
  # 共有ライブラリを前提にしたビルド。中身には手を入れず、それらが apt で入っている
  # 非 NixOS ホスト (gem-ai の Ubuntu) で使う。
  dontConfigure = true;
  dontBuild = true;
  dontFixup = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib $out/bin
    cp -r opt/Orca $out/lib/orca
    # ランチャーは symlink を辿って resources の位置を決めるので、PATH に出せる。
    ln -s $out/lib/orca/resources/bin/orca-ide $out/bin/orca-ide
    runHook postInstall
  '';

  meta = {
    description = "Orca desktop build used headless for orca-ide serve and its web client";
    homepage = "https://orca.dev/";
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    mainProgram = "orca-ide";
    platforms = builtins.attrNames sources;
  };
})
