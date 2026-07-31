{
  config,
  inputs,
  pkgs,
  ...
}:
let
  homeDir = config.home.homeDirectory;

  # React Aria 公式 skill は Git リポジトリではなく well-known endpoint で配布される。
  # index と skill 全体の再帰 hash を固定し、上流の無検証な変更を取り込まない。
  reactAriaSkillIndex = pkgs.fetchurl {
    url = "https://react-aria.adobe.com/.well-known/skills/index.json";
    hash = "sha256-IINLNbKLDfGNMLqj1jrJXp6SHEKPJjbIbqwzZCZyizw=";
  };
  reactAriaSkill =
    pkgs.runCommand "react-aria-skill"
      {
        nativeBuildInputs = [
          pkgs.curl
          pkgs.jq
        ];
        outputHashMode = "recursive";
        outputHashAlgo = "sha256";
        outputHash = "sha256-L1Urh1nXZ5Kw3MObHPehDixRRjZYlEiOwBT0UFiKNeA=";
      }
      ''
        skill_base="https://react-aria.adobe.com/.well-known/skills/react-aria"
        mkdir -p "$out"

        jq -r '.skills[] | select(.name == "react-aria") | .files[]' \
          ${reactAriaSkillIndex} | while IFS= read -r file; do
          target="$out/$file"
          mkdir -p "$(dirname "$target")"
          curl --fail --location --silent --show-error \
            --cacert ${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt \
            "$skill_base/$file" \
            --output "$target"
        done
      '';
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

      react-aria = {
        path = "${reactAriaSkill}";
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

      react-aria = {
        from = "react-aria";
        path = ".";
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
