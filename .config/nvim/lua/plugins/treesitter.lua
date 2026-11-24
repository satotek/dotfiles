-- Parser一覧はtreesitter-parsers.jsonで一元管理する。Nixのhome-managerも同じ一覧を読む。
local parsers = vim.json.decode(
  table.concat(vim.fn.readfile(vim.fs.joinpath(vim.fn.stdpath("config"), "treesitter-parsers.json")), "\n")
)

-- Nix環境ではhome-managerが、パーサーとクエリを同梱したnvim-treesitterをここへ置く。
-- パーサーとクエリが同じnixpkgsの版で揃うので、手元でのビルドや版ずれが起きない。
-- 置かれていない環境(Windowsなど)では従来どおりnvim-treesitterがビルドする。
local nix_dir = vim.fs.joinpath(vim.fn.stdpath("data"), "nix", "nvim-treesitter")
local use_nix = vim.uv.fs_stat(nix_dir) ~= nil

return {
  {
    "nvim-treesitter/nvim-treesitter",
    dir = use_nix and nix_dir or nil,
    branch = "main",
    version = false,
    build = not use_nix and ":TSUpdate" or nil,
    event = { "BufReadPost", "BufNewFile", "VeryLazy" },
    cmd = { "TSInstall", "TSLog", "TSUninstall", "TSUpdate" },
    init = function()
      -- ヘルプはlazy.nvimに:helptagsを書き込ませないよう、別ディレクトリで渡される。
      if use_nix then
        vim.opt.runtimepath:append(vim.fs.joinpath(vim.fn.stdpath("data"), "nix", "nvim-treesitter-doc"))
      end
    end,
    config = function()
      local treesitter = require("nvim-treesitter")
      treesitter.setup({})

      if not use_nix then
        local installed = treesitter.get_installed()
        local missing = vim.tbl_filter(function(parser)
          return not vim.list_contains(installed, parser)
        end, parsers)
        if #missing > 0 then
          treesitter.install(missing, { summary = true })
        end
      end

      -- get_installed()はnvim-treesitterのinstall_dirしか見ないので、Nixで置いたパーサーや
      -- Neovim同梱のパーサーも拾えるようruntimepathから読み込めるかで判定する。
      local function attach(buffer)
        local filetype = vim.bo[buffer].filetype
        if filetype == "" then
          return
        end
        local lang = vim.treesitter.language.get_lang(filetype) or filetype
        local ok, loaded = pcall(vim.treesitter.language.add, lang)
        if ok and loaded and pcall(vim.treesitter.start, buffer, lang) then
          for _, win in ipairs(vim.fn.win_findbuf(buffer)) do
            vim.wo[win][0].foldmethod = "expr"
            vim.wo[win][0].foldexpr = "v:lua.vim.treesitter.foldexpr()"
          end
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
