local function dial(increment, g)
  local mode = vim.fn.mode(true)
  local visual = mode == "v" or mode == "V" or mode == "\22"
  local action = (increment and "inc" or "dec") .. (g and "_g" or "_") .. (visual and "visual" or "normal")
  local group = vim.g.dials_by_ft[vim.bo.filetype] or "default"
  return require("dial.map")[action](group)
end

return {
  {
    "monaqa/dial.nvim",
    keys = {
      {
        "<C-a>",
        function()
          return dial(true)
        end,
        expr = true,
        desc = "Increment",
        mode = { "n", "v" },
      },
      {
        "<C-x>",
        function()
          return dial(false)
        end,
        expr = true,
        desc = "Decrement",
        mode = { "n", "v" },
      },
      {
        "g<C-a>",
        function()
          return dial(true, true)
        end,
        expr = true,
        desc = "Increment",
        mode = { "n", "x" },
      },
      {
        "g<C-x>",
        function()
          return dial(false, true)
        end,
        expr = true,
        desc = "Decrement",
        mode = { "n", "x" },
      },
    },
    config = function()
      local augend = require("dial.augend")
      local default = {
        augend.integer.alias.decimal,
        augend.integer.alias.decimal_int,
        augend.integer.alias.hex,
        augend.date.alias["%Y/%m/%d"],
        augend.constant.alias.en_weekday,
        augend.constant.alias.en_weekday_full,
        augend.constant.alias.bool,
        augend.constant.alias.Bool,
        augend.constant.new({ elements = { "&&", "||" }, word = false, cyclic = true }),
      }
      local groups = {
        default = default,
        typescript = { augend.constant.new({ elements = { "let", "const" } }) },
        css = { augend.hexcolor.new({ case = "lower" }), augend.hexcolor.new({ case = "upper" }) },
        markdown = {
          augend.constant.new({ elements = { "[ ]", "[x]" }, word = false, cyclic = true }),
          augend.misc.alias.markdown_header,
        },
        json = { augend.semver.alias.semver },
        lua = { augend.constant.new({ elements = { "and", "or" }, word = true, cyclic = true }) },
        python = { augend.constant.new({ elements = { "and", "or" } }) },
      }
      for name, group in pairs(groups) do
        if name ~= "default" then
          vim.list_extend(group, default)
        end
      end
      require("dial.config").augends:register_group(groups)
      vim.g.dials_by_ft = {
        css = "css",
        sass = "css",
        scss = "css",
        vue = "css",
        javascript = "typescript",
        javascriptreact = "typescript",
        typescript = "typescript",
        typescriptreact = "typescript",
        json = "json",
        lua = "lua",
        markdown = "markdown",
        python = "python",
      }
    end,
  },
}
