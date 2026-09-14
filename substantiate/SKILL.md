---
name: substantiate
description: Route a draft through the evidence and writing passes in order, running only the ones its document type needs. Use when asked to "substantiate" a draft, and on requests that name no pass in particular — "review this doc", "clean this up", "go over this before I send it", "is this ready to publish", "check this over", "make this good". Also as the default entry point whenever a document needs more than one pass and you do not know which. Covers classifying the document and its reader, selecting passes by type, the run order and the two places the skills contradict each other, handing off to each pass instead of restating its rules, cost control before a long chain, and reporting what ran. Routes to verify-claims, claim-provenance, semantic-remediation, readability, brevity, deslop, tech-docs-layers, code-restraint, and rendered-page-review. Not a pass itself — it makes no edits of its own, and it never authors content the source did not supply.
---

# Substantiate

A draft fails in more than one way at once, and the failures are independent. Evidence that could not have shown the opposite. A guess delivered in the register of a measurement. A sentence that reads fluently and means nothing. Structure a reader cannot follow. A machine register. Each has a pass that owns it, and running them in the wrong order wastes most of them.

This skill routes. It classifies the document, selects the passes that apply, runs them in order, and reports. It edits nothing itself.

## Three things this skill does not do

**It does not run every pass.** A chain of eight over a short PR description costs more than the description is worth and returns a diff nobody reads. Selection is the work; the run is bookkeeping.

**It does not author.** Every pass here reports a gap rather than filling it — `readability` states the rule directly, and it binds this skill too. A missing lead, an undefined term, a claim with nothing behind it: name it and leave it. Writing the sentence yourself puts your prose in the draft under someone else's name.

**It does not restate any pass's rules.** Invoke each one with the Skill tool. A front door that inlines "and check for nominalizations" now holds a second copy of `deslop`'s catalog, and the two drift the first time either changes.

## Step 1: classify the draft

Three questions. Answer them from the draft and the request, and ask only if the answer changes which passes run.

**What kind of document is it?** The table in Step 2 is keyed on this.

**Who reads it?** A published artifact carrying a byline, or a working artifact carrying none — a plan, a backlog row, a reply to the person you are talking to. Both are in scope. The reader decides strictness, not whether the work happens.

**Does it make claims about the world?** Numbers, outcomes, what a tool does, what a population is like, what happened. If yes, the evidence passes apply and lead. If the draft asserts nothing checkable — a tutorial's worked example, a glossary — they do not, and skipping them is the difference between a two-pass run and a six-pass one.

## Step 2: select the passes

| Document | Passes, in run order |
|---|---|
| Repo doc, README, docs page | `tech-docs-layers`, evidence, `readability` M1, `deslop` plain, `semantic-remediation`, `rendered-page-review` if the repo publishes a site |
| Runbook, procedure, error message | `tech-docs-layers`, `readability` M1, `deslop` **strict**, `semantic-remediation` |
| PR description, issue, review comment | evidence, `readability` M1, `deslop` plain |
| Release notes | evidence, `readability` M1, `deslop` plain |
| Essay, article, blog post | voice, evidence, `readability` M2, `deslop` **voice**, `semantic-remediation` |
| Post, thread, reply (short form) | voice, `readability` M3, `deslop` voice, `semantic-remediation` |
| Source comments, code shape | `code-restraint` alone; add `readability` M4 for doc comments |
| Plan, backlog row, design note | evidence, `readability` M1 |
| A reply to the person you are talking to | `claim-provenance`, `readability` M5 |

"Evidence" means `verify-claims` then `claim-provenance`, and only when Step 1's third question came back yes.

Three rules the table cannot carry:

- **A personal voice skill, if one is loaded, wins every voice conflict** and outranks `deslop` on anything with a byline. Run `deslop` afterwards as a lint and drop any hit that flattens the voice.
- **`code-restraint` owns the file boundary.** Inside a source file it wins over every prose pass except `readability` M4, which covers the prose inside a doc comment and nothing else.
- **A short working artifact usually needs one pass.** Do not assemble a chain because the table has rows.
- **`brevity` is not in the table because it is keyed on size, not document type.** Add it to any row when the draft is longer than the request wanted, or when it is a document read on every invocation rather than once. It and `readability` split a boundary worth stating: `brevity` decides which units survive, `readability` refuses to drop a claim inside one that does.

## Step 3: run them in order

The order is not the conceptual ladder from evidence to render. It comes from what the passes declare, plus one argument where they declare nothing.

1. **`tech-docs-layers`** — what the doc contains and where it lives. `deslop` states the dependency: structure first, then register.
2. **`brevity`** — how much of this should exist at all. It runs here, before the passes that read every word, because each of them is charged per surviving word and cutting a section is cheaper than auditing one. Run it only when the draft is over a length somebody named, or when the document is re-read on every use.
3. **`verify-claims`** — could the evidence have shown the opposite.
4. **`claim-provenance`** — did the delivery earn how it was got.
5. **`readability`** — can a reader who was not there follow it.
6. **`deslop`** — register, vocabulary, sentence mechanics.
7. **`semantic-remediation`** — does each sentence mean what it appears to. It declares that it runs last, after the content is settled and after the other two prose passes; auditing prose still being restructured wastes both passes.
8. **`rendered-page-review`** — what the browser does with the result.

**Evidence leads because content settles before form.** No pass declares this, so it is an argument rather than a citation: `deslop` already works this way internally, fixing content-slop before touching style, on the grounds that a line-edited hollow paragraph is a well-written hollow paragraph. The same holds a level up. Restructuring a paragraph that a provenance audit is about to cut is the identical waste `semantic-remediation` refuses.

**Two dependencies are not orderings, and reading them as such breaks the chain.** `claim-provenance` uses `semantic-remediation`'s exhibit test — the check for whether a span is text the document speaks *with* or *about* — as a component, and that does not pull the whole pass earlier. It also hands off to `verify-claims` inside its most expensive repair, so `verify-claims` runs again mid-chain when a claim is worth going and checking. Neither is a reason to reorder.

**One pass in this list, `verify-claims`, is not a prose pass.** It is about evidence, and it fires on gates, flakes, and root causes as readily as on drafts. Invoke it on the claims a document makes, not on the document.

## Step 4: cost control

Say what you are about to run before running it, whenever the chain exceeds two passes or the draft exceeds a few hundred words. One line: the document type you classified it as, the passes selected, and what you are skipping. That gives the author a chance to cut the chain before it is paid for rather than after.

Stop early when a pass returns nothing and the passes after it depend on what it would have found. An evidence pass that finds every claim already checked does not mean the prose is fine; a `readability` pass that finds nothing to restructure does mean `semantic-remediation` is auditing settled prose, which is exactly when it should run.

## Step 5: report

One block, in this shape:

- **Classified as** — document type, reader, and whether it makes checkable claims.
- **Ran** — each pass, in order, with its finding count.
- **Skipped** — each pass not run, and the one-clause reason.
- **Findings left for the author** — every gap that was reported rather than repaired, quoted. This section is the deliverable when a pass found something only the author can settle: a claim to go and check, a missing lead, an invented term.
- **Changed** — what was actually edited, by pass.

Keep the two apart. A reader who sees repairs and gaps in one list cannot tell what still needs them.

## When the chain finds nothing

Say so plainly and briefly, and do not pad the report to look like work. "Checked, still stands" is a first-class outcome — `claim-provenance` says this about a single claim and it holds for a whole run. An audit that can only report problems will invent them.

## Related skills

- Each pass this skill routes to owns its own rules and wins any conflict about them. This skill owns only selection, order, and the report.
- `verify-claims` is the one member that stands alone. It is invoked constantly outside any writing task, and nothing here changes that.
