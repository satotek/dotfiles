-- ローマ字で日本語を検索する。/nihongo → 「日本語」「にほんご」「ニホンゴ」に一致。
-- Neovim内蔵のLuaJITだけで動き、辞書も同梱されている。変換はlua/config/migemo.lua。
return {
  {
    "delphinus/luamigemo",
    version = "*",
    lazy = true,
    init = function()
      -- /と?の<CR>で入力をVim正規表現に置き換えてから検索する。:コマンドラインはそのまま。
      -- blink.pairsがcmdlineの<CR>をグローバルに上書きするので、検索中だけ優先される
      -- バッファローカルのマッピングにする。
      local group = vim.api.nvim_create_augroup("dotfiles_migemo_search", { clear = true })
      vim.api.nvim_create_autocmd("CmdlineEnter", {
        group = group,
        pattern = { "/", "\\?" },
        callback = function(event)
          -- 末尾の<CR>が自分を呼んで無限に繰り返さないよう、非再帰(remap=false)にする。
          vim.keymap.set("c", "<CR>", [[<C-\>ev:lua.require'config.migemo'.cmdline()<CR><CR>]], {
            buffer = event.buf,
            remap = false,
            desc = "Search Japanese by Romaji",
          })
        end,
      })
      vim.api.nvim_create_autocmd("CmdlineLeave", {
        group = group,
        pattern = { "/", "\\?" },
        callback = function(event)
          pcall(vim.keymap.del, "c", "<CR>", { buffer = event.buf })
        end,
      })
    end,
    keys = {
      {
        "<leader>sj",
        function()
          Snacks.picker.grep({
            title = "Grep (Romaji → 日本語)",
            -- 入力をripgrepが読める正規表現(PCRE)に変換してから、Snacks標準のgrepへ渡す。
            -- 表示中の入力欄は書き換えないよう、複製したctxに差し込む。
            finder = function(opts, ctx)
              local converted = ctx:clone()
              converted.filter = setmetatable(
                { search = require("config.migemo").query(ctx.filter.search, "pcre") },
                { __index = ctx.filter }
              )
              return require("snacks.picker.source.grep").grep(opts, converted)
            end,
          })
        end,
        desc = "Grep (Romaji → Japanese)",
      },
    },
  },
}
