-- nvim 内のターミナル（toggleterm 等）から `nvim <file>` した時に、
-- 子 nvim をネストさせず親 nvim で開く。git の $EDITOR やターミナル作業で効く。
-- ターミナル起動直後にパイプを仕込む必要があるため即ロード（遅延不可）。
return {
  "willothy/flatten.nvim",
  lazy = false,
  priority = 1001,
  opts = {},
}
