{ pkgs, ... }:
{
  # AGY は trustedWorkspaces などの実行時状態を settings.json に書き戻すので、
  # 宣言した値だけをマージする。
  programs.antigravity-cli = {
    enable = true;
    package = pkgs.llm-agents.antigravity-cli;
    mutableSettings = true;

    # Keep the model choice consistent across hosts instead of letting it
    # drift with whatever /model last selected. Declared values are merged
    # over the writable settings.json, so trustedWorkspaces and saved
    # permissions survive activation.
    settings.model = "Gemini 4 Neon (Medium)";

    # Auto-approve tool calls globally. This is equivalent to selecting
    # "always-proceed" for Tool Permission in /settings.
    settings.toolPermission = "always-proceed";
  };
}
