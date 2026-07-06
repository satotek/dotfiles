{ pkgs, lib, ... }:
{
  home.packages = [ pkgs.delta ];

  # SSH 署名をローカルで検証（git log --show-signature / verify-commit）するための
  # 対応表。「メール 公開鍵」の行で、コミッタと署名鍵が一致するかを git が確認する。
  # 署名生成は 1Password(op-ssh-sign)なので Mac 限定でよい。
  home.file = lib.mkIf pkgs.stdenv.isDarwin {
    ".config/git/allowed_signers".text = ''
      konosuke.s0912@gmail.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEu/vDcjBdXbzqM6e6V56JX65xkjyK7Z6sDvnfeCTXLU
    '';
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
    }
    // (
      # GitHub と Azure DevOps で認証経路を分ける。
      # Mac には 1Password の SSH エージェントがあるので GitHub は SSH 化し、
      # Linux VM(azureuser) にはそれが無いので従来どおり store を使う。
      if pkgs.stdenv.isDarwin then
        {
          # GitHub: https の remote を push/fetch 時に git@ へ自動書き換え。
          # SSH は 1Password エージェントが鍵を出すため credential helper を通らず、
          # GitHub トークンの平文保存が無くなる。
          url."git@github.com:".insteadOf = "https://github.com/";

          # Azure DevOps だけ store(PAT)。先頭の空 helper で system の
          # osxkeychain 継承をこの URL 用にリセットし、store のみを使わせる。
          # useHttpPath = 組織/リポジトリ単位で別トークンを保存する。
          credential."https://dev.azure.com" = {
            helper = [
              ""
              "store --file ~/.local/state/git/credentials"
            ];
            useHttpPath = true;
          };

          # コミット署名を 1Password の SSH 鍵で行う。秘密鍵はディスクに出ず、
          # 署名のたびに op-ssh-sign が 1Password（Touch ID）に依頼する。
          # signingKey は "Github" 鍵の公開鍵。GitHub 側に Signing key として登録すると
          # コミットに Verified が付く。
          gpg = {
            format = "ssh";
            ssh = {
              program = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
              # ローカル検証（--show-signature / verify-commit）用の対応表を指す。
              allowedSignersFile = "~/.config/git/allowed_signers";
            };
          };
          user.signingKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEu/vDcjBdXbzqM6e6V56JX65xkjyK7Z6sDvnfeCTXLU";
          commit.gpgsign = true;
          tag.gpgsign = true;
        }
      else
        {
          # azureuser(Linux VM): この VM を常用機として扱い、ディスク上に GitHub 用の
          # SSH 秘密鍵(~/.ssh/id_ed25519)を置く。公開鍵は GitHub の SSH keys に登録済み。
          # これにより push も private repo の fetch/clone も VM 内で完結する。
          #
          # push/fetch 両方を SSH 化するため insteadOf を使う(pushInsteadOf ではない)。
          # 以前は「VM に秘密を残さない(A-strict)」方針で pushInsteadOf にし fetch を匿名
          # https のまま残していたが、常用機化に伴い鍵をディスクに置く判断へ変更した。
          url."git@github.com:".insteadOf = "https://github.com/";

          # Azure DevOps だけは VM 内で完結させるため従来どおり store(PAT)。
          # GitHub の平文トークンは VM から無くなる。
          credential."https://dev.azure.com".helper = "store --file ~/.local/state/git/credentials";
        }
    );
  };
}
