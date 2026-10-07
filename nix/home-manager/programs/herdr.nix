{ config, pkgs, ... }:
{
  programs.herdr = {
    enable = true;
    package = pkgs.llm-agents.herdr;

    settings = {
      onboarding = false;

      session.resume_agents_on_restore = true;

      # OS標準zshではNix製のバイナリモジュールとglibcが一致しない。
      terminal.default_shell = "${config.programs.zsh.package}/bin/zsh";

      theme = {
        name = "terminal";
        auto_switch = false;
        custom.selection_bg = "black";
      };

      keys = {
        # nvimやzshの既存操作と競合しにくいprefixを使う。
        prefix = "ctrl+q";

        previous_agent = "prefix+shift+p";
        next_agent = "prefix+shift+n";
        rename_pane = "";
        new_workspace = "";

        navigate_workspace_up = "k";
        navigate_workspace_down = "j";

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
            command = "exec \"${config.programs.zsh.package}/bin/zsh\"";
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
}
