---@type LazySpec
return {
  "stevearc/oil.nvim",
  version = "*",
  lazy = true,
  cmd = { "Oil" },
  init = function()
    local path = vim.fn.expand("%:p")
    local is_dir = vim.fn.isdirectory(path) == 1
    local is_oil_path = path:find("^oil://") or path:find("^oil%-ssh://") or path:find("^oil%-trash://")

    if is_dir or is_oil_path then
      require("oil")
    end
  end,
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
