{
  lib,
  stdenvNoCC,
  fetchurl,
  makeWrapper,
  nodejs,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "chrome-devtools-mcp";
  version = "1.11.0";

  # npm の tarball はビルド済みの JS と package.json だけを含み、実行時依存は
  # バンドル済み。npm を実行時に走らせず、Node で直接起動する。
  src = fetchurl {
    url = "https://registry.npmjs.org/chrome-devtools-mcp/-/chrome-devtools-mcp-${finalAttrs.version}.tgz";
    hash = "sha256-6fCrl62VFZJ8fZ8KPfvbnqSF0oENVy5KZOuEsZLIvww=";
  };

  sourceRoot = "package";
  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib/node_modules/chrome-devtools-mcp
    cp -r . $out/lib/node_modules/chrome-devtools-mcp

    makeWrapper ${lib.getExe nodejs} $out/bin/chrome-devtools-mcp \
      --add-flags $out/lib/node_modules/chrome-devtools-mcp/build/src/bin/chrome-devtools-mcp.js
    makeWrapper ${lib.getExe nodejs} $out/bin/chrome-devtools \
      --add-flags $out/lib/node_modules/chrome-devtools-mcp/build/src/bin/chrome-devtools.js
    runHook postInstall
  '';

  meta = with lib; {
    description = "MCP server for Chrome DevTools";
    homepage = "https://github.com/ChromeDevTools/chrome-devtools-mcp";
    license = licenses.asl20;
    mainProgram = "chrome-devtools-mcp";
    platforms = platforms.unix;
  };
})
