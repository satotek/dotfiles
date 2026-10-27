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
  # Claude/Codex/Cursor/Grok/OpenCode/ompの設定本体はHome Manager側で宣言し、hook scriptと
  # OpenCodeプラグインは現在のHerdrに生成させる。生成物はリポジトリへコピーしない。
  # Herdr更新後も次のnix-switchでintegrationの最新版へ追従する。
  home.activation.installHerdrAgentIntegrations = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    herdr_bin="${config.programs.herdr.package}/bin/herdr"
    integration_tmp="$(${pkgs.coreutils}/bin/mktemp -d "''${TMPDIR:-/tmp}/herdr-integrations.XXXXXX")"
    trap '${pkgs.coreutils}/bin/rm -rf "$integration_tmp"' EXIT

    run ${pkgs.coreutils}/bin/mkdir -p "$integration_tmp/claude" "$integration_tmp/codex"
    run ${pkgs.coreutils}/bin/mkdir -p "${homeDirectory}/.grok" "${homeDirectory}/.config/opencode" "${homeDirectory}/.cursor" "${homeDirectory}/.omp/agent/extensions"
    run ${pkgs.coreutils}/bin/env CLAUDE_CONFIG_DIR="$integration_tmp/claude" "$herdr_bin" integration install claude
    run ${pkgs.coreutils}/bin/env CODEX_HOME="$integration_tmp/codex" "$herdr_bin" integration install codex
    run ${pkgs.coreutils}/bin/env GROK_HOME="${homeDirectory}/.grok" "$herdr_bin" integration install grok
    run "$herdr_bin" integration install opencode
    # omp は extensions/ が無いと install を拒むので、上で作っておく。
    run "$herdr_bin" integration install omp
    # 既存の hooks.json は残し、sessionStart だけを足す。
    run "$herdr_bin" integration install cursor

    run ${pkgs.coreutils}/bin/install -Dm755 \
      "$integration_tmp/claude/hooks/herdr-agent-state.sh" \
      "${homeDirectory}/.claude/hooks/herdr-agent-state.sh"
    run ${pkgs.coreutils}/bin/install -Dm755 \
      "$integration_tmp/codex/herdr-agent-state.sh" \
      "${homeDirectory}/.codex/herdr-agent-state.sh"
  '';
}
