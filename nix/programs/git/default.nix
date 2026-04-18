{ ... }:
{
  programs.git = {
    enable = true;
    includes = [
      { path = "~/.config/git.local"; }
    ];
    ignores = [
      ".DS_Store"
      "thumbs.db"
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
      };
    };
  };
}
