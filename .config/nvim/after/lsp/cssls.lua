-- CSSの補完・診断・documentColorだけを使い、整形はBiome等へ任せる。
return {
  init_options = { provideFormatter = false },
  settings = {
    css = { format = { enable = false } },
    scss = { format = { enable = false } },
    less = { format = { enable = false } },
  },
  on_init = function(client)
    client.server_capabilities.documentFormattingProvider = false
    client.server_capabilities.documentRangeFormattingProvider = false
  end,
}
