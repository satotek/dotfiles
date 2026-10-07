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

  allow = [
    "$defaults"
    # critique は追跡済み・再生成可能な対象への限定を勧めたが、手間との兼ね合いで
    # 広いままにしている。.git/ やリポジトリのルートは soft_deny 側で止める。
    "Running `rm` to delete files inside the current working repository is routine and safe — allow without confirmation, including recursive deletion of ordinary subdirectories such as build outputs, caches, vendored dependencies, test fixtures, and git worktrees."
    "Allow inline interpreters (`python -c`, `python3 -c`, `node -e`, `ruby -e`, `perl -e`) that only read files inside the working repo and print a parsed or computed value. Not covered: writing or deleting files, making any network request, spawning a subprocess, or eval/exec of data. This does not override Code from External."
    "Allow compound chains joined by `&&` or `|` whose every stage is a read-only inspection command: cd, ls, cat, head, tail, wc, sort, uniq, grep, rg, jq, `sed -n` without `w`/`e` commands, `awk` without `system()` or redirection, `find` without -delete/-exec/-execdir/-ok/-okdir/-fprint*, git status/log/diff/show without `--output`, and `gh api` / `gh search` with no `-X` other than GET and no `-f`/`-F`/`--input`. Not covered: output redirection (`>`, `>>`, `tee`), chains that end in a shell or interpreter, or decoding piped into execution (decoded content is still judged as an encoded command)."
  ];

  soft_deny = [
    "$defaults"
    "Require confirmation for `rm` that targets the repo root, `.git/`, the home directory, or any path outside the working repo."
    "Require confirmation for any force-push (including `--force-with-lease`) to the repository's default branch (`main` or `master`), and for force-pushing a branch that may contain commits from other people."
  ];
}
