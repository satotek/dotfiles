local function lsp_clients()
  local clients = vim.lsp.get_clients({ bufnr = 0 })
  local names = vim.tbl_map(function(client)
    return client.name
  end, clients)

  return "  " .. table.concat(names, ", ")
end

local function cwd()
  return vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
end

return {
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      local icons = LazyVim.config.icons

      opts.options = vim.tbl_deep_extend("force", opts.options or {}, {
        theme = "auto",
        globalstatus = true,
        component_separators = "",
        section_separators = "",
      })

      opts.sections = {
        lualine_a = {
          {
            "mode",
            icon = "",
            separator = { left = "", right = "" },
          },
        },
        lualine_b = {
          {
            "filetype",
            icon_only = true,
            padding = { left = 1, right = 0 },
          },
          {
            "filename",
            path = 0,
            separator = { left = "", right = "" },
            symbols = {
              modified = " ●",
              readonly = " ",
              unnamed = "[No Name]",
            },
          },
        },
        lualine_c = {
          {
            "branch",
            icon = "",
          },
          {
            "diff",
            symbols = {
              added = icons.git.added,
              modified = icons.git.modified,
              removed = icons.git.removed,
            },
          },
        },
        lualine_x = {
          {
            function()
              return "  " .. require("dap").status()
            end,
            cond = function()
              return package.loaded["dap"] and require("dap").status() ~= ""
            end,
            color = function()
              return { fg = Snacks.util.color("Debug") }
            end,
          },
          {
            require("lazy.status").updates,
            cond = require("lazy.status").has_updates,
            color = function()
              return { fg = Snacks.util.color("Special") }
            end,
          },
          {
            "diagnostics",
            symbols = {
              error = icons.diagnostics.Error,
              warn = icons.diagnostics.Warn,
              info = icons.diagnostics.Info,
              hint = icons.diagnostics.Hint,
            },
          },
          {
            lsp_clients,
            cond = function()
              return #vim.lsp.get_clients({ bufnr = 0 }) > 0
            end,
          },
        },
        lualine_y = {
          {
            function()
              return "󰉋"
            end,
            padding = { left = 1, right = 1 },
          },
          cwd,
          {
            "progress",
            separator = " ",
            padding = { left = 1, right = 0 },
          },
        },
        lualine_z = {
          {
            function()
              return ""
            end,
            padding = { left = 1, right = 1 },
          },
          {
            "location",
            fmt = function(location)
              return location:gsub(":", "/")
            end,
          },
        },
      }

      opts.inactive_sections = {
        lualine_a = {},
        lualine_b = {
          {
            "filename",
            path = 0,
          },
        },
        lualine_c = {},
        lualine_x = {},
        lualine_y = {},
        lualine_z = { "location" },
      }

      return opts
    end,
  },
}
