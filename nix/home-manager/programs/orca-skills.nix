{
  config,
  lib,
  pkgs,
  ...
}:
let
  # Orca 同梱の skill のうち、どのホストでも入れておくもの。
  skillNames = [
    "orca-cli"
    "orca-computer-use"
    "orca-emulator"
    "orchestration"
  ];

  # Mac は Homebrew cask の CLI、gem-ai は orca-server パッケージの CLI を使う。
  # Linux では素の orca が GNOME の画面読み上げと衝突するため orca-ide という名前になる。
  cliCandidates =
    if pkgs.stdenv.hostPlatform.isDarwin then
      [ "/opt/homebrew/bin/orca" ]
    else
      [ "${config.home.profileDirectory}/bin/orca-ide" ];

  enabledTargets = lib.filterAttrs (_: t: t.enable) config.programs.agent-skills.targets;
  targetDests = lib.mapAttrsToList (_: t: t.dest) enabledTargets;

  # Orca が検出しない追加アカウント (CLAUDE_CONFIG_DIR) にも同じ skill を見せる。
  claudeAccountDests = lib.mapAttrsToList (_: t: t.dest) (
    lib.filterAttrs (name: _: lib.hasPrefix "claude-" name) enabledTargets
  );

  skillArgs = lib.concatMapStringsSep " " (name: "--skill ${lib.escapeShellArg name}") skillNames;
  namesList = lib.escapeShellArgs skillNames;
in
{
  # Orca は SKILL.md のハッシュで自分の配ったものか判定し、symlink は別物とみなして
  # 置き換えを求める。中身もアプリの版と揃っている必要があるので、Nix からは配らず
  # 同期の削除対象から外し、配置はインストール済みの Orca CLI に任せる。
  programs.agent-skills.excludePatterns = map (name: "/${name}") skillNames;

  home.activation.orcaSkills = lib.hm.dag.entryAfter [ "agent-skills" ] ''
    orca_cli=""
    for candidate in ${lib.escapeShellArgs cliCandidates}; do
      if [ -x "$candidate" ]; then
        orca_cli="$candidate"
        break
      fi
    done

    if [ -z "$orca_cli" ]; then
      verboseEcho "orca-skills: Orca CLI not found, skipping"
    else
      # 以前 Nix が張った store へのリンクは Orca が別物として残すので、先に外す。
      for dest in ${lib.escapeShellArgs targetDests}; do
        for name in ${namesList}; do
          link="$dest/$name"
          if [ -L "$link" ] && case "$(readlink "$link")" in /nix/store/*) true ;; *) false ;; esac; then
            run rm -- "$link"
          fi
        done
      done

      # 同じ版の skill が入っていれば No change になるので、毎回実行してよい。
      # アプリの更新で新しい版が同梱されたときは、ここで追従する。
      # activation の umask 077 のままだと、他の agent ユーザーから読めない
      # フォルダになる。Orca がアプリから入れるときと同じ権限に揃える。
      if ! (umask 022 && run "$orca_cli" skills install ${skillArgs} >/dev/null); then
        warnEcho "orca-skills: 'orca skills install' failed; skills may be stale"
      fi

      for dest in ${lib.escapeShellArgs claudeAccountDests}; do
        for name in ${namesList}; do
          if [ -d "$HOME/.agents/skills/$name" ] && [ ! -e "$dest/$name" ]; then
            run ln -s "$HOME/.agents/skills/$name" "$dest/$name"
          fi
        done
      done
    fi
  '';
}
