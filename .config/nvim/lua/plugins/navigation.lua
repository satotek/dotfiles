return {
  {
    "akinsho/bufferline.nvim",
    event = { "BufAdd", "TabEnter" },
    opts = {
      options = {
        mode = "tabs",
        separator_style = "slant",
        always_show_bufferline = false,
        show_buffer_close_icons = false,
        show_close_icon = false,
        color_icons = true,
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
