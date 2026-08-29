{
  config,
  inputs,
  pkgs,
  ...
}:
let
  homeDir = config.home.homeDirectory;

  astGrepBin = "${pkgs.ast-grep}/bin/ast-grep";
  agentBrowserBin = "${pkgs.llm-agents.agent-browser}/bin/agent-browser";

  # React Aria 公式 skill は Git リポジトリではなく well-known endpoint で配布される。
  # index と skill 全体の再帰 hash を固定し、上流の無検証な変更を取り込まない。
  reactAriaSkillIndex = pkgs.fetchurl {
    url = "https://react-aria.adobe.com/.well-known/skills/index.json";
    hash = "sha256-KyoDNoEysqdILf+7Wi74cEtO4Fd1Kx8JOmyw+dR9GbU=";
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
        outputHash = "sha256-aJeRYH7EPoakb8opsnzMjdXveyFbhvR/g+sc0RwCF6s=";
      }
      ''
        skill_base="https://react-aria.adobe.com/.well-known/skills/react-aria"
        mkdir -p "$out"

        jq -r '.skills[] | select(.name == "react-aria") | .files[]' \
          ${reactAriaSkillIndex} | while IFS= read -r file; do
          target="$out/$file"
          mkdir -p "$(dirname "$target")"
          curl --fail --location --silent --show-error \
            --retry 5 \
            --retry-all-errors \
            --retry-delay 1 \
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
  # skill 側は transform で store の絶対パスを直接叩くため PATH に依存しないが、
  # 対話シェルから手で叩けるよう同じ derivation を PATH にも入れておく。
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

      ast-grep = {
        input = "ast-grep-skill";
        subdir = "ast-grep/skills";
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

      webapp-testing = {
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

      next-dev-loop = {
        from = "vercel-next-skills";
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
        packages = [ pkgs.llm-agents.agent-browser ];
        # rewriteCommands を切って transform で絶対パスへ書き換える。
        # 自動 rewrite は SKILL.md 全体を無差別に置換するため frontmatter の
        # name: まで "./agent-browser" に化ける。ここでは実際のコマンド行と
        # allowed-tools だけを差し替え、npm 導線は削除する。
        rewriteCommands = false;
        transform =
          { original, dependencies }:
          let
            patched =
              builtins.replaceStrings
                [
                  "Bash(agent-browser:*), Bash(npx agent-browser:*)"
                  "Install: `npm i -g agent-browser && agent-browser install`\n\n"
                  "agent-browser skills "
                  "`agent-browser`"
                ]
                [
                  "Bash(${agentBrowserBin}:*)"
                  ""
                  "${agentBrowserBin} skills "
                  "`${agentBrowserBin}`"
                ]
                original;
          in
          ''
            ${patched}

            ${dependencies}
          '';
      };

      ast-grep = {
        from = "ast-grep";
        path = "ast-grep";
        packages = [ pkgs.ast-grep ];
        # rewriteCommands を切って transform で絶対パスへ書き換える。
        # 自動 rewrite は "ast-grep" という文字列を SKILL.md 全体で "./ast-grep"
        # に置換するため、frontmatter の name/description や散文まで壊れる。
        # ここでは実際に CLI を起動する行だけを Nix store の絶対パスに差し替える。
        rewriteCommands = false;
        transform =
          { original, dependencies }:
          let
            patched =
              builtins.replaceStrings
                [
                  "| ast-grep "
                  "ast-grep scan "
                  "ast-grep run "
                ]
                [
                  "| ${astGrepBin} "
                  "${astGrepBin} scan "
                  "${astGrepBin} run "
                ]
                original;
          in
          ''
            ${patched}

            ${dependencies}
          '';
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
