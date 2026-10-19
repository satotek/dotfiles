{ pkgs, ... }:
{
  # DeepSeek Harness。upstream はリリース成果物を出さないので、
  # llm-agents.nix がソースからビルドしたパッケージを使う。
  home.packages = [ pkgs.llm-agents.dsh ];
}
