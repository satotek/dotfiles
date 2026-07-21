vim.filetype.add({ extension = { mdx = "markdown.mdx" } })

return {
  {
    "delphinus/md-render.nvim",
    version = "*",
    cmd = { "MdRender" },
    ft = { "markdown" },
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
