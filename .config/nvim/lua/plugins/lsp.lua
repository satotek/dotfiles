-- LSPの実行ファイルはNixまたはプロジェクトローカルで管理する。
-- サーバー固有の設定はafter/lsp/<server>.luaに置く。
local servers = {
  "bashls",
  "biome",
  "cssls",
  "denols",
  "efm",
  "eslint",
  "gopls",
  "jsonls",
  "lua_ls",
  "marksman",
  "nixd",
  "oxfmt",
  "oxlint",
  "pyright",
  "ruff",
  "rust_analyzer",
  "tailwindcss",
  "taplo",
  "terraformls",
  "tflint",
  "tsgo",
  "yamlls",
}

local enabled = {}
for _, server in ipairs(servers) do
  enabled[server] = {}
end

-- Neovim 0.12純正のLSP色情報をインラインの色見本として表示する。
vim.lsp.document_color.enable(true, nil, { style = "virtual" })

return {
  {
    "neovim/nvim-lspconfig",
    dependencies = { "b0o/SchemaStore.nvim" },
    opts = { servers = enabled },
  },
}
