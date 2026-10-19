---
name: web-fetch
description: Fetches and extracts web content with ax, xh, aria2c, and the host web tools. Use when asked to read a URL, research a topic, extract structured data from a page, download a large file, or handle a page that needs a real browser ("このURLを読んで", "Webで調べて", "ページから抽出して").
---

# Web Fetch

Pick the smallest tool that answers the request. Start with the host's own web
search/fetch for simple lookups; use `ax` for page text and extraction, `xh` for
APIs, `aria2c` for large downloads, and `agent-browser` only when the page needs
JavaScript, a login, or interaction.

## 1. Simple lookup

Use the harness's web search/fetch first. Fetch only the pages needed for the
answer and keep the source URLs.

## 2. Read a page

```sh
./ax <url>                 # status, final URL, headers, body
./ax <url> --md            # readable Markdown
./ax <url> --md --budget 800
```

`ax` is local and deterministic, and never silently prints an empty body. Use
`--md --budget` for prose; use the default report when status, redirects, or
headers matter.

If `ax` cannot fetch the page, fall back to:

```sh
xh -b <url>
curl -L <url>
```

Do not paste raw HTML into the conversation. Save it to a file and grep what you
need, or let `ax` extract it.

## 3. Discover and extract

```sh
./ax <url> --outline
./ax <url> --locate 'text'
./ax <url> '.item' --row 'title=a, href=a@href' --limit 20
./ax <url> --table
```

- `--outline` shows repeating structures without dumping HTML.
- `--locate` answers which selector holds a piece of text.
- `--row` extracts several fields in one call.
- `--table` turns a `<table>` into keyed rows.
- Results cap at 50. Use `--budget` or `--limit`.
- To continue, rerun with `--offset` from the truncation note; do not restart
  from zero.

## 4. APIs and JSON

Use `xh` when the target is an API rather than an HTML page:

```sh
xh GET https://api.example.com/users
xh POST https://api.example.com/items name=foo
```

## 5. Large files

Use `aria2c` for PDFs, datasets, archives, and media. It is a downloader, not a
text extractor.

```sh
mkdir -p ~/.cache/web-fetch
aria2c -x8 -s8 -c --dir="$HOME/.cache/web-fetch" <url>
```

Keep downloads under `~/.cache/web-fetch` and never execute a downloaded file
without inspecting it first.

## 6. JavaScript, login, or interaction

A browser is the last resort. Use the `agent-browser` skill, headless by default;
do not pass `--headed` for a fetch. Prefer the current app's own browser when it
has one.

## 7. Research across sources

For multi-page research, delegate the reading to the current agent's subagent and
ask for a digest with source URLs. Keep only the digest and the excerpts that must
be quoted verbatim. Do not pull whole pages into this context.

## Rules

- Include the final URL of each source in the answer.
- Prefer `ax` over ad-hoc HTML parsing.
- Use the smallest budget that answers the question; continue with `--offset`
  rather than re-fetching.
- Do not use a browser when `ax` or `xh` can do the job.
- This skill assumes no Exa, 1Password, or `tgrab`; add them only when needed.
