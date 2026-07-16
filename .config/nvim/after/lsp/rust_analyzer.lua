return {
  settings = {
    ["rust-analyzer"] = {
      cargo = {
        allFeatures = true,
        buildScripts = { enable = true },
      },
      check = { command = "clippy" },
      files = {
        exclude = {
          ".direnv",
          ".git",
          ".github",
          ".gitlab",
          ".jj",
          ".venv",
          "bin",
          "node_modules",
          "target",
          "venv",
        },
        watcher = "client",
      },
      procMacro = { enable = true },
    },
  },
}
