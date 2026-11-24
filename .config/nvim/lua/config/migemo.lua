-- ローマ字を、ひらがな・カタカナ・漢字にも一致する正規表現へ変換する(luamigemo)。
-- IMEを切り替えずに日本語を検索するために、/検索とgrepから使う。
local M = {}

-- 英数字と空白だけの入力をローマ字とみなす。正規表現や日本語を直接打ったときは変換しない。
local function is_romaji(text)
  return text:match("^[%w%- ]+$") ~= nil
end

-- Nix環境ではhome-managerが、SKK-JISYO.L由来の大きい辞書をここに置く。
-- 同梱の辞書(BSD版)は語彙が少なく、例えばnihongoが日本語に変換されない。
local function engine()
  local luamigemo = require("luamigemo")
  local dict = vim.fs.joinpath(vim.fn.stdpath("data"), "nix", "migemo-compact-dict")
  if vim.uv.fs_stat(dict) then
    return luamigemo.get(dict), luamigemo
  end
  return luamigemo.get(), luamigemo
end

---@param text string
---@param dialect "vim"|"pcre"
---@return string
function M.query(text, dialect)
  if not is_romaji(text) then
    return text
  end
  local ok, pattern = pcall(function()
    local migemo, luamigemo = engine()
    return migemo:query(text, dialect == "vim" and luamigemo.RXOP_VIM or luamigemo.RXOP_PCRE)
  end)
  return ok and pattern ~= "" and pattern or text
end

-- cmdlineの<CR>から<C-\>eで呼び、/と?の検索だけをVim正規表現へ置き換える。
function M.cmdline()
  local text = vim.fn.getcmdline()
  local cmdtype = vim.fn.getcmdtype()
  if cmdtype ~= "/" and cmdtype ~= "?" then
    return text
  end
  return M.query(text, "vim")
end

return M
