-- 作業ディレクトリ(とgitブランチ)ごとにセッションを終了時に自動保存し、復元は手動で行う。
-- 保存先と名前の付け方はpersistence.nvimと同じにして、以前のセッションをそのまま読めるようにする。
local directory = vim.fs.joinpath(vim.fn.stdpath("state"), "sessions")

local function git_branch()
  local out = vim.fn.systemlist({ "git", "-C", vim.fn.getcwd(), "branch", "--show-current" })
  if vim.v.shell_error == 0 and out[1] and out[1] ~= "" then
    return out[1]
  end
end

-- main/master以外のブランチはブランチ名を付けた別セッションにする。
local function session_name(opts)
  local name = vim.fn.getcwd():gsub("[\\/:]+", "%%")
  local branch = opts and opts.branch == false and nil or git_branch()
  if branch and branch ~= "main" and branch ~= "master" then
    name = name .. "%%" .. branch:gsub("[\\/:]+", "%%")
  end
  return name .. ".vim"
end

local function exists(name)
  return vim.uv.fs_stat(vim.fs.joinpath(directory, name)) ~= nil
end

return {
  {
    "nvim-mini/mini.sessions",
    lazy = true,
    opts = {
      directory = directory,
      -- リポジトリにSession.vimを作らない。
      file = "",
      -- 読み込んだセッションではなく、終了時の作業ディレクトリのセッションへ保存する(下のinit)。
      autowrite = false,
      verbose = { read = false, write = false, delete = true },
    },
    init = function()
      vim.api.nvim_create_autocmd("VimLeavePre", {
        group = vim.api.nvim_create_augroup("dotfiles_session", { clear = true }),
        callback = function()
          if vim.g.dotfiles_session_disabled then
            return
          end
          -- ファイルを1つも開いていない起動(ダッシュボードだけ等)では上書きしない。
          local has_file = vim.iter(vim.api.nvim_list_bufs()):any(function(buf)
            return vim.bo[buf].buflisted and vim.bo[buf].buftype == "" and vim.api.nvim_buf_get_name(buf) ~= ""
          end)
          if has_file then
            vim.fn.mkdir(directory, "p")
            require("mini.sessions").write(session_name(), { force = true })
          end
        end,
      })
    end,
    keys = {
      {
        "<leader>qs",
        function()
          -- ブランチのセッションが無ければ、ディレクトリのセッションを読む。
          local name = session_name()
          if not exists(name) then
            name = session_name({ branch = false })
          end
          if exists(name) then
            require("mini.sessions").read(name)
          else
            vim.notify("No session for " .. vim.fn.getcwd(), vim.log.levels.WARN)
          end
        end,
        desc = "Restore Session",
      },
      {
        "<leader>qS",
        function()
          require("mini.sessions").select("read")
        end,
        desc = "Select Session",
      },
      {
        "<leader>ql",
        function()
          local sessions = require("mini.sessions")
          local latest = sessions.get_latest()
          if latest then
            sessions.read(latest)
          end
        end,
        desc = "Restore Last Session",
      },
      {
        "<leader>qd",
        function()
          vim.g.dotfiles_session_disabled = true
          vim.notify("Session will not be saved on exit")
        end,
        desc = "Don't Save Current Session",
      },
    },
  },
}
