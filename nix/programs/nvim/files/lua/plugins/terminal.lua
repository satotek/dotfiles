return {
  {
    "akinsho/toggleterm.nvim",
    version = "*",

    keys = {
      {
        "<leader>tt",
        "<cmd>ToggleTerm<cr>",
        mode = { "n", "t" },
        desc = "Toggle terminal",
      },
    },
    opts = {
      open_mapping = nil,
      size = 100,
      hide_numbers = true,
      shade_filetypes = {},
      shade_terminals = true,
      shading_factor = 2,
      start_in_insert = true,

      insert_mappings = true,
      persist_size = true,
      direction = "float",

      close_on_exit = true,
    },
  },
}
