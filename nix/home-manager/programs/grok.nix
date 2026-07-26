{ pkgs, ... }:

{
  # Grok Build CLI。llm-agents.nix が提供する公式バイナリのパッケージを使う。
  home.packages = [ pkgs.llm-agents.grok ];
}
