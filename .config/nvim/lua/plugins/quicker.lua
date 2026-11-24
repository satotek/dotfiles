-- quickfixを見やすく整形し、quickfixバッファの編集を:wで元ファイルへ反映する。
-- pickerで集めた結果を<C-q>で送り、まとめて直す流れに使う。
return {
  {
    "stevearc/quicker.nvim",
    ft = "qf",
    keys = {
      {
        "<leader>xq",
        function()
          require("quicker").toggle()
        end,
        desc = "Toggle Quickfix",
      },
      {
        "<leader>xl",
        function()
          require("quicker").toggle({ loclist = true })
        end,
        desc = "Toggle Loclist",
      },
    },
    ---@module "quicker"
    ---@type quicker.SetupOptions
    opts = {
      keys = {
        {
          ">",
          function()
            require("quicker").expand({ before = 2, after = 2, add_to_existing = true })
          end,
          desc = "Expand quickfix context",
        },
        {
          "<",
          function()
            require("quicker").collapse()
          end,
          desc = "Collapse quickfix context",
        },
      },
    },
  },
}
