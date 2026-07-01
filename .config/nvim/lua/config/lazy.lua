local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = {
    -- ============================================================
    -- LazyVim コア（snacks / lspconfig / mason / cmp / treesitter /
    -- which-key / conform / gitsigns / flash / trouble ... 約50個の土台）
    -- ============================================================
    { "LazyVim/LazyVim", import = "lazyvim.plugins" },

    -- ============================================================
    -- extras（旧 lazyvim.json → ここに明示 import 化）
    -- 各行のコメントは「その extra が連れてくる主なプラグイン」
    -- 卒業したら該当行を消し、lua/plugins/ に自前ファイルを置く
    -- ============================================================
    -- AI
    { import = "lazyvim.plugins.extras.ai.copilot" }, -- zbirenbaum/copilot.lua

    -- coding
    { import = "lazyvim.plugins.extras.coding.yanky" }, -- gbprod/yanky.nvim

    -- editor
    { import = "lazyvim.plugins.extras.editor.dial" }, -- monaqa/dial.nvim
    { import = "lazyvim.plugins.extras.editor.illuminate" }, -- RRethy/vim-illuminate
    { import = "lazyvim.plugins.extras.editor.inc-rename" }, -- smjonas/inc-rename.nvim
    { import = "lazyvim.plugins.extras.editor.snacks_picker" }, -- folke/snacks.nvim (picker有効化)

    -- lang（LSP × formatter × treesitter × dap の結線を各言語で提供）
    { import = "lazyvim.plugins.extras.lang.docker" },
    { import = "lazyvim.plugins.extras.lang.git" },
    { import = "lazyvim.plugins.extras.lang.go" },
    { import = "lazyvim.plugins.extras.lang.haskell" },
    { import = "lazyvim.plugins.extras.lang.json" },
    { import = "lazyvim.plugins.extras.lang.markdown" },
    { import = "lazyvim.plugins.extras.lang.prisma" },
    { import = "lazyvim.plugins.extras.lang.python" },
    { import = "lazyvim.plugins.extras.lang.rust" },
    { import = "lazyvim.plugins.extras.lang.sql" },
    { import = "lazyvim.plugins.extras.lang.tailwind" },
    { import = "lazyvim.plugins.extras.lang.terraform" }, -- terraform-ls + hcl treesitter + fmt
    { import = "lazyvim.plugins.extras.lang.toml" },
    { import = "lazyvim.plugins.extras.lang.typescript" },
    { import = "lazyvim.plugins.extras.lang.typescript.biome" },
    { import = "lazyvim.plugins.extras.lang.yaml" },

    -- test
    { import = "lazyvim.plugins.extras.test.core" }, -- neotest + nvim-dap

    -- ui
    { import = "lazyvim.plugins.extras.ui.mini-animate" }, -- nvim-mini/mini.animate
    { import = "lazyvim.plugins.extras.ui.treesitter-context" }, -- nvim-treesitter/nvim-treesitter-context

    -- util
    { import = "lazyvim.plugins.extras.util.mini-hipatterns" }, -- nvim-mini/mini.hipatterns
    { import = "lazyvim.plugins.extras.util.project" }, -- ahmedkhalf/project.nvim

    -- ============================================================
    -- 自前プラグイン（lua/plugins/*.lua）— 上書きが効くよう最後に
    -- ============================================================
    { import = "plugins" },
  },
  defaults = {
    -- By default, only LazyVim plugins will be lazy-loaded. Your custom plugins will load during startup.
    -- If you know what you're doing, you can set this to `true` to have all your custom plugins lazy-loaded by default.
    lazy = false,
    -- It's recommended to leave version=false for now, since a lot the plugin that support versioning,
    -- have outdated releases, which may break your Neovim install.
    version = false, -- always use the latest git commit
    -- version = "*", -- try installing the latest stable version for plugins that support semver
  },
  install = { colorscheme = { "tokyonight", "habamax" } },
  checker = {
    enabled = true, -- check for plugin updates periodically
    notify = false, -- notify on update
  }, -- automatically check for plugin updates
  performance = {
    rtp = {
      -- disable some rtp plugins
      disabled_plugins = {
        "gzip",
        -- "matchit",
        -- "matchparen",
        -- "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})
