{
  config,
  inputs,
  pkgs,
  ...
}:
let
  homeDir = config.home.homeDirectory;
in
{
  imports = [
    inputs.agent-skills.homeManagerModules.default
  ];

  # agent-browser skill のランタイム本体 (Rust製CLI)。
  # skill 定義 (skills.explicit.agent-browser) と同居させ、
  # skill だけ入って CLI が無い状態を防ぐ。
  home.packages = [ pkgs.llm-agents.agent-browser ];

  programs.agent-skills = {
    enable = true;

    sources = {
      vercel-agent-skills = {
        input = "vercel-agent-skills";
        subdir = "skills";
      };

      vercel-skills = {
        input = "vercel-skills";
        subdir = "skills";
      };

      vercel-next-skills = {
        input = "vercel-next-skills";
        subdir = "skills";
      };

      anthropic-skills = {
        input = "anthropic-skills";
        subdir = "skills";
      };

      mattpocock-skills = {
        input = "mattpocock-skills";
        subdir = "skills";
      };

      agent-browser = {
        input = "agent-browser";
        subdir = "skills";
      };
    };

    skills.explicit = {
      find-skills = {
        from = "vercel-skills";
      };

      frontend-design = {
        from = "anthropic-skills";
      };

      vercel-react-best-practices = {
        from = "vercel-agent-skills";
        path = "react-best-practices";
      };

      vercel-composition-patterns = {
        from = "vercel-agent-skills";
        path = "composition-patterns";
      };

      next-best-practices = {
        from = "vercel-next-skills";
      };

      web-design-guidelines = {
        from = "vercel-agent-skills";
      };

      grill-me = {
        from = "mattpocock-skills";
        path = "productivity/grill-me";
      };

      agent-browser = {
        from = "agent-browser";
      };
    };

    targets.agents = {
      enable = true;
      dest = "${homeDir}/.agents/skills";
      structure = "symlink-tree";
    };

    targets.claude = {
      enable = true;
      dest = "${homeDir}/.claude/skills";
      structure = "symlink-tree";
    };
  };
}
