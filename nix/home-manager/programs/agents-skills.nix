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
  modernWebGuidance = pkgs.callPackage ../../packages/modern-web-guidance.nix { };
  modernWebGuidanceBin = "${modernWebGuidance}/bin/modern-web-guidance";

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

    # ~/.claude/skills は Claude アプリも使う。同期は rsync --delete なので、
    # アプリが claude.ai からダウンロードする synced と退避先の .trash を除外する。
    excludePatterns = [
      "/.system"
      "/synced"
      "/.trash"
    ];

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

      modern-web-guidance = {
        input = "modern-web-guidance-skill";
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

        modern-web-guidance = {
          from = "modern-web-guidance";
          packages = [ modernWebGuidance ];
          # rewriteCommands を切って transform で store の絶対パスへ書き換える。
          # 自動 rewrite は "modern-web-guidance" を SKILL.md 全体で
          # "./modern-web-guidance" に置換し、frontmatter の name まで壊す。
          rewriteCommands = false;
          transform =
            { original, dependencies }:
            let
              # 上流は npx 実行を前提にしている。nix では store のバイナリを直接叩くので、
              # その前提の節ごと差し替える。見出しが変わったら評価時に落ちるので気付ける。
              npxSection = lib.splitString "## Using npx / pnpx" original;
              guidelinesSection = lib.splitString "## Guidelines" (lib.last npxSection);

              body = ''
                ${lib.head npxSection}## Running the CLI

                - **Provided by Nix**: `modern-web-guidance` is a pinned Nix store binary. It bundles its own guide corpus, runs offline, and needs neither network access nor `npx`.
                - **Telemetry**: disabled by the wrapper.

                ## Guidelines${lib.last guidelinesSection}
              '';

              patched =
                builtins.replaceStrings
                  [
                    "Run `modern-web-guidance` directly with `npx` using a"
                    "npx -y modern-web-guidance@latest search \"<query>\" --skill-version 2026_11_09-5bcc021b"
                    "npx -y modern-web-guidance@latest "
                    "name: modern-web-guidance\n"
                  ]
                  [
                    "Run `${modernWebGuidanceBin}` using a"
                    "${modernWebGuidanceBin} search \"<query>\""
                    "${modernWebGuidanceBin} "
                    "name: modern-web-guidance\nallowed-tools: Bash(${modernWebGuidanceBin}:*)\n"
                  ]
                  body;
            in
            ''
              ${patched}

              ${dependencies}
            '';
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
