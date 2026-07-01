---@type LazySpec
return {
  "Bekaboo/dropbar.nvim",
  -- requires Neovim >= 0.10 (you're on 0.12) — uses the native winbar
  event = "VeryLazy",
  keys = {
    {
      "<leader>;",
      function()
        require("dropbar.api").pick()
      end,
      desc = "Pick symbols in winbar (dropbar)",
    },
  },
  opts = {},
}
