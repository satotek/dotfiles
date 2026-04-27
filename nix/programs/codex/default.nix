{ pkgs, ... }:
{
  programs.codex = {
    enable = true;
    package = pkgs.llm-agents.codex;

    settings = {
      personality = "friendly";
      model = "gpt-5.5";
      model_reasoning_effort = "medium";
      service_tier = "fast";

      plugins = {
        "computer-use@openai-bundled".enabled = true;
        "github@openai-curated".enabled = true;
        "gmail@openai-curated".enabled = true;
        "google-calendar@openai-curated".enabled = true;
        "google-drive@openai-curated".enabled = true;
      };
    };
  };
}
