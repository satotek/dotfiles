-- 保存時整形はconformに集約する。CLI formatterを優先し、使えないときだけ
-- formatter機能を持つLSPに任せる。lintしかしないツールはnvim-lintで動かす。

-- 整形を任せてよいLSP。cssls・jsonls・yamllsなどは整形が不要なので含めない。
local lsp_formatters = {
  biome = true,
  denols = true,
  gopls = true,
  hls = true,
  nixd = true,
  oxfmt = true,
  ruff = true,
  rumdl = true,
  rust_analyzer = true,
  taplo = true,
  terraformls = true,
}

local format_opts = {
  lsp_format = "fallback",
  filter = function(client)
    return lsp_formatters[client.name] == true
  end,
}

-- organize importsはformatterではなくcode actionなので、整形の前に同期で適用する。
local organize_import_clients = { "gopls", "ruff" }

local function organize_imports(bufnr)
  for _, name in ipairs(organize_import_clients) do
    for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr, name = name })) do
      local params = vim.lsp.util.make_range_params(0, client.offset_encoding)
      params.context = { only = { "source.organizeImports" }, diagnostics = {} }
      local response = client:request_sync("textDocument/codeAction", params, 1000, bufnr)
      for _, action in ipairs((response and response.result) or {}) do
        if action.edit then
          vim.lsp.util.apply_workspace_edit(action.edit, client.offset_encoding)
        end
        if action.command then
          client:exec_cmd(action.command, { bufnr = bufnr })
        end
      end
    end
  end
end

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

-- Prettierを導入したプロジェクトのルート。グローバルのprettierでよそのコードを
-- 勝手に整形しないよう、設定とnode_modules内の実行ファイルの両方を条件にする。
local function prettier_root(filename)
  local root = vim.fs.root(filename, function(name, dir)
    if vim.list_contains(prettier_configs, name) then
      return true
    end
    if name ~= "package.json" then
      return false
    end
    local ok, lines = pcall(vim.fn.readfile, vim.fs.joinpath(dir, name))
    return ok and table.concat(lines, "\n"):find('"prettier"', 1, true) ~= nil
  end)
  if root and vim.fn.executable(vim.fs.joinpath(root, "node_modules/.bin/prettier")) == 1 then
    return root
  end
end

local prettier_filetypes = {
  "astro",
  "css",
  "graphql",
  "html",
  "javascript",
  "javascriptreact",
  "json",
  "jsonc",
  "less",
  "markdown",
  "markdown.mdx",
  "scss",
  "svelte",
  "typescript",
  "typescriptreact",
  "vue",
  "yaml",
}

local formatters_by_ft = {
  bash = { "shfmt" },
  lua = { "stylua" },
  sh = { "shfmt" },
}
for _, ft in ipairs(prettier_filetypes) do
  formatters_by_ft[ft] = { "prettier" }
end

return {
  {
    "stevearc/conform.nvim",
    event = "BufWritePre",
    cmd = "ConformInfo",
    keys = {
      {
        "<leader>cf",
        function()
          require("conform").format(vim.tbl_extend("force", format_opts, { async = true }))
        end,
        mode = { "n", "x" },
        desc = "Format",
      },
    },
    opts = {
      formatters_by_ft = formatters_by_ft,
      format_on_save = function(bufnr)
        organize_imports(bufnr)
        return vim.tbl_extend("force", format_opts, { timeout_ms = 3000 })
      end,
      formatters = {
        prettier = {
          command = function(_, ctx)
            return vim.fs.joinpath(prettier_root(ctx.filename), "node_modules/.bin/prettier")
          end,
          cwd = function(_, ctx)
            return prettier_root(ctx.filename)
          end,
          condition = function(_, ctx)
            return prettier_root(ctx.filename) ~= nil
          end,
        },
      },
    },
  },
  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      local lint = require("lint")
      -- Windowsなど実行ファイルが無い環境で、lintのたびにspawn失敗を通知させない。
      lint.linters_by_ft = {}
      if vim.fn.executable("hadolint") == 1 then
        lint.linters_by_ft.dockerfile = { "hadolint" }
      end

      vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost", "InsertLeave" }, {
        group = vim.api.nvim_create_augroup("dotfiles_lint", { clear = true }),
        callback = function()
          lint.try_lint()
        end,
      })
    end,
  },
}
