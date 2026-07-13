{ pkgs, lib, ... }:
let
  gitSsh = pkgs.writeShellScript "git-ssh" ''
    for arg in "$@"; do
      case "$arg" in
        git@ssh.dev.azure.com|ssh.dev.azure.com)
          identity="$HOME/.ssh/azure-devops"
          if [ ! -f "$identity" ]; then
            identity="$identity.pub"
          fi
          if [ ! -f "$identity" ]; then
            echo "Azure DevOps SSH identity not found: ~/.ssh/azure-devops[.pub]" >&2
            exit 1
          fi

          exec ${pkgs.openssh}/bin/ssh \
            -o IdentitiesOnly=yes \
            -o IdentityFile="$identity" \
            "$@"
          ;;
      esac
    done

    exec ${pkgs.openssh}/bin/ssh "$@"
  '';
in
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
        sshCommand = toString gitSsh;
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
      # Azure DevOpsは各端末で作った専用RSA鍵をgitSshで選ぶ。
      # Macの1Password SSH Agentは公開鍵(~/.ssh/azure-devops.pub)、
      # Linux等は秘密鍵(~/.ssh/azure-devops)をIdentityFileとして使う。
      if pkgs.stdenv.isDarwin then
        {
          # GitHub: push だけ SSH 化する。fetch/clone は HTTPS のままにして、
          # lazy.nvim など public repo を読むツールが SSH port 22 に依存しないようにする。
          # private repo は最初から git@github.com:owner/repo.git で clone する。
          url."git@github.com:".pushInsteadOf = "https://github.com/";

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
          # GitHub: push だけ SSH 化する。fetch/clone は HTTPS のままにして、
          # lazy.nvim など public repo を読むツールが SSH port 22 に依存しないようにする。
          # private repo は最初から git@github.com:owner/repo.git で cloneする。
          url."git@github.com:".pushInsteadOf = "https://github.com/";
        }
    );
  };
}
