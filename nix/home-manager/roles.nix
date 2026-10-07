# ホストは role の組み合わせで構成を選ぶ。role は preset（道具のまとまり）の束で、
# 「そのマシンで何をするか」を表す。ホストごとの差分を条件分岐ではなく
# 読み込む role の違いだけで表すために置く。
let
  roles = {
    # どのマシンでも使うシェル、CLI、Git、エディタ。
    base = [
      ./presets/shell.nix
      ./presets/cli.nix
      ./presets/git.nix
      ./presets/editor.nix
    ];
    dev = [
      ./presets/editor-lsp.nix
      ./presets/node.nix
      ./presets/python.nix
      ./presets/go.nix
      ./presets/infra.nix
      ./presets/cloud.nix
      ./presets/media.nix
    ];
    rust = [ ./presets/rust.nix ];
    # AI エージェント本体、共通の指示、スキル、MCP、Herdr との連携。
    ai = [ ./presets/agents.nix ];
    # SOPS で暗号化したシークレットを activation で復号する。
    secrets = [ ./presets/secrets.nix ];
  };
in
{
  select = names: builtins.concatMap (name: roles.${name}) names;
}
