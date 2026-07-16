-- 保存時整形はLSPへ集約し、Conformとの二重実行を避ける。
local lsp_formatted_filetypes = {
  "astro",
  "bash",
  "css",
  "graphql",
  "html",
  "javascript",
  "javascriptreact",
  "json",
  "jsonc",
  "less",
  "lua",
  "markdown",
  "markdown.mdx",
  "scss",
  "sh",
  "svelte",
  "typescript",
  "typescriptreact",
  "vue",
  "yaml",
}

return {
  {
    "stevearc/conform.nvim",
    opts = function(_, opts)
      opts.formatters_by_ft = opts.formatters_by_ft or {}
      for _, ft in ipairs(lsp_formatted_filetypes) do
        opts.formatters_by_ft[ft] = nil
      end
    end,
  },
}
