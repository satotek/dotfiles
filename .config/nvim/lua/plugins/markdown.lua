vim.filetype.add({ extension = { mdx = "markdown.mdx" } })

return {
  {
    "delphinus/md-render.nvim",
    version = "*",
    cmd = { "MdRender" },
    ft = { "markdown" },
    dependencies = {
      -- 日本語の文節単位の折り返し。md-render が自動で検出する。
      { "delphinus/budoux.lua", version = "*" },
    },
    keys = {
      { "<leader>cp", "<Plug>(md-render-preview)", ft = "markdown", desc = "Markdown Preview" },
    },
  },
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown", "markdown.mdx" },
    opts = {
      html = {
        comment = {
          conceal = false,
        },
      },
    },
  },
}
