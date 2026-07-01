---@type LazySpec
return {
  "bennypowers/nvim-regexplainer",
  cmd = { "RegexplainerShow", "RegexplainerHide", "RegexplainerToggle" },
  keys = {
    {
      "<leader>re",
      "<cmd>RegexplainerToggle<cr>",
      mode = { "n", "v" },
      desc = "Explain regex under cursor",
    },
  },
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    { "MunifTanjim/nui.nvim", lazy = true },
  },
  ---@type RegexplainerOptions
  opts = {
    mode = "narrative",
    -- render into a floating popup near the regex
    display = "popup",
  },
  config = function(_, opts)
    require("regexplainer").setup(opts)
  end,
}
