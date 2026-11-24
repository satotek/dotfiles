-- todo-commentsの既定と同じキーワード。ハイライト・移動・一覧のすべてがこれを使う。
local todo_groups = {
  MiniHipatternsFixme = { "FIX", "FIXME", "BUG", "FIXIT", "ISSUE" },
  MiniHipatternsHack = { "HACK", "WARN", "WARNING", "XXX", "PERF" },
  MiniHipatternsTodo = { "TODO" },
  MiniHipatternsNote = { "NOTE", "INFO", "TEST" },
}
local todo_keywords = vim.iter(vim.tbl_values(todo_groups)):flatten():totable()

local function todo_vim_pattern(keywords)
  return [[\v\C<(]] .. table.concat(keywords, "|") .. [[)>:]]
end

local function todo_rg_pattern(keywords)
  return [[\b(]] .. table.concat(keywords, "|") .. [[):]]
end

return {
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      signs = {
        add = { text = "▎" },
        change = { text = "▎" },
        delete = { text = "" },
        topdelete = { text = "" },
        changedelete = { text = "▎" },
        untracked = { text = "▎" },
      },
      signs_staged = {
        add = { text = "▎" },
        change = { text = "▎" },
        delete = { text = "" },
        topdelete = { text = "" },
        changedelete = { text = "▎" },
      },
      on_attach = function(buffer)
        local gs = require("gitsigns")
        local function map(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = buffer, desc = desc, silent = true })
        end

        map("n", "]h", function()
          if vim.wo.diff then
            vim.cmd.normal({ "]c", bang = true })
          else
            gs.nav_hunk("next")
          end
        end, "Next Hunk")
        map("n", "[h", function()
          if vim.wo.diff then
            vim.cmd.normal({ "[c", bang = true })
          else
            gs.nav_hunk("prev")
          end
        end, "Previous Hunk")
        map("n", "]H", function()
          gs.nav_hunk("last")
        end, "Last Hunk")
        map("n", "[H", function()
          gs.nav_hunk("first")
        end, "First Hunk")
        map({ "n", "x" }, "<leader>ghs", ":Gitsigns stage_hunk<CR>", "Stage Hunk")
        map({ "n", "x" }, "<leader>ghr", ":Gitsigns reset_hunk<CR>", "Reset Hunk")
        map("n", "<leader>ghS", gs.stage_buffer, "Stage Buffer")
        map("n", "<leader>ghu", gs.undo_stage_hunk, "Undo Stage Hunk")
        map("n", "<leader>ghR", gs.reset_buffer, "Reset Buffer")
        map("n", "<leader>ghp", gs.preview_hunk_inline, "Preview Hunk Inline")
        map("n", "<leader>ghb", function()
          gs.blame_line({ full = true })
        end, "Blame Line")
        map("n", "<leader>ghB", gs.blame, "Blame Buffer")
        map("n", "<leader>ghd", gs.diffthis, "Diff This")
        map("n", "<leader>ghD", function()
          gs.diffthis("~")
        end, "Diff This ~")
        map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", "Select Hunk")
      end,
    },
  },
  {
    -- TODOコメントのハイライト。一覧はSnacksのgrep、移動はsearch()で行う。
    "nvim-mini/mini.hipatterns",
    event = { "BufReadPost", "BufNewFile" },
    opts = function()
      -- todo-commentsと同じく、コロン付きのキーワードだけを対象にする。
      local highlighters = {}
      for group, keywords in pairs(todo_groups) do
        for _, keyword in ipairs(keywords) do
          highlighters[keyword] = { pattern = "%f[%w]()" .. keyword .. "():", group = group }
        end
      end
      return { highlighters = highlighters }
    end,
    keys = {
      {
        "]t",
        function()
          vim.fn.search(todo_vim_pattern(todo_keywords), "W")
        end,
        desc = "Next Todo Comment",
      },
      {
        "[t",
        function()
          vim.fn.search(todo_vim_pattern(todo_keywords), "bW")
        end,
        desc = "Previous Todo Comment",
      },
      {
        "<leader>st",
        function()
          Snacks.picker.grep({ search = todo_rg_pattern(todo_keywords), live = false, title = "Todo" })
        end,
        desc = "Todo",
      },
      {
        "<leader>sT",
        function()
          Snacks.picker.grep({
            search = todo_rg_pattern({ "TODO", "FIX", "FIXME" }),
            live = false,
            title = "Todo/Fix/Fixme",
          })
        end,
        desc = "Todo/Fix/Fixme",
      },
    },
  },
}
