-- ローマ字で日本語を検索する。`/nihongo` → 「日本語」にマッチする正規表現へ変換。
-- vim-kensaku が変換エンジン、kensaku-search が `/` 検索の <CR> に統合する。
-- denops.vim 依存（bad-apple 経由で既に導入済み）。
return {
  {
    "lambdalisue/vim-kensaku",
    dependencies = { "vim-denops/denops.vim" },
    event = "VeryLazy",
  },
  {
    "lambdalisue/kensaku-search.vim",
    dependencies = { "lambdalisue/vim-kensaku" },
    event = "CmdlineEnter",
    config = function()
      -- 検索(/ ?)の cmdline で <CR> を押すと romaji→日本語の正規表現に変換して実行。
      -- : コマンドラインでは素通り。必ず非再帰(remap=false=cnoremap相当)にすること。
      -- remap=true(cmap相当)にすると末尾<CR>が自分を呼び :qa 等が無限再帰する。
      vim.keymap.set("c", "<CR>", "<Plug>(kensaku-search-replace)<CR>", { remap = false })
    end,
  },
}
