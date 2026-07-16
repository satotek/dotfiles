local function root()
  return Snacks.git.get_root() or vim.uv.cwd()
end

local function with_root(source, opts)
  return function()
    opts = vim.tbl_deep_extend("force", { cwd = root() }, opts or {})
    Snacks.picker[source](opts)
  end
end

return {
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    opts = {
      input = { enabled = true },
      picker = {
        enabled = true,
        ui_select = true,
        sources = {
          explorer = { hidden = true, ignored = false },
        },
      },
      bigfile = { enabled = true },
      quickfile = { enabled = true },
      notifier = { enabled = true },
      words = { enabled = true },
    },
    keys = {
      {
        "<leader>,",
        function()
          Snacks.picker.buffers()
        end,
        desc = "Buffers",
      },
      { "<leader>/", with_root("grep"), desc = "Grep (Root Dir)" },
      {
        "<leader>:",
        function()
          Snacks.picker.command_history()
        end,
        desc = "Command History",
      },
      { "<leader><space>", with_root("files"), desc = "Find Files (Root Dir)" },
      {
        "<leader>n",
        function()
          Snacks.picker.notifications()
        end,
        desc = "Notification History",
      },
      {
        "<leader>fb",
        function()
          Snacks.picker.buffers()
        end,
        desc = "Buffers",
      },
      {
        "<leader>fB",
        function()
          Snacks.picker.buffers({ hidden = true, nofile = true })
        end,
        desc = "Buffers (all)",
      },
      {
        "<leader>fc",
        function()
          Snacks.picker.files({ cwd = vim.fn.stdpath("config") })
        end,
        desc = "Find Config File",
      },
      { "<leader>ff", with_root("files"), desc = "Find Files (Root Dir)" },
      {
        "<leader>fF",
        function()
          Snacks.picker.files()
        end,
        desc = "Find Files (cwd)",
      },
      {
        "<leader>fg",
        function()
          Snacks.picker.git_files()
        end,
        desc = "Find Files (git-files)",
      },
      {
        "<leader>fr",
        function()
          Snacks.picker.recent()
        end,
        desc = "Recent",
      },
      {
        "<leader>fR",
        function()
          Snacks.picker.recent({ filter = { cwd = true } })
        end,
        desc = "Recent (cwd)",
      },
      {
        "<leader>fp",
        function()
          Snacks.picker.projects()
        end,
        desc = "Projects",
      },
      {
        "<leader>gd",
        function()
          Snacks.picker.git_diff()
        end,
        desc = "Git Diff",
      },
      {
        "<leader>gs",
        function()
          Snacks.picker.git_status()
        end,
        desc = "Git Status",
      },
      {
        "<leader>sb",
        function()
          Snacks.picker.lines()
        end,
        desc = "Buffer Lines",
      },
      {
        "<leader>sB",
        function()
          Snacks.picker.grep_buffers()
        end,
        desc = "Grep Open Buffers",
      },
      { "<leader>sg", with_root("grep"), desc = "Grep (Root Dir)" },
      {
        "<leader>sG",
        function()
          Snacks.picker.grep()
        end,
        desc = "Grep (cwd)",
      },
      { "<leader>sw", with_root("grep_word"), desc = "Word (Root Dir)", mode = { "n", "x" } },
      {
        "<leader>sW",
        function()
          Snacks.picker.grep_word()
        end,
        desc = "Word (cwd)",
        mode = { "n", "x" },
      },
      {
        '<leader>s"',
        function()
          Snacks.picker.registers()
        end,
        desc = "Registers",
      },
      {
        "<leader>s/",
        function()
          Snacks.picker.search_history()
        end,
        desc = "Search History",
      },
      {
        "<leader>sa",
        function()
          Snacks.picker.autocmds()
        end,
        desc = "Autocmds",
      },
      {
        "<leader>sC",
        function()
          Snacks.picker.commands()
        end,
        desc = "Commands",
      },
      {
        "<leader>sd",
        function()
          Snacks.picker.diagnostics()
        end,
        desc = "Diagnostics",
      },
      {
        "<leader>sD",
        function()
          Snacks.picker.diagnostics_buffer()
        end,
        desc = "Buffer Diagnostics",
      },
      {
        "<leader>sh",
        function()
          Snacks.picker.help()
        end,
        desc = "Help Pages",
      },
      {
        "<leader>sk",
        function()
          Snacks.picker.keymaps()
        end,
        desc = "Keymaps",
      },
      {
        "<leader>sm",
        function()
          Snacks.picker.marks()
        end,
        desc = "Marks",
      },
      {
        "<leader>sq",
        function()
          Snacks.picker.qflist()
        end,
        desc = "Quickfix List",
      },
      {
        "<leader>sR",
        function()
          Snacks.picker.resume()
        end,
        desc = "Resume",
      },
      {
        "<leader>st",
        function()
          Snacks.picker.todo_comments()
        end,
        desc = "Todo",
      },
      {
        "<leader>uC",
        function()
          Snacks.picker.colorschemes()
        end,
        desc = "Colorschemes",
      },
    },
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        ["*"] = {
          keys = {
            {
              "gd",
              function()
                Snacks.picker.lsp_definitions()
              end,
              desc = "Goto Definition",
              has = "definition",
            },
            {
              "gr",
              function()
                Snacks.picker.lsp_references()
              end,
              desc = "References",
              nowait = true,
            },
            {
              "gI",
              function()
                Snacks.picker.lsp_implementations()
              end,
              desc = "Goto Implementation",
            },
            {
              "gy",
              function()
                Snacks.picker.lsp_type_definitions()
              end,
              desc = "Goto Type Definition",
            },
            {
              "<leader>ss",
              function()
                Snacks.picker.lsp_symbols()
              end,
              desc = "LSP Symbols",
              has = "documentSymbol",
            },
            {
              "<leader>sS",
              function()
                Snacks.picker.lsp_workspace_symbols()
              end,
              desc = "LSP Workspace Symbols",
            },
          },
        },
      },
    },
  },
}
