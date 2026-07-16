-- LSPの実行ファイルはNixまたはプロジェクトローカルで管理する。
-- サーバー固有の設定はafter/lsp/<server>.luaに置く。
local servers = {
  "bashls",
  "biome",
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

return {
  {
    "neovim/nvim-lspconfig",
    dependencies = { "b0o/SchemaStore.nvim" },
    opts = { servers = enabled },
  },
}
