-- OxfmtをWeb系のデフォルトformatterにする。
-- BiomeまたはPrettierを明示したプロジェクトでは、それらを優先してattachしない。
local util = require("lspconfig.util")

local biome_configs = { "biome.json", "biome.jsonc" }
local prettier_configs = {
  ".prettierrc",
  ".prettierrc.json",
  ".prettierrc.json5",
  ".prettierrc.js",
  ".prettierrc.cjs",
  ".prettierrc.mjs",
  ".prettierrc.yaml",
  ".prettierrc.yml",
  ".prettierrc.toml",
  "prettier.config.js",
  "prettier.config.cjs",
  "prettier.config.mjs",
  "prettier.config.ts",
}

local function has_formatter(markers, field, filename, stop)
  markers = util.insert_package_json(vim.deepcopy(markers), field, filename)
  return vim.fs.find(markers, {
    path = filename,
    upward = true,
    stop = stop,
  })[1] ~= nil
end

return {
  root_dir = function(bufnr, on_dir)
    local filename = vim.api.nvim_buf_get_name(bufnr)
    local project_root = vim.fs.root(bufnr, {
      "package-lock.json",
      "pnpm-lock.yaml",
      "yarn.lock",
      "bun.lock",
      "bun.lockb",
      ".git",
    })
    if not project_root then
      return
    end

    local stop = vim.fs.dirname(project_root)
    if has_formatter(biome_configs, "biomejs", filename, stop) then
      return
    end
    if has_formatter(prettier_configs, "prettier", filename, stop) then
      return
    end

    on_dir(project_root)
  end,
}
