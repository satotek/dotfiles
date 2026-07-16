-- LSP の定義/参照/型/実装をフロートのプレビュー窓で確認する。
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
}
