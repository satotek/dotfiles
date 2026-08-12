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
in
{
  programs.lazygit = {
    enable = true;
    enableZshIntegration = false;

    settings = {
      gui = {
        language = "ja";
        showIcons = true;
      };

      git = {
        parseEmoji = true;
        branchLogCmd = "${gitLogFormat} {{branchName}} --";
        allBranchesLogCmds = [ "${gitLogFormat} --" ];
        log.showWholeGraph = true;
        # lazygit 0.64 で git.pagers -> git.diffRenderers、pager -> command に改称された。
        # config.yml は Nix store のシンボリックリンクで書き込めず、lazygit の自動移行が
        # 毎回失敗するため、宣言側を新スキーマに合わせる。type は delta 向けの
        # 既定値 "stdinFilter" のままでよい。
        diffRenderers = [
          {
            colorArg = "always";
            command = "${delta} --dark --paging=never --side-by-side --line-numbers --hyperlinks --hyperlinks-file-link-format=\"lazygit-edit://{path}:{line}\"";
          }
        ];
      };

      os.editPreset = "nvim";

      customCommands = [
        {
          key = "<c-c>";
          context = "files";
          description = "commit files with format";
          loadingText = "Commiting...";
          prompts = [
            {
              type = "menu";
              title = "What kind of commit type is it?";
              key = "Type";
              options = [
                (mkOption "fix" "バグや不具合の修正")
                (mkOption "feat" "新機能の追加")
                (mkOption "docs" "ドキュメントの更新や改善")
                (mkOption "style" "コードフォーマットの修正、UIのみの変更")
                (mkOption "refactor" "パフォーマンスの改善なしのコードの改善")
                (mkOption "test" "テストの追加や改善")
                (mkOption "perf" "パフォーマンスの改善")
                (mkOption "chore" "ビルドプロセスの変更や改善")
                (mkOption "wip" "作業中")
              ];
            }
            {
              type = "input";
              title = "Enter the Message";
              key = "Message";
              initialValue = "";
            }
            {
              type = "menu";
              title = "Choose the emoji";
              key = "Emoji";
              options = [
                {
                  name = "(empty)";
                  description = "";
                  # The schema requires a non-empty value. A single space keeps
                  # the confirmation display empty and is normalized below.
                  value = " ";
                }
                (mkOption ":ambulance:" "(fix)🚑致命的なバグ修正")
                (mkOption ":bug:" "(fix)🐛バグ修正")
                (mkOption ":+1:" "(fix)👍機能改善や機能修正")
                (mkOption ":cop:" "(fix)👮セキュリティ関連の修正")
                (mkOption ":tada:" "(feat)🎉大きな機能追加")
                (mkOption ":sparkles:" "(feat)✨部分的な機能追加")
                (mkOption ":up:" "(feat)🆙依存パッケージ等のアップデート")
                (mkOption ":memo:" "(docs)📝ドキュメントの追加や修正")
                (mkOption ":bulb:" "(docs)💡ソースコードへのコメント追加や修正")
                (mkOption ":art:" "(style)🎨レイアウト関連の修正")
                (mkOption ":lipstick:" "(style)💄Lintエラーの修正やコードスタイルの修正")
                (mkOption ":recycle:" "(refactor)♻️ リファクタリング")
                (mkOption ":fire:" "(refactor)🔥コードやファイルの削除")
                (mkOption ":green_heart:" "(test)💚テストやCIの修正")
                (mkOption ":rocket:" "(perf)🚀パフォーマンス改善")
                (mkOption ":wrench:" "(chore)🔧設定ファイルの修正")
                (mkOption ":building_construction:" "(chore)🏗️アーキテクチャの修正")
                (mkOption ":construction:" "(wip)🚧作業中")
              ];
            }
            {
              type = "confirm";
              title = "Commit";
              body = "Commit with the message '{{.Form.Type}}: {{.Form.Message}}{{.Form.Emoji}}'. Is this okay?";
            }
          ];
          command = "sh -c 'type=\"{{.Form.Type}}\"; message=\"{{.Form.Message}}\"; emoji=\"{{.Form.Emoji}}\"; [ \"$emoji\" = \" \" ] && emoji=\"\"; if [ -n \"$emoji\" ]; then commit_message=\"$type: $message $emoji\"; else commit_message=\"$type: $message\"; fi; git commit -m \"$commit_message\"'";
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
