// TUI plugin: show a session cache-hit badge in the prompt footer and open an
// anchored breakdown card (cached / uncached / output) above it on click.
// The total token count is intentionally not pinned; it lives in the card.
import { createSignal } from "solid-js"
import { Plugin, usePlugin } from "@opencode/plugin/tui"

type Usage = {
  input: number
  output: number
  reasoning: number
  cached: number
  cacheWrite: number
  total: number
  hit: number
  steps: number
}

// The plugin context type cannot be resolved from a local checkout, so accept
// any and keep the surface limited to session.message.list, theme, router, and toast.
function usage(context: any, sessionID: string | undefined): Usage {
  const result: Usage = {
    input: 0,
    output: 0,
    reasoning: 0,
    cached: 0,
    cacheWrite: 0,
    total: 0,
    hit: 0,
    steps: 0,
  }
  if (!sessionID) return result

  const messages = context.data.session.message.list(sessionID) ?? []
  for (const message of messages) {
    if (message?.type !== "assistant" || !message.tokens) continue
    const tokens = message.tokens
    result.steps += 1
    result.input += tokens.input ?? 0
    result.output += tokens.output ?? 0
    result.reasoning += tokens.reasoning ?? 0
    result.cached += tokens.cache?.read ?? 0
    result.cacheWrite += tokens.cache?.write ?? 0
  }

  result.total = result.input + result.output + result.reasoning + result.cached + result.cacheWrite
  // Count only the input side: cached / (cached + uncached input).
  // Including output would make the hit rate look lower than it is.
  const input = result.input + result.cached
  result.hit = input > 0 ? (result.cached / input) * 100 : 0
  return result
}

function exact(value: number) {
  return value.toLocaleString()
}

function currentSessionID(context: any) {
  const route = context.ui.router.current()
  return route?.type === "session" ? route.sessionID : undefined
}

function UsageCard(props: { context: any; sessionID: string }) {
  const context = props.context
  const u = () => usage(context, props.sessionID)
  const row = (label: string, value: string) => (
    <box flexDirection="row" justifyContent="space-between" width={48}>
      <text fg={context.theme.text.muted}>{label}</text>
      <text fg={context.theme.text.base}>{value}</text>
    </box>
  )

  return (
    <box
      position="absolute"
      bottom={3}
      right={2}
      zIndex={100}
      flexDirection="column"
      gap={1}
      padding={1}
      width={50}
      backgroundColor={context.theme.background.raised.base}
    >
      <box flexDirection="row" justifyContent="space-between" width={48}>
        <text fg={context.theme.text.base}>Token usage</text>
        <text fg={context.theme.text.base}>{exact(u().total)} tok</text>
      </box>
      <box flexDirection="column">
        {row("Cache hit", `${u().hit.toFixed(1)}%`)}
        {row("Uncached input", exact(u().input))}
        {row("Cached input", exact(u().cached))}
        {u().cacheWrite > 0 ? row("Cache write", exact(u().cacheWrite)) : null}
        {row("Output", exact(u().output))}
        {u().reasoning > 0 ? row("Reasoning", exact(u().reasoning)) : null}
      </box>
      <text fg={context.theme.text.muted}>{`${u().steps} assistant steps`}</text>
    </box>
  )
}

function Badge(props: { sessionID?: string; active?: string; onToggle: (sessionID?: string) => void }) {
  const context = usePlugin()
  const u = () => usage(context, props.sessionID)
  const [hovered, setHovered] = createSignal(false)
  const open = () => Boolean(props.sessionID && props.active === props.sessionID)

  // onClick is only wired up for built-in OpenCode components, not raw boxes.
  // mousedown is consumed by text selection, so listen on mouseup instead.
  return (
    <box
      flexDirection="row"
      backgroundColor={hovered() || open() ? context.theme.background.raised.base : undefined}
      onMouseOver={() => setHovered(true)}
      onMouseOut={() => setHovered(false)}
      onMouseUp={() => props.onToggle(props.sessionID)}
    >
      <text fg={hovered() || open() ? context.theme.text.base : context.theme.text.muted}>
        {u().steps > 0 ? `cache ${u().hit.toFixed(1)}%` : ""}
      </text>
    </box>
  )
}

export default Plugin.define({
  id: "usage.tui",
  setup(context) {
    const [active, setActive] = createSignal<string | undefined>(undefined)
    const toggle = (sessionID?: string) => {
      if (!sessionID) {
        context.ui.toast.show({ message: "No active session", variant: "warning" })
        return
      }
      setActive((current) => (current === sessionID ? undefined : sessionID))
    }

    context.ui.slot({
      append: "app",
      render: () => {
        const sessionID = active()
        return sessionID ? <UsageCard context={context} sessionID={sessionID} /> : null
      },
    })

    context.ui.slot({
      append: "prompt.footer.status",
      render: (props: { sessionID?: string }) => (
        <Badge sessionID={props?.sessionID} active={active()} onToggle={toggle} />
      ),
    })

    // Take Escape only while the card is open so the prompt keeps its own binding.
    context.keymap.layer(() => ({
      mode: "global",
      priority: 10,
      commands: active()
        ? [
            {
              id: "usage.close",
              title: "Close token usage",
              bind: "escape",
              run: () => setActive(undefined),
            },
          ]
        : [],
    }))

    context.keymap.layer(() => ({
      mode: "global",
      commands: [
        {
          id: "usage.show",
          title: "Show token usage",
          group: "Usage",
          palette: true,
          slash: { name: "usage", aliases: ["tokens"] },
          run: () => toggle(currentSessionID(context)),
        },
      ],
    }))
  },
})
