-- Magit流のgit操作画面。lazygit(<leader>gg)と使い比べるため別キーに置く。
-- Snacksの連携はインストール済みなら既定値(nil)のまま自動で有効になる。
return {
  {
    "NeogitOrg/neogit",
    cmd = "Neogit",
    dependencies = {
      "esmuellert/codediff.nvim",
      "folke/snacks.nvim",
    },
    keys = {
      {
        "<leader>gn",
        function()
          -- 開いているファイルのリポジトリを対象にする(cwdと違うworktreeでも迷わない)。
          require("neogit").open({ cwd = vim.fn.expand("%:p:h") })
        end,
        desc = "Neogit",
      },
    },
    opts = {
      -- diffのhunkにも言語の構文色を付ける。
      treesitter_diff_highlight = true,
      -- diffのポップアップ(d)はcodediffで開く。
      integrations = { codediff = true },
    },
  },
}
