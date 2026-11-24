-- 畳んだ行を「元の行のtreesitterハイライト + 󰁂 隠れた行数」で描く。
-- foldtext=""でも元の行のハイライトは出るが行数を足せないので、
-- foldtextがリストを返すとvirtual textとして描かれる仕組みを使って組み立てる。
local M = {}

-- 1行分の各列にtreesitterのハイライトグループを割り当てる。injectionも含め、
-- 後から見つかったcaptureで上書きして優先度の高いものを近似する。
local function line_highlights(buf, row, line)
  local hls = {}
  local ok, parser = pcall(vim.treesitter.get_parser, buf)
  if not ok or not parser then
    return hls
  end
  parser:for_each_tree(function(tree, ltree)
    local query = vim.treesitter.query.get(ltree:lang(), "highlights")
    if not query then
      return
    end
    for id, node in query:iter_captures(tree:root(), buf, row, row + 1) do
      local sr, sc, er, ec = node:range()
      if sr <= row and er >= row then
        local from = sr < row and 0 or sc
        local to = er > row and #line or ec
        local group = "@" .. query.captures[id] .. "." .. ltree:lang()
        for col = from, to - 1 do
          hls[col] = group
        end
      end
    end
  end)
  return hls
end

function M.render()
  local buf = vim.api.nvim_get_current_buf()
  local row = vim.v.foldstart - 1
  local line = vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1] or ""
  local hls = line_highlights(buf, row, line)
  local tab = string.rep(" ", vim.bo[buf].tabstop)

  local chunks = {}
  local text, group = "", hls[0]
  for col = 0, #line - 1 do
    if hls[col] ~= group then
      chunks[#chunks + 1] = { (text:gsub("\t", tab)), group or "Normal" }
      text, group = "", hls[col]
    end
    text = text .. line:sub(col + 1, col + 1)
  end
  chunks[#chunks + 1] = { (text:gsub("\t", tab)), group or "Normal" }
  chunks[#chunks + 1] = { (" 󰁂 %d "):format(vim.v.foldend - vim.v.foldstart), "MoreMsg" }
  return chunks
end

return M
