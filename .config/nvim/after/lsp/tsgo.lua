-- nixpkgsのTypeScript 7は実行名がtsc。
return {
  cmd = { "tsc", "--lsp", "--stdio" },
}
