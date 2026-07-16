-- formatter機能を持つLSPだけを保存時整形へ接続する。
local formatter_clients = {
  biome = true,
  denols = true,
  efm = true,
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

return {
  {
    "lukas-reineke/lsp-format.nvim",
    lazy = false,
    opts = { sync = true },
    config = function(_, opts)
      require("lsp-format").setup(opts)

      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("lsp-format", { clear = true }),
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          local lint_only = client and client.name == "efm" and vim.bo[args.buf].filetype == "dockerfile"
          if not client or not formatter_clients[client.name] or lint_only then
            return
          end

          vim.b[args.buf].autoformat = false

          if client.name == "gopls" or client.name == "ruff" then
            vim.api.nvim_create_autocmd("BufWritePre", {
              group = vim.api.nvim_create_augroup(client.name .. "-organize-imports-" .. args.buf, { clear = true }),
              buffer = args.buf,
              callback = function()
                local params = vim.lsp.util.make_range_params(0, client.offset_encoding)
                params.context = { only = { "source.organizeImports" }, diagnostics = {} }
                local response = client:request_sync("textDocument/codeAction", params, 1000, args.buf)
                for _, action in ipairs((response and response.result) or {}) do
                  if action.edit then
                    vim.lsp.util.apply_workspace_edit(action.edit, client.offset_encoding)
                  end
                  if action.command then
                    client:exec_cmd(action.command, { bufnr = args.buf })
                  end
                end
              end,
            })
          end

          require("lsp-format").on_attach(client, args.buf)
        end,
      })
    end,
  },
}
