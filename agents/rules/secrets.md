## Secrets

- Never put raw secrets (tokens, API keys, passwords, private keys, cookies) in
  command text: no inline `TOKEN=... cmd`, curl headers, query strings, or
  heredocs. Command text lands in shell history, process lists, and transcripts.
- Read secrets at run time from an existing source instead, such as
  `$(gh auth token)` or an environment variable, and write `<token>` in prose.
- Do not echo, log, summarise, or commit secret values. If one is exposed, tell
  me to rotate it; deleting history is not enough.
