{
  config,
  inputs,
  ...
}:
let
  homeDir = config.home.homeDirectory;
in
{
  imports = [
    inputs.agent-skills.homeManagerModules.default
  ];

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

      next-best-practices = {
        from = "vercel-next-skills";
      };

      web-design-guidelines = {
        from = "vercel-agent-skills";
      };
    };

    targets.agents = {
      enable = true;
      dest = "${homeDir}/.agents/skills";
      structure = "symlink-tree";
    };

    excludePatterns = [
      "/vercel-composition-patterns"
    ];
  };
}
