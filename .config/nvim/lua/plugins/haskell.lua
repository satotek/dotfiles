-- lang.haskell のカスタマイズ。
return {
  -- Mason の haskell-language-server(1.7GB) を入れさせない。
  -- 既に ghcup 管理のシステム HLS があり、haskell-tools.nvim が PATH の HLS を
  -- 自動利用するため Mason 版は不要（実体は削除済み）。
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = vim.tbl_filter(function(tool)
        return tool ~= "haskell-language-server"
      end, opts.ensure_installed or {})
    end,
  },
  -- nvim-lint の外部 hlint を無効化。
  -- HLS が hlint プラグインを内蔵しており二重になる上、外部 hlint バイナリ未導入で
  -- "Error running hlint: ENOENT" が出ていたため。hlint 指摘は HLS 経由で受ける。
  {
    "mfussenegger/nvim-lint",
    opts = function(_, opts)
      if opts.linters_by_ft then
        opts.linters_by_ft.haskell = nil
      end
    end,
  },
  -- conform の外部フォーマッタ(fourmolu / cabal-fmt)を無効化。
  -- HLS が ormolu/fourmolu 整形を内蔵しているので、formatter を外すと保存時は
  -- LSP(HLS)整形にフォールバックする。→ Haskell ツールを全て ghcup HLS に一本化。
  {
    "stevearc/conform.nvim",
    opts = function(_, opts)
      if opts.formatters_by_ft then
        opts.formatters_by_ft.haskell = nil
        opts.formatters_by_ft.cabal = nil
      end
    end,
  },
}
