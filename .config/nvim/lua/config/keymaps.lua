local map = vim.keymap.set

map({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true, desc = "Down" })
map({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true, desc = "Up" })

map("n", "<C-h>", "<C-w>h", { remap = true, desc = "Go to Left Window" })
map("n", "<C-j>", "<C-w>j", { remap = true, desc = "Go to Lower Window" })
map("n", "<C-k>", "<C-w>k", { remap = true, desc = "Go to Upper Window" })
map("n", "<C-l>", "<C-w>l", { remap = true, desc = "Go to Right Window" })
map("n", "<C-Up>", "<cmd>resize +2<cr>", { desc = "Increase Window Height" })
map("n", "<C-Down>", "<cmd>resize -2<cr>", { desc = "Decrease Window Height" })
map("n", "<C-Left>", "<cmd>vertical resize -2<cr>", { desc = "Decrease Window Width" })
map("n", "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "Increase Window Width" })

map("n", "<A-j>", "<cmd>execute 'move .+' . v:count1<cr>==", { desc = "Move Down" })
map("n", "<A-k>", "<cmd>execute 'move .-' . (v:count1 + 1)<cr>==", { desc = "Move Up" })
map("i", "<A-j>", "<esc><cmd>move .+1<cr>==gi", { desc = "Move Down" })
map("i", "<A-k>", "<esc><cmd>move .-2<cr>==gi", { desc = "Move Up" })
map("x", "<A-j>", ":move '>+1<cr>gv=gv", { desc = "Move Down" })
map("x", "<A-k>", ":move '<-2<cr>gv=gv", { desc = "Move Up" })

map("n", "<S-h>", "<cmd>bprevious<cr>", { desc = "Previous Buffer" })
map("n", "<S-l>", "<cmd>bnext<cr>", { desc = "Next Buffer" })
map("n", "[b", "<cmd>bprevious<cr>", { desc = "Previous Buffer" })
map("n", "]b", "<cmd>bnext<cr>", { desc = "Next Buffer" })
map("n", "<leader>bb", "<cmd>buffer #<cr>", { desc = "Switch to Other Buffer" })
map("n", "<leader>bd", function()
  Snacks.bufdelete()
end, { desc = "Delete Buffer" })
map("n", "<leader>bo", function()
  Snacks.bufdelete.other()
end, { desc = "Delete Other Buffers" })

map({ "i", "x", "n", "s" }, "<C-s>", "<cmd>write<cr><esc>", { desc = "Save File" })
map({ "i", "n", "s" }, "<Esc>", function()
  vim.cmd.nohlsearch()
  return "<Esc>"
end, { expr = true, desc = "Escape and Clear Search" })
map("x", "<", "<gv")
map("x", ">", ">gv")
map("n", "<leader>l", "<cmd>Lazy<cr>", { desc = "Lazy" })
map("n", "<leader>fn", "<cmd>enew<cr>", { desc = "New File" })

local function diagnostic_jump(count, severity)
  return function()
    vim.diagnostic.jump({ count = count * vim.v.count1, severity = severity, float = true })
  end
end

map("n", "<leader>cd", vim.diagnostic.open_float, { desc = "Line Diagnostics" })
map("n", "]d", diagnostic_jump(1), { desc = "Next Diagnostic" })
map("n", "[d", diagnostic_jump(-1), { desc = "Previous Diagnostic" })
map("n", "]e", diagnostic_jump(1, vim.diagnostic.severity.ERROR), { desc = "Next Error" })
map("n", "[e", diagnostic_jump(-1, vim.diagnostic.severity.ERROR), { desc = "Previous Error" })
map("n", "]w", diagnostic_jump(1, vim.diagnostic.severity.WARN), { desc = "Next Warning" })
map("n", "[w", diagnostic_jump(-1, vim.diagnostic.severity.WARN), { desc = "Previous Warning" })
map("n", "[q", "<cmd>cprev<cr>", { desc = "Previous Quickfix" })
map("n", "]q", "<cmd>cnext<cr>", { desc = "Next Quickfix" })
map({ "n", "x" }, "<leader>cf", function()
  vim.lsp.buf.format({ async = true })
end, { desc = "Format" })

Snacks.toggle.option("spell", { name = "Spelling" }):map("<leader>us")
Snacks.toggle.option("wrap", { name = "Wrap" }):map("<leader>uw")
Snacks.toggle.option("relativenumber", { name = "Relative Number" }):map("<leader>uL")
Snacks.toggle.diagnostics():map("<leader>ud")
Snacks.toggle.line_number():map("<leader>ul")
Snacks.toggle.inlay_hints():map("<leader>uh")
Snacks.toggle.zoom():map("<leader>wm")
Snacks.toggle.zen():map("<leader>uz")

map("n", "<leader>-", "<C-w>s", { remap = true, desc = "Split Window Below" })
map("n", "<leader>|", "<C-w>v", { remap = true, desc = "Split Window Right" })
map("n", "<leader>wd", "<C-w>c", { remap = true, desc = "Delete Window" })
map("n", "<leader>qq", "<cmd>qa<cr>", { desc = "Quit All" })

map("n", "<leader><tab><tab>", "<cmd>tabnew<cr>", { desc = "New Tab" })
map("n", "<leader><tab>]", "<cmd>tabnext<cr>", { desc = "Next Tab" })
map("n", "<leader><tab>[", "<cmd>tabprevious<cr>", { desc = "Previous Tab" })
map("n", "<leader><tab>d", "<cmd>tabclose<cr>", { desc = "Close Tab" })
map("n", "<leader><tab>o", "<cmd>tabonly<cr>", { desc = "Close Other Tabs" })

map("n", "<leader>D", function()
  Snacks.terminal("oxker", {
    cwd = Snacks.git.get_root() or vim.uv.cwd(),
    win = { style = "lazygit" },
  })
end, { desc = "Oxker (Docker)" })
