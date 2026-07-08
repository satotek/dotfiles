---@type LazySpec
return {
  "andymass/vim-matchup",
  event = "BufReadPost",
  init = function()
    vim.g.matchup_matchparen_enabled = 1
    vim.g.matchup_text_obj_enabled = 1
    vim.g.matchup_matchparen_deferred = 1
    vim.g.matchup_matchparen_deferred_show_delay = 0
    vim.g.matchup_matchparen_deferred_hide_delay = 700
    vim.g.matchup_matchparen_timeout = 300
    vim.g.matchup_matchparen_insert_timeout = 60
  end,
}
