{
  lib,
  stdenv,
  bubblewrap,
  codex,
  ripgrep,
}:
let
  # 0.157 の daemon 導入は、実行中の codex がこのレイアウトの中にあるときだけ
  # パッケージを ~/.codex へ複製する。外へのシンボリックリンクは複製時に拒否される。
  # store 上のハードリンクは所有者を引き継いで Nix に拒否されるので、実体をコピーする。
  target =
    if stdenv.hostPlatform.isDarwin && stdenv.hostPlatform.isAarch64 then
      "aarch64-apple-darwin"
    else if stdenv.hostPlatform.isDarwin && stdenv.hostPlatform.isx86_64 then
      "x86_64-apple-darwin"
    else if
      stdenv.hostPlatform.isLinux && stdenv.hostPlatform.isAarch64 && !stdenv.hostPlatform.isMusl
    then
      "aarch64-unknown-linux-gnu"
    else if stdenv.hostPlatform.isLinux && stdenv.hostPlatform.isAarch64 then
      "aarch64-unknown-linux-musl"
    else if
      stdenv.hostPlatform.isLinux && stdenv.hostPlatform.isx86_64 && !stdenv.hostPlatform.isMusl
    then
      "x86_64-unknown-linux-gnu"
    else if stdenv.hostPlatform.isLinux && stdenv.hostPlatform.isx86_64 then
      "x86_64-unknown-linux-musl"
    else
      throw "codex-complete: unsupported platform ${stdenv.hostPlatform.system}";

  codexBin =
    if builtins.pathExists "${codex}/libexec/codex/bin/codex" then
      "${codex}/libexec/codex/bin/codex"
    else
      "${codex}/bin/codex";

  codeModeHost =
    if builtins.pathExists "${codex}/libexec/codex/bin/codex-code-mode-host" then
      "${codex}/libexec/codex/bin/codex-code-mode-host"
    else
      "${codex}/bin/codex-code-mode-host";

  logsClient =
    if builtins.pathExists "${codex}/libexec/codex/bin/logs_client" then
      "${codex}/libexec/codex/bin/logs_client"
    else if builtins.pathExists "${codex}/bin/logs_client" then
      "${codex}/bin/logs_client"
    else
      null;

  manifest = builtins.toJSON {
    layoutVersion = 1;
    version = codex.version;
    inherit target;
    variant = "codex";
    entrypoint = "bin/codex";
    resourcesDir = "codex-resources";
    pathDir = "codex-path";
  };
in
stdenv.mkDerivation {
  pname = "codex";
  version = codex.version;

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;
  dontFixup = true;

  installPhase = ''
    runHook preInstall

    install_real() {
      local src="$1"
      local dest="$2"
      local resolved
      resolved=$(readlink -f "$src")
      mkdir -p "$(dirname "$dest")"
      cp "$resolved" "$dest"
      chmod 755 "$dest"
      if [ -L "$dest" ] || [ ! -x "$dest" ] || [ ! -f "$dest" ]; then
        echo "codex-complete: $dest is not an executable file inside the package" >&2
        exit 1
      fi
    }

    mkdir -p "$out/bin" "$out/codex-path"
    printf '%s\n' ${lib.escapeShellArg manifest} > "$out/codex-package.json"

    install_real ${lib.escapeShellArg codexBin} "$out/bin/codex"
    install_real ${lib.escapeShellArg codeModeHost} "$out/bin/codex-code-mode-host"
    install_real ${lib.escapeShellArg (lib.getExe ripgrep)} "$out/codex-path/rg"
    ${lib.optionalString (logsClient != null) ''
      install_real ${lib.escapeShellArg logsClient} "$out/bin/logs_client"
    ''}
    ${lib.optionalString stdenv.hostPlatform.isLinux ''
      mkdir -p "$out/codex-resources"
      install_real ${lib.escapeShellArg (lib.getExe' bubblewrap "bwrap")} "$out/codex-resources/bwrap"
    ''}

    if [ -d ${lib.escapeShellArg "${codex}/share"} ]; then
      mkdir -p "$out/share"
      cp -R ${lib.escapeShellArg "${codex}/share"}/. "$out/share/"
    fi

    if find "$out" -type l | grep -q .; then
      echo "codex-complete: package contains a symlink" >&2
      find "$out" -type l >&2
      exit 1
    fi

    runHook postInstall
  '';

  meta = {
    description = "Codex CLI arranged as the complete package the app-server daemon can install";
    mainProgram = "codex";
    platforms = lib.platforms.unix;
  };
}
