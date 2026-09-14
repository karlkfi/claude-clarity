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

Two sources, and the ID tells you which.

**Q146–Q301 were filed elsewhere.** They target skills that lived in a larger
private collection and moved here with them, keeping the IDs they were filed
under. Several name a neighbouring item — Q237, Q244, Q260, Q280, Q297 — that
stayed behind, so those references are deliberately not links: the row exists,
and not in this store. Their claims were re-pointed but not re-derived, which
[Q1004](Q1004.md) is about.

**Q1001 and up are this repo's own**, starting at a round number well clear of
the origin's sequence so a row moving in either direction can never collide with
one already there. The first six are the open remainder of the extraction: what
that plan left unfinished for this repo, rather than the plan itself, which
stays with the collection whose other bundles it schedules.

The ID allocator this store vendors claims IDs by pushing a ref to a shared
remote. This repo has no remote, so IDs here are picked by hand until it does.

## Vendored tooling

`scripts/queue.py` and `scripts/alloc-queue-id.sh` are copies, maintained
upstream and updated by copying the file again. Changes belong upstream rather
than here, or the next copy silently reverts them.
