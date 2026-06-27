{ pkgs, ... }:
{
  home.packages = [ pkgs.delta ];

  programs.git = {
    enable = true;
    includes = [
      { path = "~/.config/git.local"; }
    ];
    ignores = [
      ".DS_Store"
      "thumbs.db"
      ".direnv/"
      "**/.claude/settings.local.json"
    ];
    settings = {
      credential.helper = "store --file ~/.local/state/git/credentials";
      color.ui = true;
      init.defaultBranch = "main";
      core = {
        pager = "delta --side-by-side";
        editor = "vim";
        autocrlf = "input";
      };
      interactive.diffFilter = "delta --color-only";
      delta = {
        navigate = true;
        dark = true;
      };
      merge.conflictstyle = "zdiff3";
      alias = {
        st = "status";
        ss = "status -s";
        co = "checkout";
        br = "branch";
        sw = "switch";
        pr = "pull -r";
        ps = "push";
        fixit = "commit --amend --no-edit";
        fixmsg = "commit --amend";
        # ベースブランチに戻って最新化し、リモートで消えた(マージ済み)ローカルブランチを一括削除する。
        # 使い方: `git sweep`(=develop) / `git sweep main` のように引数でベースを指定可能。
        sweep = ''
          !f() { \
            base="''${1:-develop}"; \
            git switch "$base" && \
            git fetch --prune && \
            git pull && \
            git branch -vv | awk '/: gone]/{print $1}' | grep -vE '^[*+]' | xargs -r git branch -D; \
          }; f'';
      };
    };
  };
}
