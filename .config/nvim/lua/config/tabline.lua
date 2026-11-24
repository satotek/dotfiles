-- mini.tablineの前に空白を足し、左端のSnacksエクスプローラーの幅だけタブをずらす。
-- mini.tablineにはbufferlineのoffsetsに当たる機能がない。
local M = {}

-- Snacksのサイドバーは、snacks_layout_boxのウィンドウが一覧と入力欄を包んでいる。
local function sidebar_width()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].filetype == "snacks_layout_box" and vim.api.nvim_win_get_position(win)[2] == 0 then
      -- 右隣のウィンドウとの縦の区切り線の1列を足すと、本文の左端とそろう。
      return vim.api.nvim_win_get_width(win) + 1
    end
  end
  return 0
end

function M.render()
  local tabs = MiniTabline.make_tabline_string()
  local width = sidebar_width()
  if width == 0 then
    return tabs
  end
  -- mini.tablineは画面全体の幅で並べるので、ずらした分だけはみ出ることがある。
  -- %<で、はみ出たときは空白ではなくタブ側の左から切り詰める。
  return "%#MiniTablineFill#" .. string.rep(" ", width) .. "%<" .. tabs
end

return M
