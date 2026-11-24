return {
  {
    -- 開いているバッファを上部にタブのように並べる。並びはバッファ番号順で、:bnextと一致する。
    "nvim-mini/mini.tabline",
    event = "VeryLazy",
    opts = {
      -- 今のタブだけ左端に縦棒を付け、ほかは同じ幅の空白にして位置がずれないようにする。
      -- 棒だけ別の色にしたくても、%#Group#を混ぜると幅の計算が狂い、はみ出たときの切り詰めが壊れる。
      format = function(buf_id, label)
        local bar = buf_id == vim.api.nvim_get_current_buf() and "▎" or " "
        return bar .. require("mini.tabline").default_format(buf_id, label)
      end,
    },
    config = function(_, opts)
      require("mini.tabline").setup(opts)
      -- Snacksのエクスプローラーの幅だけずらす(lua/config/tabline.lua)。
      vim.o.tabline = "%!v:lua.require'config.tabline'.render()"
      -- setupはshowtablineを常に2にする。以前と同じく、バッファもタブページも1つなら隠す。
      local function update()
        local listed = #vim.fn.getbufinfo({ buflisted = 1 })
        vim.o.showtabline = (listed > 1 or #vim.api.nvim_list_tabpages() > 1) and 2 or 0
      end
      -- サイドバーの開閉や幅の変更は、tablineの再描画のきっかけにならないので明示する。
      vim.api.nvim_create_autocmd({ "WinNew", "WinClosed", "WinResized" }, {
        group = vim.api.nvim_create_augroup("dotfiles_tabline_offset", { clear = true }),
        callback = vim.schedule_wrap(function()
          vim.cmd.redrawtabline()
        end),
      })
      vim.api.nvim_create_autocmd({ "BufAdd", "BufDelete", "TabNew", "TabClosed" }, {
        group = vim.api.nvim_create_augroup("dotfiles_tabline_autohide", { clear = true }),
        -- BufDeleteの時点では消えるバッファがまだ一覧に残っているので、次のループで数える。
        callback = vim.schedule_wrap(update),
      })
      update()
    end,
  },
  {
    "folke/flash.nvim",
    event = "BufReadPost",
    opts = {
      modes = {
        char = { enabled = false },
        search = { enabled = false },
        treesitter = { enabled = false },
      },
    },
    keys = {
      {
        "<CR>",
        mode = { "n", "x", "o", "v" },
        function()
          require("flash").jump({ label = { before = true, after = false } })
        end,
        desc = "Flash",
      },
    },
  },
}
