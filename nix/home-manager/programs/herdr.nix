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
  programs.herdr = {
    enable = true;
    package = pkgs.llm-agents.herdr;

    settings = {
      onboarding = false;

      session.resume_agents_on_restore = true;

      theme = {
        name = "catppuccin";
        auto_switch = true;
        dark_name = "catppuccin";
        light_name = "catppuccin-latte";
      };

      keys = {
        # nvimやzshの既存操作と競合しにくいprefixを使う。
        prefix = "ctrl+q";

        previous_agent = "prefix+shift+p";
        next_agent = "prefix+shift+n";
        rename_pane = "";
        new_workspace = "";

        split_vertical = "prefix+\\";
        split_horizontal = "prefix+minus";

        command = [
          {
            key = "prefix+alt+g";
            type = "pane";
            command = "lazygit";
            description = "lazygit";
          }
          {
            key = "prefix+alt+b";
            type = "pane";
            command = "btop";
            description = "btop system monitor";
          }
          {
            key = "prefix+t";
            type = "pane";
            command = "exec \"\${SHELL:-zsh}\"";
            description = "scratch terminal";
          }
        ];
      };

      ui = {
        agent_panel_sort = "priority";
        mouse_capture = true;
        toast.delivery = "terminal";
      };

      experimental = {
        switch_ascii_input_source_in_prefix = true;
        reveal_hidden_cursor_for_cjk_ime = true;
        cjk_ime_agents = [
          "claude"
          "codex"
        ];
      };
    };
  };

  # Claude/Codexの設定本体はHome Manager側で宣言し、hook scriptは現在のHerdrに
  # 生成させる。Herdr更新後も次のnix-switchでintegrationの最新版へ追従する。
  home.activation.installHerdrAgentIntegrations = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    herdr_bin="${config.programs.herdr.package}/bin/herdr"
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
  '';
}
