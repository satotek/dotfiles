-- indent 可視化を hlchunk に一本化。
-- 卒業した2つの役割を1プラグインで代替する:
--   indent module → 旧 indent-blankline（全階層のガイド線）
--   chunk  module → 旧 mini.indentscope（現在ブロックの強調。枠線で表示）
-- ryoppippi / mozumasu もこの構成。見た目は mozumasu 流（角丸チャンク枠）。
return {
  "shellRaining/hlchunk.nvim",
  event = { "BufReadPre", "BufNewFile" },
  opts = {
    chunk = {
      enable = true,
      chars = {
        horizontal_line = "─",
        vertical_line = "│",
        left_top = "╭",
        left_bottom = "╰",
        right_arrow = ">",
      },
      style = "#806d9c",
    },
    indent = {
      enable = true,
      chars = { "│" },
    },
    -- 行番号・空行の強調は使わない
    line_num = { enable = false },
    blank = { enable = false },
  },
}
