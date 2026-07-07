-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
-- swap を有効化して crash recovery を確保する（VM の突然停止対策）。
-- 実ファイルは書き換えないので auto-save のような保存時副作用は出ない。
-- swap の保存先はデフォルトの stdpath("state")/swap// に集約されるため、
-- 編集対象の隣に .swp は散らからない。
vim.opt.swapfile = true
-- swap をディスクへ書き出す間隔を短縮（既定 4000ms）。突然死時のロスを最小化。
vim.opt.updatetime = 250
vim.opt.autoread = true
vim.opt.mouse = "a"

vim.opt.cursorline = true
vim.opt.cursorcolumn = true
vim.opt.showmatch = true
vim.opt.showcmd = true

vim.opt.splitright = true
vim.opt.splitbelow = true

vim.opt.fenc = "utf-8"

vim.opt.undolevels = 1000

vim.opt.helplang = "ja"

vim.opt.clipboard = ""


local function paste()
  return {
    vim.fn.split(vim.fn.getreg(""), "\n"),
    vim.fn.getregtype(""),
  }
end

vim.g.clipboard = {
  name = "OSC 52",
  copy = {
    ["+"] = require("vim.ui.clipboard.osc52").copy("+"),
    ["*"] = require("vim.ui.clipboard.osc52").copy("*"),
  },
  paste = {
    ["+"] = paste,
    ["*"] = paste,
  },
}
