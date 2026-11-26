-- CSV/TSVの列をvirtual textで揃えて表示する。バッファ自体は書き換えないので、保存してもdiffが汚れない。
return {
  {
    "hat0uma/csvview.nvim",
    ft = { "csv", "tsv" },
    cmd = { "CsvViewEnable", "CsvViewDisable", "CsvViewToggle" },
    ---@module "csvview"
    ---@type CsvView.Options
    opts = {
      parser = { comments = { "#", "//" } },
      view = { display_mode = "border" },
      keymaps = {
        textobject_field_inner = { "if", mode = { "o", "x" } },
        textobject_field_outer = { "af", mode = { "o", "x" } },
        jump_next_field_end = { "<Tab>", mode = { "n", "v" } },
        jump_prev_field_end = { "<S-Tab>", mode = { "n", "v" } },
        jump_next_row = { "<Enter>", mode = { "n", "v" } },
        jump_prev_row = { "<S-Enter>", mode = { "n", "v" } },
      },
    },
    config = function(_, opts)
      require("csvview").setup(opts)
      -- ftでロードされた最初のバッファにもFileTypeは既に過ぎているので、ここで有効化しておく。
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "csv", "tsv" },
        callback = function(args)
          require("csvview").enable(args.buf)
        end,
      })
      local ft = vim.bo.filetype
      if ft == "csv" or ft == "tsv" then
        require("csvview").enable(0)
      end
    end,
  },
}
