return {
  -- add kanagawa
  {
    "rebelot/kanagawa.nvim",
    opts = {
      transparent = true,
      theme = "wave", -- wave, dragon, lotus
    },
  },

  -- Configure LazyVim to load kanagawa
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "kanagawa",
    },
  },
}
