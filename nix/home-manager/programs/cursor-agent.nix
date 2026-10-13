{ pkgs, ... }:
{
  # Cursor Agent CLI。llm-agents.nix の公式バイナリを使う。
  # 実行ファイル名は cursor-agent。grok が PATH の agent を占有しているので、
  # agent という名前では出さない。
  home.packages = [ pkgs.llm-agents.cursor-agent ];
}
