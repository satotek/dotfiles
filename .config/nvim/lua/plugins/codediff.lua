-- 差分レビュー・ファイル履歴・コンフリクト解決をVS Code風の左右差分で行う。
-- stage/commitなどの操作はlazygit(<leader>gg)とneogit(<leader>gn)。
-- 差分計算用のライブラリは初回利用時に自動でダウンロードされる。
---@type LazySpec
return {
  "esmuellert/codediff.nvim",
  cmd = "CodeDiff",
  keys = {
    { "<leader>gd", "<cmd>CodeDiff<cr>", desc = "CodeDiff (working tree)" },
    -- <leader>ghはgitsignsのHunksグループなので避けてgH/gFを使う。
    { "<leader>gH", "<cmd>CodeDiff history<cr>", desc = "CodeDiff history (repo)" },
    { "<leader>gF", "<cmd>CodeDiff history %<cr>", desc = "CodeDiff history (current file)" },
    -- 選んだ行を変更したコミットだけをたどる。
    { "<leader>gF", ":CodeDiff history<cr>", mode = "x", desc = "CodeDiff history (selected lines)" },
  },
  opts = {},
}
