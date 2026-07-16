return {
  init_options = { provideFormatter = false },
  before_init = function(_, config)
    config.settings = config.settings or {}
    config.settings.json = config.settings.json or {}
    config.settings.json.schemas = require("schemastore").json.schemas()
  end,
  settings = {
    json = {
      format = { enable = false },
      validate = { enable = true },
    },
  },
}
