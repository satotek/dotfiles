-- Parser一覧は言語Extraに分散させず、ここで一元管理する。
-- Treesitter本体の初期化とparser更新は引き続きLazyVimコアへ任せる。
return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      -- LazyVimコアの既定値へ追記せず、この一覧を唯一の定義にする。
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
  },
  {
    "nvim-treesitter/nvim-treesitter-context",
    opts = {},
  },
}
