# Backlog

One file per item, priority held in each item's `rank` key rather than in its
position in a table. Two sessions editing different items cannot conflict,
whatever the merge algorithm and with no merge driver installed.

Read the ordered queue:

```bash
python3 scripts/queue.py --store docs/queue render
```

`next` prints the top ready item as a session kickoff prompt. `lint` checks
frontmatter, ids, ranks and references, and runs as part of `make validate`.

## No table lives here

A committed table of items restores line-position priority: two sessions
completing adjacent rows edit adjacent lines, which is the conflict the
per-item store exists to remove. Render one on demand instead.

## Item shape

Frontmatter carries `id`, `rank`, `labels`, `status`, `size`, and an optional
`target` naming the file the work lands in. The body is the finding: what was
measured, when, what would settle it. A row that only asserts a problem without
a measurement behind it is a note rather than an item.

An exhibit citation is `` `path:line:the words on that line` ``. The lint
re-finds the quoted text and tells you the current line when it has moved, so a
citation goes stale loudly rather than silently.

## Where these items came from

The ten items this store opened with were filed against skills that lived in a
larger private collection and moved here with them. Several name a neighbouring
item — Q237, Q244, Q260, Q280, Q297 — that stayed behind, so those references
are deliberately not links: the row exists, and not in this store.

## Vendored tooling

`scripts/queue.py` and `scripts/alloc-queue-id.sh` are copies, maintained
upstream and updated by copying the file again. Changes belong upstream rather
than here, or the next copy silently reverts them.
