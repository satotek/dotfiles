{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  homeDir = config.home.homeDirectory;

  astGrepBin = "${pkgs.ast-grep}/bin/ast-grep";
  agentBrowserBin = "${pkgs.llm-agents.agent-browser}/bin/agent-browser";

  localSkillsDir = ../../../agents/skills;

  # agents/skills 配下のディレクトリをそのまま配布対象にする。
  # スキルを追加するたびにこのファイルの列挙を直し忘れるのを防ぐ。
  localSkillNames = lib.mapAttrsToList (name: _: name) (
    lib.filterAttrs (_: type: type == "directory") (builtins.readDir localSkillsDir)
  );

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

      anthropic-skills = {
        input = "anthropic-skills";
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

      yomiyasu = {
        input = "yomiyasu-skill";
        subdir = "skills";
      };

      # このリポジトリで書いた自作スキル (agents/skills)。
      local = {
        path = localSkillsDir;
      };
    };

    # ローカルスキルは agents/skills のディレクトリを自動で列挙する。
    # web-fetch だけは ax の同梱とコマンド書き換えの抑制が要るため上書きする。
    skills.explicit =
      lib.genAttrs localSkillNames (name: {
        from = "local";
      })
      // {
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

        yomiyasu = {
          from = "yomiyasu";
        };

        web-fetch = {
          from = "local";
          packages = [ pkgs.llm-agents.ax ];
          # The skill calls ./ax; keep the command as written.
          rewriteCommands = false;
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
