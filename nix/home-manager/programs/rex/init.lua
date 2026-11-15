-- Herdr TUI に合わせた prefix キーバインド。
--
-- Herdr の「workspace / tab / pane」は Rex の「session / tab / pane」に
-- ほぼ対応する。agent の移動だけは Rex に対応する概念が無いため、
-- ペインの前後移動で近似する。

local prefix = "ctrl+q"

local function key(rest)
  return prefix .. ">" .. rest
end

-- prefix 自体を端末へ渡せるようにする。これが無いと ctrl+q は
-- シーケンスの開始として消費され、シェルやエディタへ届かない。
rex.bind(key("ctrl+q"), "pane.send_key", { key = "ctrl+q" })

-- Tabs
rex.bind(key("c"), "client.tab.new")
rex.bind(key("n"), "client.tab.next")
rex.bind(key("p"), "client.tab.previous")
rex.bind(key("shift+t"), "client.tab.rename")
rex.bind(key("shift+x"), "client.tab.close")
for i = 1, 9 do
  rex.bind(key(tostring(i)), "client.tab.goto", { index = i })
end

-- Panes
rex.bind(key("\\"), "pane.split", { direction = "right" })
rex.bind(key("v"), "pane.split", { direction = "right" })
rex.bind(key("-"), "pane.split", { direction = "down" })
rex.bind(key("h"), "pane.focus.left")
rex.bind(key("j"), "pane.focus.down")
rex.bind(key("k"), "pane.focus.up")
rex.bind(key("l"), "pane.focus.right")
rex.bind(key("tab"), "pane.focus_next")
rex.bind(key("shift+tab"), "pane.focus_previous")
rex.bind(key("x"), "pane.close")
rex.bind(key("z"), "pane.zoom")

-- Herdr の agent 移動に相当するものは Rex に無いので、ペイン移動にする。
rex.bind(key("shift+n"), "pane.focus_next")
rex.bind(key("shift+p"), "pane.focus_previous")

-- Resize mode
rex.mode("resize", { exclusive = true })
rex.bind(key("r"), "client.mode.enter", { name = "resize" })
rex.bind("resize/h", "pane.resize", { direction = "left" })
rex.bind("resize/j", "pane.resize", { direction = "down" })
rex.bind("resize/k", "pane.resize", { direction = "up" })
rex.bind("resize/l", "pane.resize", { direction = "right" })
rex.bind("resize/escape", "client.mode.exit")
rex.bind("resize/enter", "client.mode.exit")

-- Sessions (Herdr の workspace)
rex.bind(key("w"), "session.switch")
rex.bind(key("g"), "pane.go_to")
rex.bind(key("shift+c"), "session.new")
rex.bind(key("shift+w"), "session.rename")
rex.bind(key("shift+d"), "session.close")
rex.bind(key("shift+left"), "session.previous")
rex.bind(key("shift+right"), "session.next")

-- Client
rex.bind(key("b"), "client.sidebar.toggle")
rex.bind(key("s"), "client.settings")
rex.bind(key("shift+r"), "client.config.reload")
rex.bind(key("shift+/"), "client.palette.toggle")

-- Herdr の prefix+t / prefix+alt+g / prefix+alt+b は「新しいペインで
-- コマンドを開く」。Rex には該当アクションが無いので Lua で分割する。
local function split_terminal(command)
  return function(ctx)
    local block = {
      flavor = "com.superlogical.terminal.shell",
    }
    if command then
      block.options = {
        command = command,
        shell = "none",
        -- コマンドが終了してもペインを閉じない。
        exit = { on_completion = false },
      }
    end

    local _, err = rex.session.new_split{
      session_id = ctx.session_id,
      direction = "horizontal",
      side = "after",
      ratio = 0.5,
      focus = true,
      layout = rex.layout.block(block),
    }
    if err then
      rex.log("error", "rex key binding: " .. err)
    end

    return true
  end
end

rex.bind(key("t"), split_terminal(nil))
rex.bind(key("alt+g"), split_terminal({ "lazygit" }))
rex.bind(key("alt+b"), split_terminal({ "btop" }))
