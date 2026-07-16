return {
  {
    "akinsho/bufferline.nvim",
    event = { "BufAdd", "TabEnter" },
    opts = {
      options = {
        mode = "buffers",
        always_show_bufferline = false,
        diagnostics = "nvim_lsp",
        offsets = {
          { filetype = "snacks_layout_box" },
        },
      },
    },
  },
  {
    "folke/flash.nvim",
    event = "BufReadPost",
    opts = {
      modes = {
        char = { enabled = false },
        search = { enabled = false },
        treesitter = { enabled = false },
      },
    },
    keys = {
      {
        "<CR>",
        mode = { "n", "x", "o", "v" },
        function()
          require("flash").jump({ label = { before = true, after = false } })
        end,
        desc = "Flash",
      },
    },
  },
}
