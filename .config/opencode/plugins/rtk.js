// OpenCode v2 plugin that routes bash commands through `rtk rewrite`.
//
// rtk 0.51 only ships a v1 plugin, which v2 refuses to load (it requires a
// default export with `id` and `setup`). Upstream is working on v2 support in
// rtk-ai/rtk#3463; drop this file once `rtk init --opencode` covers v2.
//
// All rewrite rules stay in `rtk rewrite`, so this file only forwards commands.
import { execFile } from "node:child_process";

// `rtk rewrite` prints the rewritten command and exits 0 or 3; exit 1 means
// there is nothing to rewrite. Anything else falls back to the original command.
function rtkRewrite(command) {
  return new Promise((resolve) => {
    execFile("rtk", ["rewrite", command], { timeout: 5_000 }, (error, stdout) => {
      const code = error ? (error.code ?? -1) : 0;
      if (code !== 0 && code !== 3) return resolve(undefined);
      const rewritten = String(stdout).trim();
      resolve(rewritten && rewritten !== command ? rewritten : undefined);
    });
  });
}

export default {
  id: "rtk",
  async setup(ctx) {
    // Never throw from setup: a failing plugin shows up as an error in the TUI.
    if (typeof ctx?.tool?.hook !== "function") return;

    await ctx.tool.hook("execute.before", async (event) => {
      const tool = String(event?.tool ?? "").toLowerCase();
      if (tool !== "bash" && tool !== "shell") return;

      const args = event.input;
      if (!args || typeof args !== "object") return;
      if (typeof args.command !== "string" || !args.command) return;

      const rewritten = await rtkRewrite(args.command);
      if (rewritten) args.command = rewritten;
    });
  },
};
