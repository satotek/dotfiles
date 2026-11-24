return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    lazy = false,
    opts = {
      flavour = "mocha", -- 暗め。明るくするなら latte
      -- 本文・行番号・サイン列・フロートまで背景を透過する。
      transparent_background = true,
      float = {
        transparent = true,
      },
      integrations = {
        blink_pairs = true,
      },
      custom_highlights = function(colors)
        return {
          -- 1段目の括弧と同じ赤なので、波線を足して対応の取れない括弧を見分ける。
          BlinkPairsUnmatched = { fg = colors.red, sp = colors.red, style = { "undercurl" } },
          -- 背景が透過でもタブの区切りが見えるよう、今のタブを明るく、ほかを暗くする。
          MiniTablineCurrent = { fg = colors.text, bg = colors.surface0, style = { "bold" } },
          MiniTablineVisible = { fg = colors.subtext0, bg = colors.mantle },
          MiniTablineHidden = { fg = colors.overlay1, bg = colors.mantle },
          MiniTablineModifiedCurrent = { fg = colors.peach, bg = colors.surface0, style = { "bold" } },
          MiniTablineModifiedVisible = { fg = colors.peach, bg = colors.mantle },
          MiniTablineModifiedHidden = { fg = colors.peach, bg = colors.mantle },
        }
      end,
    },
    config = function(_, opts)
      require("catppuccin").setup(opts)
      vim.cmd.colorscheme("catppuccin")
    end,
  },
}
