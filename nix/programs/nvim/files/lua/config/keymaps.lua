-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Oxker (Docker TUI)
vim.keymap.set("n", "<leader>D", function()
  Snacks.terminal("oxker", {
    cwd = LazyVim.root(),
    win = { style = "lazygit" },
  })
end, { desc = "Oxker (Docker)" })
