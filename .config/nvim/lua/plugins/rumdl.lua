-- rumdl: Rust製の Markdown リンター兼フォーマッタを LSP として使う。
-- homebrew(nix-darwin管理)で導入した rumdl バイナリを利用（mason 管理外）。
-- 旧構成（nvim-lint の markdownlint-cli2 / conform の prettier）を無効化し、
-- markdown の診断・整形を rumdl 一本に集約する。
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
  -- nvim-lint の markdownlint-cli2 を無効化（rumdl が診断を担当）
  {
    "mfussenegger/nvim-lint",
    opts = function(_, opts)
      if opts.linters_by_ft then
        opts.linters_by_ft.markdown = nil
      end
    end,
  },
  -- conform の markdown フォーマッタ(prettier/markdownlint-cli2/markdown-toc)を無効化。
  -- prettier は未導入で ENOENT が出ていた。整形は rumdl(LSP)にフォールバックさせる。
  {
    "stevearc/conform.nvim",
    opts = function(_, opts)
      if opts.formatters_by_ft then
        opts.formatters_by_ft.markdown = nil
        opts.formatters_by_ft["markdown.mdx"] = nil
      end
    end,
  },
}
