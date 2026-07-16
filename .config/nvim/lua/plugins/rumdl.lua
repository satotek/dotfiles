-- rumdl: Rust製の Markdown リンター兼フォーマッタを LSP として使う。
-- Nixで導入したrumdlを使い、Markdownの診断・整形をLSPへ集約する。
return {
  -- rumdl を LSP として登録・有効化（Neovim 0.11+ ネイティブ LSP API）
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      vim.lsp.config("rumdl", {
        cmd = { "rumdl", "server" },
        filetypes = { "markdown" },
        root_markers = { ".rumdl.toml", "rumdl.toml", ".markdownlint.yaml", ".markdownlint.yml", ".git" },
      })
      vim.lsp.enable("rumdl")
      return opts
    end,
  },
}
