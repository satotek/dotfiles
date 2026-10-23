return {
  -- ルートが $HOME になると vault 全体（数万件の .md）を索引してメモリを食い潰す。
  -- マーカーの無い単発ファイルでは LSP を起動しない。
  root_dir = function(bufnr, on_dir)
    local root = vim.fs.root(bufnr, { ".moxide.toml", ".obsidian", ".git" })
    if root and root ~= vim.env.HOME then
      on_dir(root)
    end
  end,
}
