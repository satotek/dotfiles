{ pkgs, ... }:
{
  programs.claude-code = {
    enable = true;
    package = pkgs.llm-agents.claude-code;

    settings = {
      theme = "dark";
      autoUpdates = false;
      includeCoAuthoredBy = false;
      outputStyle = "Explanatory";
      enabledPlugins = {
        "rust-analyzer-lsp@claude-plugins-official" = true;
      };
    };

    lspServers = {
      go = {
        command = "gopls";
        args = [ "serve" ];
        extensionToLanguage = {
          ".go" = "go";
        };
      };

      python = {
        command = "pyright-langserver";
        args = [ "--stdio" ];
        extensionToLanguage = {
          ".py" = "python";
        };
      };

      typescript = {
        command = "typescript-language-server";
        args = [ "--stdio" ];
        extensionToLanguage = {
          ".js" = "javascript";
          ".jsx" = "javascriptreact";
          ".ts" = "typescript";
          ".tsx" = "typescriptreact";
        };
      };
    };
  };
}
