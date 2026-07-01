return {
  -- kanagawa（併用: 棚に残す。:colorscheme kanagawa で切替可）
  {
    "rebelot/kanagawa.nvim",
    opts = {
      transparent = true,
      theme = "wave", -- wave, dragon, lotus
    },
  },

  -- catppuccin（併用: デフォルト。flavour = latte/frappe/macchiato/mocha）
  {
    "catppuccin/nvim",
    name = "catppuccin",
    opts = {
      flavour = "mocha", -- 暗め。明るくするなら latte
      transparent_background = true, -- kanagawa と揃えて背景透過
    },
  },

  -- アクティブな colorscheme を catppuccin に
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "catppuccin",
    },
  },
}
