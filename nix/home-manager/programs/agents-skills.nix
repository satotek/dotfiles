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

      herdr = {
        input = "herdr-skill";
        subdir = "skills";
      };

      # hunk 公式 skill (hunk-review)。パッケージに同梱されているため flake input 不要。
      # ${hunk}/skills/hunk-review/SKILL.md の単一ファイルツリーをそのまま source にする
      # (herdr のような symlink 混入が無いので runCommand 抽出も不要)。
      # CLI 本体 (pkgs.llm-agents.hunk) は programs/hunk.nix で導入済み＝skill と同一パッケージ由来。
      hunk = {
        path = "${pkgs.llm-agents.hunk}/skills";
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

      herdr = {
        from = "herdr";
      };

      hunk-review = {
        from = "hunk";
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
