return {
  before_init = function(_, config)
    config.settings = config.settings or {}
    config.settings.yaml = config.settings.yaml or {}
    config.settings.yaml.schemas = require("schemastore").yaml.schemas()
  end,
  settings = {
    redhat = { telemetry = { enabled = false } },
    yaml = {
      format = { enable = false },
      keyOrdering = false,
      schemaStore = { enable = false, url = "" },
      validate = true,
    },
  },
  on_init = function(client)
    client.server_capabilities.documentFormattingProvider = false
  end,
}
