{
  config,
  lib,
  pkgs,
  ...
}:
let
  checkJsonschema = lib.getExe pkgs.check-jsonschema;
  delta = lib.getExe pkgs.delta;

  gitLogFormat = "git log --graph --color=always --date=format:'%Y-%m-%d %H:%M' --pretty=format:'%C(#a0a0a0 reverse)%h%Creset %C(cyan)%ad%Creset %C(#dd4814)%ae%Creset %C(yellow reverse)%d%Creset %n%C(white bold)%s%Creset%n'";

  # masterではなく実際に使うlazygitのタグを参照する。masterだと動かしているバイナリ
  # と検証対象がずれるうえ、check-jsonschemaはURL単位でスキーマをキャッシュするため、
  # master固定では古いスキーマを掴んだまま破壊的変更を見逃す。バージョンを含めれば
  # アップグレード時に必ずキャッシュが切り替わる。
  schemaUrl = "https://raw.githubusercontent.com/jesseduffield/lazygit/v${config.programs.lazygit.package.version}/schema/config.json";
  lazygitConfigFile = "${config.xdg.configHome}/lazygit/config.yml";

  mkOption = name: description: {
    inherit name description;
    value = name;
  };

  commitTypes = [
    (mkOption "fix" "バグや不具合の修正")
    (mkOption "feat" "新機能の追加")
    (mkOption "docs" "ドキュメントの更新や改善")
    (mkOption "style" "コードフォーマットの修正、UIのみの変更")
    (mkOption "refactor" "パフォーマンスの改善なしのコードの改善")
    (mkOption "test" "テストの追加や改善")
    (mkOption "perf" "パフォーマンスの改善")
    (mkOption "chore" "ビルドプロセスの変更や改善")
    (mkOption "ci" "CI設定の変更")
    (mkOption "build" "ビルドシステムや依存関係の変更")
    (mkOption "revert" "以前の変更の取り消し")
    (mkOption "wip" "作業中")
  ];
in
{
  programs.lazygit = {
    enable = true;
    enableZshIntegration = false;

    settings = {
      gui = {
        language = "ja";
        nerdFontsVersion = "3";
        colorScheme = "dark";
        showRandomTip = false;
        # フォーカス中のパネルを広げ、コミット一覧などを読みやすくする。
        expandFocusedSidePanel = true;
        showNumstatInFilesView = true;
        showDivergenceFromBaseBranch = "arrowAndNumber";
        commitHashLength = 7;
      };

      git = {
        # 署名コミットでも lazygit 内で完結させ、Touch ID 待ちで固まるのを避ける。
        overrideGpg = true;
        parseEmoji = true;
        branchLogCmd = "${gitLogFormat} {{branchName}} --";
        allBranchesLogCmds = [ "${gitLogFormat} --" ];
        log.showWholeGraph = true;
        # config.yml は読み取り専用で lazygit の自動移行が失敗するため、新スキーマで書く。
        diffRenderers = [
          {
            colorArg = "always";
            # dark / side-by-side などは delta が gitconfig の [delta] から読むので、
            # ここには lazygit 固有の指定だけを置く。
            command = "${delta} --paging=never --hyperlinks --hyperlinks-file-link-format=\"lazygit-edit://{path}:{line}\"";
          }
        ];
      };

      os.editPreset = "nvim";

      customCommands = [
        {
          key = "G";
          context = "localBranches";
          description = "選択したブランチのPRをブラウザーで開く";
          command = "${lib.getExe pkgs.gh} pr view --web -- {{.SelectedLocalBranch.Name | quote}}";
        }
        {
          key = "G";
          context = "commits";
          description = "現在のブランチのPRをブラウザーで開く";
          command = "${lib.getExe pkgs.gh} pr view --web";
        }
        {
          key = "<c-c>";
          context = "files";
          description = "commit files with format";
          loadingText = "Committing...";
          prompts = [
            {
              type = "menu";
              title = "What kind of commit type is it?";
              key = "Type";
              options = commitTypes;
            }
            {
              type = "input";
              title = "Scope (optional)";
              key = "Scope";
              initialValue = "";
            }
            {
              type = "input";
              title = "Enter the Message";
              key = "Message";
              initialValue = "";
            }
            {
              type = "confirm";
              title = "Commit";
              body = "Commit with the message '{{.Form.Type}}{{if .Form.Scope}}({{.Form.Scope}}){{end}}: {{.Form.Message}}'. Is this okay?";
            }
          ];
          # Quote the complete message once so user input cannot become shell syntax.
          command = ''{{$scope := ""}}{{if .Form.Scope}}{{$scope = printf "(%s)" .Form.Scope}}{{end}}git commit -m {{printf "%s%s: %s" .Form.Type $scope .Form.Message | quote}}'';
        }
        {
          key = "<c-e>";
          context = "files";
          description = "commit with body (エディターで本文まで書く)";
          # エディターを開くので lazygit を一時停止してターミナルで実行する。
          output = "terminal";
          prompts = [
            {
              type = "menu";
              title = "What kind of commit type is it?";
              key = "Type";
              options = commitTypes;
            }
            {
              type = "input";
              title = "Scope (optional)";
              key = "Scope";
              initialValue = "";
            }
          ];
          # 件名の接頭辞だけ -m で渡し、-e でエディターを開いて件名の続きと本文を書く。
          command = ''{{$scope := ""}}{{if .Form.Scope}}{{$scope = printf "(%s)" .Form.Scope}}{{end}}git commit -e -m {{printf "%s%s: " .Form.Type $scope | quote}}'';
        }
      ];
    };
  };

  home.activation.validateLazygitSettings = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    SETTINGS_FILE="${lazygitConfigFile}"

    echo "Validating lazygit config.yml..."
    if ${checkJsonschema} --default-filetype yaml --schemafile "${schemaUrl}" "$SETTINGS_FILE" 2>&1; then
      echo "lazygit config.yml validation passed"
    else
      echo "warning: lazygit config.yml validation failed (non-blocking, schema may be outdated)" >&2
    fi
  '';
}
