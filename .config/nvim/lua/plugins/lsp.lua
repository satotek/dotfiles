-- LSPの実行ファイルはNixまたはプロジェクトローカルで管理する。
-- サーバー固有の設定はafter/lsp/<server>.luaに置く。
local servers = {
  "bashls",
  "biome",
  "cssls",
  "denols",
  "efm",
  "eslint",
  "gopls",
  "jsonls",
  "lua_ls",
  "marksman",
  "nixd",
  "oxfmt",
  "oxlint",
  "pyright",
  "ruff",
  "rumdl",
  "rust_analyzer",
  "tailwindcss",
  "taplo",
  "terraformls",
  "tflint",
  "tsgo",
  "yamlls",
}

return {
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = { "b0o/SchemaStore.nvim" },
    config = function()
      -- Neovim 0.12純正のLSP色情報をインラインの色見本として表示する。
      vim.lsp.document_color.enable(true, nil, { style = "virtual" })

      local capabilities = require("blink.cmp").get_lsp_capabilities()
      for _, server in ipairs(servers) do
        vim.lsp.config(server, { capabilities = capabilities })
        vim.lsp.enable(server)
      end

      vim.diagnostic.config({
        severity_sort = true,
        underline = true,
        update_in_insert = false,
        virtual_text = { spacing = 2, source = "if_many" },
        float = { border = "rounded", source = true },
      })

      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("dotfiles_lsp_keymaps", { clear = true }),
        callback = function(event)
          local function map(lhs, rhs, desc, mode)
            vim.keymap.set(mode or "n", lhs, rhs, { buffer = event.buf, silent = true, desc = desc })
          end

          map("K", vim.lsp.buf.hover, "Hover")
          map("gd", function()
            Snacks.picker.lsp_definitions()
          end, "Goto Definition")
          map("gr", function()
            Snacks.picker.lsp_references()
          end, "References")
          map("gI", function()
            Snacks.picker.lsp_implementations()
          end, "Goto Implementation")
          map("gy", function()
            Snacks.picker.lsp_type_definitions()
          end, "Goto Type Definition")
          map("<leader>ss", function()
            Snacks.picker.lsp_symbols()
          end, "LSP Symbols")
          map("<leader>sS", function()
            Snacks.picker.lsp_workspace_symbols()
          end, "LSP Workspace Symbols")
          map("<leader>ca", vim.lsp.buf.code_action, "Code Action", { "n", "x" })
          map("<leader>cr", function()
            vim.cmd("IncRename " .. vim.fn.expand("<cword>"))
          end, "Rename", "n")
          map("gD", "<cmd>Glance definitions<cr>", "Glance Definitions")
          map("gR", "<cmd>Glance references<cr>", "Glance References")
          map("gY", "<cmd>Glance type_definitions<cr>", "Glance Type Definitions")
          map("gM", "<cmd>Glance implementations<cr>", "Glance Implementations")
        end,
      })
    end,
  },
}
