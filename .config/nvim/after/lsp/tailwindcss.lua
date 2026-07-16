-- Tailwind v4対応の`.git`フォールバックは広すぎるため、実際の採用宣言を必須にする。
local util = require("lspconfig.util")

return {
  root_dir = function(bufnr, on_dir)
    local filename = vim.api.nvim_buf_get_name(bufnr)
    local markers = {
      "tailwind.config.js",
      "tailwind.config.cjs",
      "tailwind.config.mjs",
      "tailwind.config.ts",
      "postcss.config.js",
      "postcss.config.cjs",
      "postcss.config.mjs",
      "postcss.config.ts",
    }
    markers = util.insert_package_json(markers, "tailwindcss", filename)
    local marker = vim.fs.find(markers, { path = filename, upward = true })[1]
    if marker then
      on_dir(vim.fs.dirname(marker))
    end
  end,
}
