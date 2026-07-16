return {
  on_attach = function(client)
    -- 型情報とhoverはPyrightへ一本化する。
    client.server_capabilities.hoverProvider = false
  end,
  init_options = {
    settings = { logLevel = "error" },
  },
}
