---@type LazySpec
return {
  "stevearc/oil.nvim",
  version = "*",
  -- oil replaces netrw, so it must be available the moment nvim opens a
  -- directory (e.g. `nvim .`). Lazy-loading via `keys` alone would miss that.
  lazy = false,
  -- no `dependencies`: LazyVim already loads mini.icons, and oil auto-detects it
  keys = {
    { "-", "<cmd>Oil<cr>", desc = "Open parent directory (oil)" },
    { "<leader>o", "<cmd>Oil<cr>", desc = "Open parent directory (oil)" },
  },
  ---@module "oil"
  ---@type oil.SetupOpts
  opts = {
    -- take over netrw; yazi.nvim intentionally does NOT hijack it, so no clash
    default_file_explorer = true,
    view_options = {
      show_hidden = true,
    },
    keymaps = {
      ["q"] = "actions.close",
    },
  },
}
