{
  lib,
  stdenvNoCC,
  fetchurl,
}:

let
  version = "0.1.14";

  # 上流はビルド済みバイナリだけを配布する（Linux 版は静的リンク）。ソースビルドには
  # Zig 0.16 と ghostty-vt のサブモジュールが要るため、リリースを固定して使う。
  # `hc update` は自己更新なので Nix 管理下では使わず、version を上げて追従する。
  release =
    {
      x86_64-linux = {
        target = "linux-x86_64";
        hash = "sha256-6dur3q0M4M495RtvVMyVSe/tu0Gy+ESLaTKrDRRCND4=";
      };
      aarch64-linux = {
        target = "linux-aarch64";
        hash = "sha256-Gc72ouUvFMIsS28/2vGkYtLa/HjosD+rv61bBjR3o3A=";
      };
      aarch64-darwin = {
        target = "macos-aarch64";
        hash = "sha256-ylJDKdLgYwIZVQBV3McfQqr9hfujVuDVQ9b1EkRIeXA=";
      };
      x86_64-darwin = {
        target = "macos-x86_64";
        hash = "sha256-jhbsQ6F2VvgOfX+YKSv3EMYMSu/1KUHMqY+yTzfzUCg=";
      };
    }
    .${stdenvNoCC.hostPlatform.system}
      or (throw "herdr-core: unsupported system ${stdenvNoCC.hostPlatform.system}");
in
stdenvNoCC.mkDerivation {
  pname = "herdr-core";
  inherit version;

  src = fetchurl {
    name = "herdr-core-${version}-${release.target}.tar.gz";
    url = "https://releases.herdr.dev/core/${version}/herdr-core-${release.target}.tar.gz";
    inherit (release) hash;
  };

  # アーカイブ直下に実行ファイルが1つだけ入っている。
  sourceRoot = ".";

  # 配布物は改変せずに置く。strip すると macOS の署名が壊れて起動できなくなる。
  dontStrip = true;
  dontPatchELF = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    install -Dm755 herdr-core $out/bin/herdr-core
    # `hc` は herdr-core の短い名前。上流も同じ並びで配布している。
    ln -s herdr-core $out/bin/hc

    runHook postInstall
  '';

  meta = {
    description = "Terminal runtime that keeps coding agents alive after you leave";
    homepage = "https://herdr.dev/core";
    changelog = "https://github.com/herdrdev/herdr-core/releases";
    license = lib.licenses.asl20;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    maintainers = [ ];
    mainProgram = "herdr-core";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
  };
}
