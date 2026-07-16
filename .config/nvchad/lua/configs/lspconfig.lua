require("nvchad.configs.lspconfig").defaults()

-- Prefer language servers already provided by Nix/Homebrew. NvChad-specific
-- servers (lua_ls/html/cssls) are installed in its isolated Mason data dir.
local servers = {
  "lua_ls",
  "html",
  "cssls",
  "vtsls",
  "pyright",
  "rust_analyzer",
  "gopls",
  "rumdl",
}

-- Match LazyVim's TypeScript defaults so both profiles use the same server
-- and provide comparable completion, refactoring, and inlay-hint behavior.
local typescript_settings = {
  updateImportsOnFileMove = { enabled = "always" },
  suggest = {
    completeFunctionCalls = true,
  },
  inlayHints = {
    enumMemberValues = { enabled = true },
    functionLikeReturnTypes = { enabled = true },
    parameterNames = { enabled = "literals" },
    parameterTypes = { enabled = true },
    propertyDeclarationTypes = { enabled = true },
    variableTypes = { enabled = false },
  },
}

vim.lsp.config("vtsls", {
  settings = {
    complete_function_calls = true,
    vtsls = {
      enableMoveToFileCodeAction = true,
      autoUseWorkspaceTsdk = true,
      experimental = {
        maxInlayHintLength = 30,
        completion = {
          enableServerSideFuzzyMatch = true,
        },
      },
    },
    typescript = typescript_settings,
    javascript = vim.deepcopy(typescript_settings),
  },
})

vim.lsp.enable(servers)
