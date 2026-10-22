# next-dev-loop

Vendored from the Next.js repository so this dotfiles repo does not need the
whole `vercel/next.js` tree as a flake input.

- Upstream: <https://github.com/vercel/next.js/blob/13ae649ea60769e91b06818e7b252c7e3040f92c/skills/next-dev-loop/SKILL.md>
- Revision: `13ae649ea60769e91b06818e7b252c7e3040f92c`
- License: MIT (see [LICENSE](./LICENSE))

Update by copying the upstream `skills/next-dev-loop/SKILL.md` again and
refreshing the revision above.

## Local changes

- The `agent-browser` install line points at the Nix-managed Home Manager
  package instead of `npm i -g`, because this dotfiles repo installs it through
  `llm-agents`. Reapply this change when updating from upstream.
