-- Styluaと、プロジェクトローカル版PrettierをEFM経由でLSP formatterとして使う。
local util = require("lspconfig.util")

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

local prettier = {
  formatCommand = "./node_modules/.bin/prettier --stdin-filepath ${INPUT}",
  formatStdin = true,
}

local stylua = {
  formatCommand = "stylua --search-parent-directories --stdin-filepath ${INPUT} -",
  formatStdin = true,
}

local shfmt = {
  formatCommand = "shfmt",
  formatStdin = true,
}

local hadolint = {
  lintCommand = "hadolint --no-color -",
  lintStdin = true,
  lintFormats = { "%f:%l %m" },
}

return {
  init_options = { documentFormatting = true },
  filetypes = {
    "astro",
    "bash",
    "css",
    "dockerfile",
    "graphql",
    "html",
    "javascript",
    "javascriptreact",
    "json",
    "jsonc",
    "less",
    "lua",
    "markdown",
    "markdown.mdx",
    "scss",
    "sh",
    "svelte",
    "typescript",
    "typescriptreact",
    "vue",
    "yaml",
  },
  root_dir = function(bufnr, on_dir)
    local filename = vim.api.nvim_buf_get_name(bufnr)
    if vim.bo[bufnr].filetype == "lua" then
      local root = vim.fs.root(filename, { ".stylua.toml", "stylua.toml", ".git" }) or vim.fs.dirname(filename)
      on_dir(root)
      return
    end

    if vim.bo[bufnr].filetype == "sh" or vim.bo[bufnr].filetype == "bash" then
      local root = vim.fs.root(filename, { ".git" }) or vim.fs.dirname(filename)
      on_dir(root)
      return
    end

    if vim.bo[bufnr].filetype == "dockerfile" then
      local root = vim.fs.root(filename, { ".git" }) or vim.fs.dirname(filename)
      on_dir(root)
      return
    end

    local markers = util.insert_package_json(vim.deepcopy(prettier_configs), "prettier", filename)
    local config = vim.fs.find(markers, { path = filename, upward = true })[1]
    if not config then
      return
    end
    local root = vim.fs.dirname(config)
    if vim.fn.executable(vim.fs.joinpath(root, "node_modules/.bin/prettier")) == 1 then
      on_dir(root)
    end
  end,
  settings = {
    rootMarkers = prettier_configs,
    languages = {
      astro = { prettier },
      bash = { shfmt },
      css = { prettier },
      dockerfile = { hadolint },
      graphql = { prettier },
      html = { prettier },
      javascript = { prettier },
      javascriptreact = { prettier },
      json = { prettier },
      jsonc = { prettier },
      less = { prettier },
      lua = { stylua },
      markdown = { prettier },
      ["markdown.mdx"] = { prettier },
      scss = { prettier },
      sh = { shfmt },
      svelte = { prettier },
      typescript = { prettier },
      typescriptreact = { prettier },
      vue = { prettier },
      yaml = { prettier },
    },
  },
}
