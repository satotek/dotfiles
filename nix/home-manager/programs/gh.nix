{ pkgs, ... }:
let
  # Nix の GitHub API は未認証だとすぐレート制限に当たる。gh の credential から
  # トークンを読み、NIX_CONFIG にだけ渡す。argv やシェル履歴には残さない。
  ghNix = pkgs.writeShellApplication {
    name = "gh-nix";
    runtimeInputs = [ pkgs.gh ];
    text = ''
      if [ "$#" -eq 0 ]; then
        echo "usage: gh-nix <command> [args...]" >&2
        exit 2
      fi

      if ! gh auth status >/dev/null 2>&1; then
        echo "gh-nix: gh is not authenticated; run 'gh auth login'" >&2
        exit 1
      fi

      token="$(gh auth token)"
      export NIX_CONFIG="access-tokens = github.com=$token"$'\n'"''${NIX_CONFIG:-}"
      unset token
      exec "$@"
    '';
  };
in
{
  home.packages = [ ghNix ];

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
