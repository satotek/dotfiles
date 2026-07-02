---@type LazySpec
return {
  "okuuva/auto-save.nvim",
  -- ^1.0.0 = latest 1.x, so a breaking 2.0 is never pulled in automatically
  -- (lazy-lock.json still pins the exact commit on top of this).
  version = "^1.0.0",
  -- active fork of the (unmaintained) Pocco81/auto-save.nvim.
  -- lazy-load on the same events the plugin itself saves on, plus its toggle cmd.
  cmd = "ASToggle",
  event = { "InsertLeave", "TextChanged" },
  keys = {
    { "<leader>uv", "<cmd>ASToggle<cr>", desc = "Toggle auto-save" },
  },
  opts = {
    -- okuuva defaults already save on FocusLost/BufLeave (immediate) and
    -- InsertLeave/TextChanged (deferred), so we only tune the delay + condition.
    debounce_delay = 1000,
    -- skip buffers where autosave is noisy or wrong. `oil`/`yazi` are our file
    -- explorers, the git filetypes are commit/rebase editors.
    condition = function(buf)
      local excluded_filetypes = {
        "gitcommit",
        "gitrebase",
        "oil",
        "TelescopePrompt",
      }
      if vim.tbl_contains(excluded_filetypes, vim.fn.getbufvar(buf, "&filetype")) then
        return false
      end
      -- also skip special buffers (terminals, prompts, quickfix, ...)
      return vim.fn.getbufvar(buf, "&buftype") == ""
    end,
  },
  -- `execution_message` was removed in the fork; reproduce mozumasu's timestamped
  -- "saved at" feedback via the AutoSaveWritePost lifecycle event instead.
  config = function(_, opts)
    require("auto-save").setup(opts)

    vim.api.nvim_create_autocmd("User", {
      pattern = "AutoSaveWritePost",
      group = vim.api.nvim_create_augroup("autosave_notify", { clear = true }),
      callback = function(args)
        if args.data.saved_buffer ~= nil then
          vim.notify("AutoSave: saved at " .. vim.fn.strftime("%H:%M:%S"), vim.log.levels.INFO)
        end
      end,
    })
  end,
}
