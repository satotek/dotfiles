{
  pkgs,
  lib,
  config,
  ...
}:
{
  # SSH 署名をローカルで検証（git log --show-signature / verify-commit）するための
  # 対応表。「メール 公開鍵」の行で、コミッタと署名鍵が一致するかを git が確認する。
  # 検証はこの Mac で行うので Mac 限定。1 行目は旧 1Password 鍵（過去コミットの検証用）、
  # 2 行目が現行のローカル鍵。
  home.file = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
    ".config/git/allowed_signers".text = ''
      konosuke.s0912@gmail.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEu/vDcjBdXbzqM6e6V56JX65xkjyK7Z6sDvnfeCTXLU
      konosuke.s0912@gmail.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICyS7MJj0gVRX1wufGso1kcKIbjfkIW/suHnhxfK99i1
    '';
  };

  # core.pager と interactive.diffFilter はこの git 連携が設定する。
  # diffFilter は --color-only なので、side-by-side は add -p には効かない。
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      navigate = true;
      dark = true;
      side-by-side = true;
      # side-by-side では左右それぞれに行番号が付き、変更位置を数字で追える。
      # lazygit も gitconfig を読むので、あちらの指定は不要になる。
      line-numbers = true;
    };
  };

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
      color.ui = true;
      init.defaultBranch = "main";
      core = {
        editor = "nvim";
      };
      # 素の `git pull` でもマージコミットを作らず rebase で取り込む。
      pull.rebase = true;
      # コミットメッセージ編集中に diff を表示し、内容を見ながら書けるようにする。
      commit.verbose = true;
      merge.conflictstyle = "zdiff3";
      # リモート追従と競合解決を日常操作で楽にするための既定値。
      push = {
        autoSetupRemote = true;
        # --force-with-lease 時、リモートの最新を取り込み済みの場合に限って上書きを許す。
        useForceIfIncludes = true;
      };
      fetch = {
        prune = true;
        all = true;
        writeCommitGraph = true;
      };
      rebase = {
        autoStash = true;
        autoSquash = true;
        # スタックしたブランチを rebase したとき、中間ブランチの参照も追従させる。
        updateRefs = true;
      };
      tag.sort = "version:refname";
      rerere = {
        enabled = true;
        autoupdate = true;
      };
      diff = {
        algorithm = "histogram";
        colorMoved = "dimmed-zebra";
        renames = true;
        mnemonicPrefix = true;
      };
      column.ui = "auto";
      branch.sort = "-committerdate";
      help.autocorrect = "prompt";
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
    }
    // (
      if pkgs.stdenv.hostPlatform.isDarwin then
        {
          # GitHub: push だけ SSH 化する。fetch/clone は HTTPS のままにして、
          # lazy.nvim など public repo を読むツールが SSH port 22 に依存しないようにする。
          # private repo は最初から git@github.com:owner/repo.git で clone する。
          url."git@github.com:".pushInsteadOf = "https://github.com/";

          # コミット署名は ~/.ssh/id_ed25519（ローカル鍵）で行う。T3 Code などの
          # エージェントが無人で commit/push できるよう、署名ごとの Touch ID 確認を
          # 介さない。鍵は GitHub に認証鍵と Signing key の両方として登録してあり、
          # 1Password の鍵とは独立に失効できる。
          gpg = {
            format = "ssh";
            ssh = {
              # PATH に依存しないよう ssh-keygen はストアパスで固定する。
              program = "${pkgs.openssh}/bin/ssh-keygen";
              # ローカル検証（--show-signature / verify-commit）用の対応表を指す。
              allowedSignersFile = "~/.config/git/allowed_signers";
            };
          };
          user.signingKey = "${config.home.homeDirectory}/.ssh/id_ed25519";
          commit.gpgsign = true;
          tag.gpgsign = true;
        }
      else
        {
          # azureuser(Linux VM): この VM を常用機として扱い、ディスク上に GitHub 用の
          # SSH 秘密鍵(~/.ssh/id_ed25519)を置く。公開鍵は GitHub の SSH keys に登録済み。
          # これにより push も private repo の fetch/clone も VM 内で完結する。
          #
          # GitHub: push だけ SSH 化する。fetch/clone は HTTPS のままにして、
          # lazy.nvim など public repo を読むツールが SSH port 22 に依存しないようにする。
          # private repo は最初から git@github.com:owner/repo.git で cloneする。
          url."git@github.com:".pushInsteadOf = "https://github.com/";
        }
    );
  };
}
