return {
  -- kanagawa（併用: 棚に残す。:colorscheme kanagawa で切替可）
  {
    "rebelot/kanagawa.nvim",
    lazy = true,
    opts = {
      transparent = true,
      theme = "wave", -- wave, dragon, lotus
    },
  },

  -- catppuccin（併用: デフォルト。flavour = latte/frappe/macchiato/mocha）
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    lazy = false,
    init = function()
      local function apply_transparency()
        for _, group in ipairs({
          "Normal",
          "NormalNC",
          "NormalFloat",
          "FloatBorder",
          "SignColumn",
          "EndOfBuffer",
          "LineNr",
          "CursorLineNr",
          "FoldColumn",
        }) do
          local hl = vim.api.nvim_get_hl(0, { name = group, link = false })
          hl.bg = nil
          vim.api.nvim_set_hl(0, group, hl)
        end
      end

      vim.api.nvim_create_autocmd({ "ColorScheme", "VimEnter" }, {
        group = vim.api.nvim_create_augroup("TransparentBackground", { clear = true }),
        callback = apply_transparency,
      })
    end,
    opts = {
      flavour = "mocha", -- 暗め。明るくするなら latte
      transparent_background = true, -- kanagawa と揃えて背景透過
      float = {
        transparent = true,
      },
      custom_highlights = function()
        return {
          Normal = { bg = "NONE" },
          NormalNC = { bg = "NONE" },
          NormalFloat = { bg = "NONE" },
          FloatBorder = { bg = "NONE" },
          SignColumn = { bg = "NONE" },
          EndOfBuffer = { bg = "NONE" },
          LineNr = { bg = "NONE" },
          CursorLineNr = { bg = "NONE" },
          FoldColumn = { bg = "NONE" },
        }
      end,
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
