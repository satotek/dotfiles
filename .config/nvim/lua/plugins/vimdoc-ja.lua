-- 'helplang'=jaで引く日本語ヘルプ本体。
-- lazy.nvimは未読み込みのプラグインのdoc/を索引しないため、:hやヘルプのpickerから
-- 常に引けるよう起動時に読み込む。Luaを含まずruntimepathに加わるだけなので軽い。
return {
  {
    "vim-jp/vimdoc-ja",
    lazy = false,
    -- 同梱のdoc/tags-jaはVimが生成したもので、lazy.nvimが更新時に走らせるNeovimの:helptagsは
    -- 先頭の!_TAG_FILE_ENCODING行を書かない。差分が残ると次の更新が止まるので、元に戻す。
    build = function(plugin)
      vim.system({ "git", "-C", plugin.dir, "checkout", "--", "doc/tags-ja" }):wait()
    end,
  },
}
