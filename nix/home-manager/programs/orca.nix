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

  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;

  # Orca 本体は Mac では nix-darwin の homebrew cask (stablyai/orca/orca)、Linux では
  # orca-server.nix の常駐サーバー。どちらも無いホストでは何もしない。
  hasOrca = isDarwin || config.systemd.user.services ? orca-server;

  # Orca のデータの置き場所。Linux は Electron の既定どおり XDG の config 側になる。
  orcaDataDir =
    if isDarwin then "${homeDir}/Library/Application Support/orca" else "${config.xdg.configHome}/orca";
in
lib.mkIf hasOrca {
  home.sessionVariables = telemetryEnv;

  # Dock から起動したアプリはシェルの環境変数を継承しない。Orca はテレメトリの
  # 同意を自身の環境変数で判断するので、launchd のユーザー環境にも入れる。
  launchd.agents.orca-env = lib.mkIf isDarwin {
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
    ORCA_DATA=${lib.escapeShellArg orcaDataDir}
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

  # Orca が管理する Claude アカウントは、どれもログインシェルの config (~/.claude)
  # の projects を共有する。~/.claude_work で記録したセッションは一覧に出ても
  # 再開できないので、元の場所は動かさずに ~/.claude/projects からも引けるようにする。
  # Orca の再開処理は <id>.jsonl を lstat().isFile() で探し symlink を読み飛ばすため、
  # ファイルはハードリンクにする (同じボリューム内)。どちらの名前で追記しても
  # 同じ記録に書かれる。memory などのフォルダは symlink でつなぐ。
  home.activation.linkClaudeTranscriptsForOrca = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    shared="${homeDir}/.claude/projects"
    for source in ${
      lib.escapeShellArgs (
        map (dir: "${dir}/projects") (lib.remove "${homeDir}/.claude" claudeConfigDirs)
      )
    }; do
      [ -d "$source" ] || continue
      for slug_dir in "$source"/*/; do
        slug="$(basename "$slug_dir")"
        run mkdir -p "$shared/$slug"
        for entry in "$slug_dir"*; do
          [ -e "$entry" ] || continue
          name="$(basename "$entry")"
          target="$shared/$slug/$name"
          if [ -e "$target" ] || [ -L "$target" ]; then
            continue
          elif [ -f "$entry" ]; then
            run ln "$entry" "$target"
          else
            run ln -s "$entry" "$target"
          fi
        done
      done
    done
  '';
}
