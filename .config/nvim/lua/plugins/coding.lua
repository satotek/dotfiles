local function buffer_textobject(ai_type)
  local first, last = 1, vim.fn.line("$")
  if ai_type == "i" then
    first, last = vim.fn.nextnonblank(first), vim.fn.prevnonblank(last)
    if first == 0 or last == 0 then
      return { from = { line = 1, col = 1 } }
    end
  end
  return {
    from = { line = first, col = 1 },
    to = { line = last, col = math.max(vim.fn.getline(last):len(), 1) },
  }
end

return {
  {
    "nvim-mini/mini.ai",
    event = "VeryLazy",
    opts = function()
      local ai = require("mini.ai")
      return {
        n_lines = 500,
        custom_textobjects = {
          o = ai.gen_spec.treesitter({
            a = { "@block.outer", "@conditional.outer", "@loop.outer" },
            i = { "@block.inner", "@conditional.inner", "@loop.inner" },
          }),
          f = ai.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }),
          c = ai.gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }),
          t = { "<([%p%w]-)%f[^<%w][^<>]->.-</%1>", "^<.->().*()</[^/]->$" },
          d = { "%f[%d]%d+" },
          e = {
            { "%u[%l%d]+%f[^%l%d]", "%f[%S][%l%d]+%f[^%l%d]", "%f[%P][%l%d]+%f[^%l%d]", "^[%l%d]+%f[^%l%d]" },
            "^().*()$",
          },
          g = buffer_textobject,
          u = ai.gen_spec.function_call(),
          U = ai.gen_spec.function_call({ name_pattern = "[%w_]" }),
        },
      }
    end,
  },
  {
    -- 括弧の自動補完と色分けを同じパーサーで行い、対応の取れない括弧も目立たせる。
    -- cmdlineでの色分けはui2が有効なときだけ働く。
    "saghen/blink.pairs",
    -- ビルド済みのバイナリはタグ付きリリースにしか無いので、リリース版に固定してダウンロードする。
    version = "*",
    dependencies = { "saghen/blink.lib" },
    build = function()
      require("blink.pairs").download():pwait(60000)
    end,
    event = { "BufReadPost", "BufNewFile", "InsertEnter", "CmdlineEnter" },
    opts = {
      highlights = {
        -- rainbow-delimitersの既定と同じ順に並べ、見た目を保つ。
        groups = {
          "BlinkPairsRed",
          "BlinkPairsYellow",
          "BlinkPairsBlue",
          "BlinkPairsOrange",
          "BlinkPairsGreen",
          "BlinkPairsPurple",
          "BlinkPairsCyan",
        },
        -- カーソル位置の対応はvim-matchupがif/endのような単語の対応まで含めて光らせる。
        matchparen = { enabled = false },
      },
    },
  },
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main",
    event = "VeryLazy",
    opts = {
      move = {
        enable = true,
        set_jumps = true,
      },
    },
    keys = {
      {
        "]f",
        function()
          require("nvim-treesitter-textobjects.move").goto_next_start("@function.outer", "textobjects")
        end,
        desc = "Next Function Start",
        mode = { "n", "x", "o" },
      },
      {
        "]F",
        function()
          require("nvim-treesitter-textobjects.move").goto_next_end("@function.outer", "textobjects")
        end,
        desc = "Next Function End",
        mode = { "n", "x", "o" },
      },
      {
        "[f",
        function()
          require("nvim-treesitter-textobjects.move").goto_previous_start("@function.outer", "textobjects")
        end,
        desc = "Previous Function Start",
        mode = { "n", "x", "o" },
      },
      {
        "[F",
        function()
          require("nvim-treesitter-textobjects.move").goto_previous_end("@function.outer", "textobjects")
        end,
        desc = "Previous Function End",
        mode = { "n", "x", "o" },
      },
      {
        "]c",
        function()
          require("nvim-treesitter-textobjects.move").goto_next_start("@class.outer", "textobjects")
        end,
        desc = "Next Class Start",
        mode = { "n", "x", "o" },
      },
      {
        "[c",
        function()
          require("nvim-treesitter-textobjects.move").goto_previous_start("@class.outer", "textobjects")
        end,
        desc = "Previous Class Start",
        mode = { "n", "x", "o" },
      },
      {
        "]a",
        function()
          require("nvim-treesitter-textobjects.move").goto_next_start("@parameter.inner", "textobjects")
        end,
        desc = "Next Parameter",
        mode = { "n", "x", "o" },
      },
      {
        "[a",
        function()
          require("nvim-treesitter-textobjects.move").goto_previous_start("@parameter.inner", "textobjects")
        end,
        desc = "Previous Parameter",
        mode = { "n", "x", "o" },
      },
    },
  },
  {
    "windwp/nvim-ts-autotag",
    event = { "BufReadPost", "BufNewFile" },
    opts = {},
  },
}
