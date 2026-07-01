return {
    {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    ft = { "markdown" },
    -- 既定の mkdp#util#install は yarn 前提で、yarn 未導入の環境ではビルドに失敗し
    -- app/node_modules が作られず "Cannot find module 'tslib'" になる。
    -- npm(nix経由で導入済み)で app 依存を入れるビルドに変更して環境非依存にする。
    build = "cd app && npm install",
    }
}