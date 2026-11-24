local opt = vim.opt

opt.autowrite = true
opt.completeopt = "menu,menuone,noselect"
opt.conceallevel = 2
opt.confirm = true
opt.expandtab = true
opt.fillchars = {
  foldopen = "",
  foldclose = "",
  fold = " ",
  foldsep = " ",
  diff = "╱",
  eob = " ",
}
-- 起動時は全部開いた状態にする。treesitterが使えるバッファではtreesitter.luaが
-- foldexprに切り替え、使えないバッファはインデントで畳む。
opt.foldcolumn = "1"
opt.foldenable = true
opt.foldlevel = 99
opt.foldlevelstart = 99
opt.foldmethod = "indent"
opt.foldtext = "v:lua.require'config.foldtext'.render()"
opt.formatoptions = "jcroqlnt"
opt.grepformat = "%f:%l:%c:%m"
opt.grepprg = "rg --vimgrep"
opt.ignorecase = true
opt.inccommand = "nosplit"
opt.jumpoptions = "view"
opt.laststatus = 3
opt.linebreak = true
opt.list = true
opt.number = true
opt.pumblend = 10
-- 枠の指定をプラグインごとに書かず、標準のフロート(hover・診断など)をまとめて角丸にする。
opt.winborder = "rounded"
opt.pumheight = 10
opt.relativenumber = true
opt.ruler = false
opt.scrolloff = 4
opt.sessionoptions = { "buffers", "curdir", "tabpages", "winsize", "help", "globals", "skiprtp", "folds" }
opt.shiftround = true
opt.shiftwidth = 2
opt.shortmess:append({ W = true, I = true, c = true, C = true })
opt.showmode = false
opt.sidescrolloff = 8
opt.signcolumn = "yes"
opt.smartcase = true
opt.smartindent = true
opt.smoothscroll = true
opt.spelllang = { "en" }
opt.splitkeep = "screen"
opt.tabstop = 2
opt.termguicolors = true
opt.timeoutlen = 300
opt.undofile = true
opt.virtualedit = "block"
opt.wildmode = "longest:full,full"
opt.winminwidth = 5
opt.wrap = false

vim.g.markdown_recommended_style = 0

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

-- Windows の既定 'shell' は cmd.exe なので、ターミナルも :! も pwsh に揃える。
-- shellcmdflag 以下は :h shell-powershell の推奨値。出力を UTF-8 にし、
-- :make / :grep がリダイレクト先から結果を読めるようにする。
if vim.fn.has("win32") == 1 then
  vim.o.shell = vim.fn.executable("pwsh") == 1 and "pwsh" or "powershell"
  vim.o.shellcmdflag = "-NoLogo -NonInteractive -ExecutionPolicy RemoteSigned -Command "
    .. "[Console]::InputEncoding=[Console]::OutputEncoding=[System.Text.UTF8Encoding]::new();"
    .. "$PSDefaultParameterValues['Out-File:Encoding']='utf8';"
    .. "$PSStyle.OutputRendering='plaintext';"
    .. "Remove-Alias -Force -ErrorAction SilentlyContinue tee;"
  vim.o.shellredir = '2>&1 | %%{ "$_" } | Out-File %s; exit $LastExitCode'
  vim.o.shellpipe = '2>&1 | %%{ "$_" } | tee %s; exit $LastExitCode'
  vim.o.shellquote = ""
  vim.o.shellxquote = ""
end

-- メッセージとcmdlineは本体のUI(ui2)で表示する。実験的機能でモジュール名が
-- 変わりうるので、読み込めなければ従来のcmdlineのまま使う。
local ok_ui2, ui2 = pcall(require, "vim._core.ui2")
if ok_ui2 then
  -- cmdlineは使うときだけ最下段に出す。cmdheight=0では"cmd"の表示先が
  -- 見えないので、メッセージは右下の一時ウィンドウ("msg")へ送る。
  vim.o.cmdheight = 0
  ui2.enable({ msg = { targets = "msg" } })

  -- 0.12のLSPは進捗を自分では表示しないので、progressメッセージとして流す。
  -- 同じidで出し直すと上書きされ、進捗が積み重ならない。
  vim.api.nvim_create_autocmd("LspProgress", {
    group = vim.api.nvim_create_augroup("dotfiles_lsp_progress", { clear = true }),
    callback = function(event)
      local value = event.data.params.value
      vim.api.nvim_echo({ { value.message or "done" } }, false, {
        id = "lsp." .. event.data.params.token,
        kind = "progress",
        source = "vim.lsp",
        title = value.title,
        status = value.kind ~= "end" and "running" or "success",
        percent = value.percentage,
      })
    end,
  })
end
