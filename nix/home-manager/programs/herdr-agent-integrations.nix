{
  config,
  lib,
  pkgs,
  ...
}:
let
  homeDirectory = config.home.homeDirectory;
in
{
  # Claude/Codex/Grok/OpenCodeの設定本体はHome Manager側で宣言し、hook scriptと
  # OpenCodeプラグインは現在のHerdrに生成させる。生成物はリポジトリへコピーしない。
  # Herdr更新後も次のnix-switchでintegrationの最新版へ追従する。
  # OpenCodeは XDG_CONFIG_HOME を見ず ~/.config/opencode に書く。cli.json は
  # リポジトリへの symlink なので、V2 プラグイン登録だけがそこへ残る。
  home.activation.installHerdrAgentIntegrations = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    herdr_bin="${config.programs.herdr.package}/bin/herdr"
    integration_tmp="$(${pkgs.coreutils}/bin/mktemp -d "''${TMPDIR:-/tmp}/herdr-integrations.XXXXXX")"
    trap '${pkgs.coreutils}/bin/rm -rf "$integration_tmp"' EXIT

    ${pkgs.coreutils}/bin/mkdir -p "$integration_tmp/claude" "$integration_tmp/codex"
    ${pkgs.coreutils}/bin/mkdir -p "${homeDirectory}/.grok" "${homeDirectory}/.config/opencode"
    CLAUDE_CONFIG_DIR="$integration_tmp/claude" "$herdr_bin" integration install claude
    CODEX_HOME="$integration_tmp/codex" "$herdr_bin" integration install codex
    GROK_HOME="${homeDirectory}/.grok" "$herdr_bin" integration install grok
    "$herdr_bin" integration install opencode

    ${pkgs.coreutils}/bin/install -Dm755 \
      "$integration_tmp/claude/hooks/herdr-agent-state.sh" \
      "${homeDirectory}/.claude/hooks/herdr-agent-state.sh"
    ${pkgs.coreutils}/bin/install -Dm755 \
      "$integration_tmp/codex/herdr-agent-state.sh" \
      "${homeDirectory}/.codex/herdr-agent-state.sh"
  '';
}
