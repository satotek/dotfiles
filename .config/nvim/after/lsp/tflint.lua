-- TFLintはプロジェクトが設定を持つ場合だけ起動する。
return {
  root_dir = function(bufnr, on_dir)
    local filename = vim.api.nvim_buf_get_name(bufnr)
    local config = vim.fs.find({ ".tflint.hcl", ".tflint.json" }, {
      path = filename,
      upward = true,
    })[1]
    if config then
      on_dir(vim.fs.dirname(config))
    end
  end,
}
