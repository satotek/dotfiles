{
  config,
  lib,
  pkgs,
  ...
}:
let
  homeDirectory = config.home.homeDirectory;
  dotfilesDir = "${homeDirectory}/dotfiles";
in
{
  # config.toml だけを可変 symlink で配置する。
  # herdr の ~/.config/herdr は runtime(socket/log/session.json)と config が同居するため、
  # ディレクトリ丸ごとではなく単一ファイルのみを対象にする。
  # mkOutOfStoreSymlink なので herdr 自身の書き換え(Settings / config reset-keys)も可能で、
  # キーバインド調整は repo の config.toml を編集して `herdr server reload-config` するだけで済む
  # (nix-switch 不要)。
  xdg.configFile."herdr/config.toml".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/.config/herdr/config.toml";

  # Claude/Codexの設定本体はHome Manager側で宣言し、hook scriptは現在のHerdrに
  # 生成させる。Herdr更新後も次のnix-switchでintegrationの最新版へ追従する。
  home.activation.installHerdrAgentIntegrations = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    herdr_bin=""
    for candidate in /opt/homebrew/bin/herdr "${homeDirectory}/.local/bin/herdr"; do
      if [ -x "$candidate" ]; then
        herdr_bin="$candidate"
        break
      fi
    done

    if [ -z "$herdr_bin" ]; then
      echo "WARNING: herdr not found; skipping agent integration hooks" >&2
    else
      integration_tmp="$(${pkgs.coreutils}/bin/mktemp -d "''${TMPDIR:-/tmp}/herdr-integrations.XXXXXX")"
      trap '${pkgs.coreutils}/bin/rm -rf "$integration_tmp"' EXIT

      ${pkgs.coreutils}/bin/mkdir -p "$integration_tmp/claude" "$integration_tmp/codex"
      CLAUDE_CONFIG_DIR="$integration_tmp/claude" "$herdr_bin" integration install claude
      CODEX_HOME="$integration_tmp/codex" "$herdr_bin" integration install codex

      ${pkgs.coreutils}/bin/install -Dm755 \
        "$integration_tmp/claude/hooks/herdr-agent-state.sh" \
        "${homeDirectory}/.claude/hooks/herdr-agent-state.sh"
      ${pkgs.coreutils}/bin/install -Dm755 \
        "$integration_tmp/codex/herdr-agent-state.sh" \
        "${homeDirectory}/.codex/herdr-agent-state.sh"
    fi
  '';
}
