---@type LazySpec
return {
  "HiPhish/rainbow-delimiters.nvim",
  -- powered by your existing nvim-treesitter parsers
  event = { "BufReadPost", "BufNewFile" },
  dependencies = { "nvim-treesitter/nvim-treesitter" },
  config = function()
    require("rainbow-delimiters.setup").setup({})
  end,
}
