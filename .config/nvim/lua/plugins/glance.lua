-- LSP の定義/参照/型/実装をフロートのプレビュー窓で確認する。
-- キーは lspconfig の opts.keys に登録して LazyVim 標準を「上書き」する。
--   ※ glance の keys= に置くとグローバル登録になり、LSP接続時のバッファローカル
--     キーマップ（LazyVim の gD=declaration 等）に負けて効かないため。
-- gD は元々 declaration だが、多くのサーバーが未対応で実質使えないので glance に転用。
return {
  {
    "dnlhc/glance.nvim",
    cmd = { "Glance" },
    opts = {
      border = { enable = true },
      list = { position = "left" },
      folds = { folded = false },
      -- 結果が1件でも必ずプレビュー窓を開く（before_open で jump しない）
    },
  },
  {
    "neovim/nvim-lspconfig",
    -- LazyVim は LSP キーを opts.servers["*"].keys から読む（init.lua:175）。
    -- 関数 opts で「最後に」append し、デフォルト(gD=declaration)を上書きする。
    opts = function(_, opts)
      opts.servers = opts.servers or {}
      opts.servers["*"] = opts.servers["*"] or {}
      local keys = opts.servers["*"].keys or {}
      vim.list_extend(keys, {
        -- gD/gR/gY/gM はすべて glance のプレビュー窓で表示（1件でも窓）
        { "gD", "<cmd>Glance definitions<cr>", desc = "Glance Definitions" },
        { "gR", "<cmd>Glance references<cr>", desc = "Glance References" },
        { "gY", "<cmd>Glance type_definitions<cr>", desc = "Glance Type Definitions" },
        { "gM", "<cmd>Glance implementations<cr>", desc = "Glance Implementations" },
      })
      opts.servers["*"].keys = keys
      return opts
    end,
  },
}
