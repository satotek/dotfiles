## Delegation

- Every token read into this conversation is re-read on each later turn.
  Send work whose input is bulky but whose conclusion is short to your native
  subagent: codebase searches, reading docs or pages, summarising logs and
  test output. Ask for the conclusion, with paths and line numbers, not the
  raw material.
- Keep work here when it needs this conversation's history, or when doing it
  is quicker than writing the brief.
- Claude Code subagents are forced onto Haiku. Give them reading and
  summarising, not implementation or design decisions.
- Implementation may be delegated when the brief is cheaper than the work.
  Write a self-contained brief (files, intended change, how to verify), then
  read the returned diff before building on it. Inside T3 Code, use
  `delegate_task` with an explicit `target.model` and pick a model that fits
  the step; outside T3 Code, implement it yourself.
- Review goes to another vendor's model through the `review` skill.
