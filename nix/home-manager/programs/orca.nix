{
  config,
  lib,
  pkgs,
  ...
}:
let
  jq = lib.getExe pkgs.jq;
  homeDir = config.home.homeDirectory;

  telemetryEnv = {
    ORCA_TELEMETRY_DISABLED = "1";
    DO_NOT_TRACK = "1";
  };

  # Agent Session History に全アカウントの履歴を出すため、Claude の config
  # ディレクトリを全部知らせる。Orca は自分の CLAUDE_CONFIG_DIR と、hook 付きの
  # セッションが書き込んだのを見たディレクトリしか走査しない。
  claudeConfigDirs = [
    "${homeDir}/.claude"
    "${homeDir}/.claude_work"
  ];
in
lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
  # Orca 本体は nix-darwin の homebrew cask (stablyai/orca/orca) で入れる。

  home.sessionVariables = telemetryEnv;

  # Dock から起動したアプリはシェルの環境変数を継承しない。Orca はテレメトリの
  # 同意を自身の環境変数で判断するので、launchd のユーザー環境にも入れる。
  launchd.agents.orca-env = {
    enable = true;
    config = {
      ProgramArguments = [
        "/bin/sh"
        "-c"
        (lib.concatStringsSep "; " (
          lib.mapAttrsToList (name: value: "/bin/launchctl setenv ${name} ${value}") telemetryEnv
        ))
      ];
      RunAtLoad = true;
    };
  };

  # Orca は観測したディレクトリをこのファイルに保持し、新しいものを先頭へ足していく。
  # 置き換えると Orca 側の記録を消すので、宣言分を差分だけマージする。
  home.activation.seedOrcaClaudeConfigDirs = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    ORCA_DATA="$HOME/Library/Application Support/orca"
    OBSERVED="$ORCA_DATA/claude-observed-config-dirs.json"
    DECLARED='${builtins.toJSON claudeConfigDirs}'
    run mkdir -p "$ORCA_DATA"
    if [ -f "$OBSERVED" ]; then
      MERGED="$(${jq} -c --argjson declared "$DECLARED" '. + ($declared - .)' "$OBSERVED")"
    else
      MERGED="$DECLARED"
    fi
    if [ -z "''${DRY_RUN:-}" ]; then
      TEMP_FILE="$(mktemp "$ORCA_DATA/.claude-observed-config-dirs.XXXXXX")"
      printf '%s' "$MERGED" > "$TEMP_FILE"
      chmod 600 "$TEMP_FILE"
      mv "$TEMP_FILE" "$OBSERVED"
    fi
  '';
}
