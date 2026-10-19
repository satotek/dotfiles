# Claude Code auto mode 分類器への追加ルール（純データ）。
# 各要素は分類器にそのまま渡る自然文。"$defaults" の位置に組み込みルールが
# 展開されるので、既定を残したまま足したい分だけ書く。
# 効いている内容は `claude auto-mode config`、書き方の講評は
# `claude auto-mode critique` で確認できる。
# 参考: dryvist/nix-ai modules/claude/automode.nix
{
  environment = [
    "$defaults"
    "Source control: github.com/satotek/* is the user's own GitHub account. In these repos, cloning, pushing branches, opening PRs, and editing PR titles and bodies are routine. Trust does not override repo visibility: public satotek repos are publishing destinations."
    # 業務 VM/WSL では az がログイン済みのことがあるため、信頼範囲を広げずに
    # 「共有資源」と明示して既定より慎重に扱わせる。
    "Cloud provider(s): the Azure CLI may be logged in to a company subscription. Treat every Azure subscription, resource group, and resource as shared company infrastructure, not the user's own. Read-only queries are fine. Creating, modifying, or deleting Azure resources needs explicit user intent, meaning the user named both the resource and the operation."
  ];

  # allow は上書きしない。未指定なら Claude 組み込みの default allow が使われる。
  soft_deny = [
    "$defaults"
    "Require confirmation for `rm` that targets the repo root, `.git/`, the home directory, or any path outside the working repo."
    "Require confirmation for any force-push (including `--force-with-lease`) to the repository's default branch (`main` or `master`), and for force-pushing a branch that may contain commits from other people."
  ];
}
