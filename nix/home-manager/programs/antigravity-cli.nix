{ pkgs, ... }:
{
  # AGY は trustedWorkspaces などの実行時状態を settings.json に書き戻すので、
  # 宣言した値だけをマージする。
  programs.antigravity-cli = {
    enable = true;
    package = pkgs.llm-agents.antigravity-cli;
    mutableSettings = true;

    # Auto-approve tool calls globally. This is equivalent to selecting
    # "always-proceed" for Tool Permission in /settings.
    settings.toolPermission = "always-proceed";
  };
}
