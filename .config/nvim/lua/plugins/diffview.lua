-- lazygit だと過去コミットの差分が細いパネルで読みづらいので、その閲覧を
-- diffview に寄せる。stage/commit などの操作は今まで通り lazygit(<leader>gg)。
-- 差分レビュー・ファイル履歴・3way マージ解決を全画面 side-by-side で担当する。
---@type LazySpec
return {
  "sindrets/diffview.nvim",
  -- コマンド/キー実行時に初めて読み込む（起動を軽く保つ）
  cmd = { "DiffviewOpen", "DiffviewFileHistory", "DiffviewClose" },
  keys = {
    -- 今の作業ツリー全体を左右差分でレビュー
    { "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Diffview open (working tree)" },
    -- 履歴を遡ってコミットを選び、その差分を全画面で読む（メイン用途）
    -- ※ <leader>gh は gitsigns の Hunks グループなので避けて gH/gF を使う
    { "<leader>gH", "<cmd>DiffviewFileHistory<cr>", desc = "Diffview file history (repo)" },
    -- 今開いているファイルだけの履歴を追う（<leader>gf は Snacks が使用中）
    { "<leader>gF", "<cmd>DiffviewFileHistory %<cr>", desc = "Diffview file history (current file)" },
  },
  opts = {
    -- diff は縦分割の左右2ペイン（side-by-side）
    view = {
      default = { layout = "diff2_horizontal" },
      -- マージ衝突時は 3way（OURS | 結果 | THEIRS）
      merge_tool = { layout = "diff3_mixed" },
    },
    -- diffview のパネル内でだけ効くキー
    keymaps = {
      view = {
        { "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close diffview" } },
      },
      file_panel = {
        { "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close diffview" } },
      },
      file_history_panel = {
        { "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close diffview" } },
      },
    },
  },
}
