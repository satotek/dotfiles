{
  lib,
  stdenvNoCC,
  fetchurl,
  makeWrapper,
  nodejs,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "modern-web-guidance";
  version = "1.0.0";

  # npm の tarball はガイド本文とオフライン検索用の埋め込みデータを同梱した
  # 自己完結パッケージで、実行時依存は無い。Node だけで動くので npm は使わない。
  src = fetchurl {
    url = "https://registry.npmjs.org/modern-web-guidance/-/modern-web-guidance-${finalAttrs.version}.tgz";
    hash = "sha256-vXqmI60QcQqa1meP28wLiQyQPFT9ar/BJv9C3gHw5Xc=";
  };

  sourceRoot = "package";
  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib/node_modules/modern-web-guidance
    cp -r . $out/lib/node_modules/modern-web-guidance

    makeWrapper ${lib.getExe nodejs} $out/bin/modern-web-guidance \
      --add-flags $out/lib/node_modules/modern-web-guidance/skills/modern-web-guidance/modern-web.mjs \
      --set-default DISABLE_TELEMETRY 1
    runHook postInstall
  '';

  meta = with lib; {
    description = "Coding agent skill CLI for modern web platform best practices";
    homepage = "https://github.com/GoogleChrome/modern-web-guidance";
    license = licenses.asl20;
    mainProgram = "modern-web-guidance";
    platforms = platforms.unix;
  };
})
