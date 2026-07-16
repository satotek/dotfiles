-- Parser一覧は言語ごとに分散させず、ここで一元管理する。
return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    version = false,
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile", "VeryLazy" },
    cmd = { "TSInstall", "TSLog", "TSUninstall", "TSUpdate" },
    opts = function(_, opts)
      opts = opts or {}
      opts.ensure_installed = {
        -- Neovim・基本ファイル
        "bash",
        "c",
        "diff",
        "lua",
        "luadoc",
        "luap",
        "printf",
        "query",
        "regex",
        "vim",
        "vimdoc",

        -- Web
        "html",
        "javascript",
        "jsdoc",
        "json",
        "json5",
        "tsx",
        "typescript",
        "xml",
        "yaml",

        -- 言語
        "go",
        "gomod",
        "gosum",
        "gowork",
        "haskell",
        "python",
        "ron",
        "rst",
        "rust",
        "sql",

        -- 設定・インフラ
        "dockerfile",
        "hcl",
        "nix",
        "terraform",
        "toml",

        -- ドキュメント
        "markdown",
        "markdown_inline",

        -- Git
        "git_config",
        "gitcommit",
        "git_rebase",
        "gitignore",
        "gitattributes",
      }
      return opts
    end,
    config = function(_, opts)
      local treesitter = require("nvim-treesitter")
      treesitter.setup({})

      local installed = treesitter.get_installed()
      local missing = vim.tbl_filter(function(parser)
        return not vim.list_contains(installed, parser)
      end, opts.ensure_installed)
      if #missing > 0 then
        treesitter.install(missing, { summary = true })
      end

      local function attach(buffer)
        local filetype = vim.bo[buffer].filetype
        local lang = vim.treesitter.language.get_lang(filetype) or filetype
        if filetype ~= "" and vim.list_contains(treesitter.get_installed(), lang) then
          pcall(vim.treesitter.start, buffer, lang)
        end
      end

      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("dotfiles_treesitter", { clear = true }),
        callback = function(event)
          attach(event.buf)
        end,
      })

      for _, buffer in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(buffer) then
          attach(buffer)
        end
      end
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter-context",
    event = { "BufReadPost", "BufNewFile" },
    opts = {},
  },
}
