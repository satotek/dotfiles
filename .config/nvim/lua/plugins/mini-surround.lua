-- coding.mini-surround extra から卒業した自前スペック。
-- LazyVim の extra は衝突回避のため `gs` プレフィックス（gsr 等）にしていたが、
-- ここでは mini.surround デフォルトの `s` プレフィックスに戻す。
--   sr})  → } を ) に置換 (Replace)
--   sa,sd,sf ... = Add / Delete / Find
-- 代償: Vim 標準の `s`(1文字消して挿入=cl) / `S`(行置換=cc) が surround に奪われる。
--       素の s が欲しければ cl/cc で代用する。
-- keys 関数は extra 本体を踏襲（mappings から遅延ロード用キーを生成）。
return {
  "nvim-mini/mini.surround",
  keys = function(_, keys)
    local opts = LazyVim.opts("mini.surround")
    local mappings = {
      { opts.mappings.add, desc = "Add Surrounding", mode = { "n", "x" } },
      { opts.mappings.delete, desc = "Delete Surrounding" },
      { opts.mappings.find, desc = "Find Right Surrounding" },
      { opts.mappings.find_left, desc = "Find Left Surrounding" },
      { opts.mappings.highlight, desc = "Highlight Surrounding" },
      { opts.mappings.replace, desc = "Replace Surrounding" },
      { opts.mappings.update_n_lines, desc = "Update `MiniSurround.config.n_lines`" },
    }
    mappings = vim.tbl_filter(function(m)
      return m[1] and #m[1] > 0
    end, mappings)
    return vim.list_extend(mappings, keys)
  end,
  opts = {
    mappings = {
      add = "sa", -- Add surrounding in Normal and Visual modes
      delete = "sd", -- Delete surrounding
      find = "sf", -- Find surrounding (to the right)
      find_left = "sF", -- Find surrounding (to the left)
      highlight = "sh", -- Highlight surrounding
      replace = "sr", -- Replace surrounding
      update_n_lines = "sn", -- Update `n_lines`
    },
  },
}
