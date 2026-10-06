{ ... }:
{
  # config.yml は読み取り専用になるので、`gh config set` ではなくここで変える。
  # 認証情報は hosts.yml に残り、Nix の管理外。
  programs.gh = {
    enable = true;
    settings = {
      git_protocol = "https";
      aliases.co = "pr checkout";
    };
  };
}
