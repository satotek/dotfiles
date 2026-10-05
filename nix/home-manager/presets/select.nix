# ホストが選ぶ preset の並び。省略すると今の開発マシンと同じ一式になる。
# ヘッドレスなサーバは withTerminal = false にして Ghostty と WezTerm を外す。
{
  withTerminal ? true,
  withSecrets ? true,
  withRust ? true,
}:
let
  optional = cond: path: if cond then [ path ] else [ ];
in
[
  ./shell.nix
  ./cli.nix
  ./git.nix
  ./editor.nix
]
++ optional withTerminal ./terminal.nix
++ [ ./agents.nix ]
++ optional withSecrets ./secrets.nix
++ [
  ./cloud.nix
  ./infra.nix
  ./go.nix
]
++ optional withRust ./rust.nix
++ [
  ./node.nix
  ./python.nix
  ./editor-lsp.nix
  ./media.nix
]
