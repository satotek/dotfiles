-- LSP renameを入力中にプレビューする。キーはLazyVim標準の<leader>crを維持する。
return {
  {
    "smjonas/inc-rename.nvim",
    cmd = "IncRename",
    opts = {},
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        ["*"] = {
          keys = {
            {
              "<leader>cr",
              function()
                local inc_rename = require("inc_rename")
                return ":" .. inc_rename.config.cmd_name .. " " .. vim.fn.expand("<cword>")
              end,
              expr = true,
              desc = "Rename",
              has = "rename",
            },
          },
        },
      },
    },
  },
  {
    "folke/noice.nvim",
    optional = true,
    opts = { presets = { inc_rename = true } },
  },
}
