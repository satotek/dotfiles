-- LazyVimコアが依存関係として追加するMasonを無効化する。
return {
  { "mason-org/mason.nvim", enabled = false },
  { "mason-org/mason-lspconfig.nvim", enabled = false },
}
