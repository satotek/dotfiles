return {
  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    ft = { "markdown" },
    -- 既定の mkdp#util#install は yarn 前提で、yarn 未導入の環境ではビルドに失敗し
    -- app/node_modules が作られず "Cannot find module 'tslib'" になる。
    -- npm(nix経由で導入済み)で app 依存を入れるビルドに変更して環境非依存にする。
    build = "cd app && npm install",
    init = function()
      -- リモート(SSH/ヘッドレス)判定: SSH接続あり、または Linux で GUI(DISPLAY)無し
      local is_remote = vim.env.SSH_CONNECTION ~= nil
        or (vim.fn.has("mac") == 0 and vim.env.DISPLAY == nil and vim.env.WAYLAND_DISPLAY == nil)

      -- 共通: ポート固定＋URL表示（どこでも SSH ポートフォワードしやすく）
      vim.g.mkdp_port = "8090"
      vim.g.mkdp_echo_preview_url = 1

      if is_remote then
        -- リモート: 表示する画面が無いのでブラウザ自動起動しない。
        -- localhost 待受のまま `ssh -L 8090:localhost:8090` で手元ブラウザから見る。
        -- （open_to_the_world=1 は URL が LAN IP になり手元から届かないので使わない）
        -- 手順: :MarkdownPreview → 表示された http://localhost:8090/... を手元で開く。
        vim.g.mkdp_auto_start = 0
        vim.g.mkdp_browser = "true" -- /usr/bin/true = no-op。ブラウザ起動を試みない
      end
      -- ローカル(Mac/GUI)は既定のまま: <leader>cp で手元ブラウザが開く
    end,
  },
  {
    "MeanderingProgrammer/render-markdown.nvim",
    opts = {
      html = {
        comment = {
          conceal = false,
        },
      },
    },
  },
}
