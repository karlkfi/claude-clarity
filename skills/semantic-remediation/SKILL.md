---
name: semantic-remediation
description: >-
  Audit prose for sentences that read fluently and fall apart on a literal
  read, then repair them in a separate pass. Use when a draft draws "does this
  actually make sense", "does that make sense", "review it with fresh eyes",
  "that sounds like an oversell", "this sounds smart but I can't tell if it's
  saying anything", or "does it look like a human wrote this" — and when
  writing reads well but the author suspects something is off anyway. Also as
  the last pass on a prose deliverable, after deslop and readability. Repairs
  by default and reports the findings afterwards; a question about a draft gets
  an audit and no edits. Covers telling exhibits from the author's own claims,
  twelve defect categories, severity scoring, and a bottom-up repair walk.
  Neighbors, not replacements: deslop owns vocabulary and AI tells, readability
  owns structure and findability, claim-provenance owns whether the author
  earned the claim, this one owns whether the sentences mean what they appear
  to mean.
---

# Semantic Remediation

Semantic nonsense passes a fluent read and fails a literal one. It uses reasonable-sounding words in ways that don't hold up in context. Bad writing is hard to read. This is easy to read and empty, which is why it survives so many revisions.

It shows up most in confident, aphoristic, heavily edited prose, and in anything an LLM helped write, because what makes prose sound right is not what makes it true.

Two phases, and they never run together: repairing as you go destroys the sentence-level pattern the section pass reads.

## Modes

**Repair unless something says otherwise.** Audit, repair, then report both the findings and the changes. This is the default, and it is what a mid-task pass wants — a PR body, a `SKILL.md`, code comments, release notes, anything handed over to be finished rather than judged. The author reviews the output, not the audit.

**Audit alone when the invocation is a question about the draft** — "does this actually make sense", "review it with fresh eyes", "that sounds like an oversell". A question wants an answer, not a diff. Report the findings and change nothing.

An explicit instruction beats both readings. "audit it", "just tell me what's wrong", `--audit` hold the repairs; "fix it", "clean it up", `--fix` run the full pass on a draft you would otherwise only have audited.

Repairing unattended does not lower the bar for a repair. A finding that can only be fixed by supplying something the draft never says — severity 3, and the two catalog entries that carry no repair — is reported unfixed in either mode, the same as anything else that survives the Phase 2 walk. Nobody watching is the reason to hold that line, not to relax it.

## Phase 1: Audit

Read the whole draft first. Then work bottom-up, in this order, skipping nothing:

1. every sentence
2. every paragraph: does it cohere, or is it just cadence?
3. every section: does it deliver what its heading promises? does anything introduced here do work later?
4. the document: does the title or thesis get argued? are terms promised and never defined?

Order matters. A section-level finding is often an accumulation of sentence-level ones, and you can't tell which it is until the sentences are done.

### Quoted text is not always the author's

Before scoring a sentence, work out whose it is. A **quotation** is a span the text speaks with. An **exhibit** is a span the text speaks about — bad writing on display, or a model to copy. Two properties identify an exhibit, and both must hold:

- **Swappable.** Another specimen of the same class could replace it without changing what the passage claims.
- **Evaluated.** The surrounding text condemns it, corrects it, or holds it up as a model.

Quote marks are not required. In "people write things like the binding constraint moved to trust and nobody blinks," the exhibit carries no punctuation at all.

Four kinds, each read differently:

| Kind | Read as |
|---|---|
| **Quotation** — used, author asserts it | ordinary prose |
| **Disowned exhibit** — displayed as defective | skip at sentence level; check against its label at section level |
| **Diagnosis** — the author's finding about an adjacent exhibit | bound to its exhibit, never alone |
| **Endorsed exhibit** — offered as the model or the fix | harder than ordinary prose |

A diagnosis fails a standalone read by design: "Contact with what?" is a fragment whose referent is the exhibit beside it. Read an exhibit and its diagnosis as one unit, and ask whether the diagnosis names what actually breaks and holds beyond that one specimen. Give an endorsed exhibit the hardest read in the document, because a broken model teaches the break to everyone who copies it.

Two things are out of scope entirely: epigraphs, and quoted voice — verse, dialogue, a deliberately absurd aside. They are mentioned but neither swappable nor evaluated. A pass that reads literally on purpose will otherwise shred fiction and call it a finding.

### What to look for

Sorted by the level each one surfaces at, matching the order of the walk above.

**Sentence**

- **Borrowed idiom, wrong sense.** "A decade to walk back." You walk back a statement; you recover from a bad bet. → "A decade to recover from."
- **Metaphor missing its referent.** "Evaporated on contact." Contact with what? The phrase borrows a surface it never supplies. → "Evaporated on contact with the pan."
- **Axis error.** "The exhaustion runs ahead of the movement." Exhaustion is a state and a movement is a group; only rates can outpace each other. → "The exhaustion outpaces the advancement."
- **Attribute transfer.** "A merge bomb with good intentions." The intentions are the author's, not the merge's. → "A merge bomb from someone with good intentions."
- **Asserted paradox with nothing behind it.** "It's crude, and that's the point." Is it? Say what the crudeness buys, or cut it. → "It's crude, but polishing takes time."
- **Circular definition.** "Idempotent means the operation is idempotent." The definition uses the word it defines and adds nothing. → "Idempotent means running it twice has the same effect as running it once."
- **Impossible as stated.** "You end up standing where you started, on a higher floor." Both are true at once on a spiral staircase, so the contradiction never lands. No repair at this level — it needs to know what you started with.
- **Jargon standing in for a claim.** "The binding constraint moved to trust." Which stage, and measured how? The term imports a model the sentence never fills in. No repair at this level — it needs the stage and the measurement.

**Section**

- **Heading mismatch.** The section title promises a contrast the section makes in one subordinate clause. Usually repaired in the heading rather than the section.

**Document**

- **Term drift.** "Add the item to the queue, then re-rank the rows so the backlog stays ordered." Queue, rows, and backlog are one thing under three names. → "Add the item to the backlog, then groom the backlog." Compressed into one sentence here; in a real draft it spreads across sections.
- **Orphaned concept.** Introduced, defined, then used in no example, test, or conclusion.
- **Title gap.** The headline claim never gets argued. A reader who finishes can't restate what the title asserted.

The two entries with no repair are not oversights. They are found in a sentence and can only be fixed with context the sentence doesn't carry, which is what Phase 2's walk exists to handle.

### Questions the list doesn't cover

- Could this be false? A claim that can't be false isn't a claim.
- Strip the impressive word. What was lost? If nothing, it was decoration.
- Would defending this require explaining what you meant? Then that's the finding.

### Scoring

Score severity, 1 to 5. The category comes from the list above and is recorded alongside it — a finding is "axis error, 4", never one or the other. Severity says how badly the meaning fails; the category says how.

- **5** can't be true as written. Collapses on any literal reading.
- **4** survives a literal reading but asserts nothing that could be false.
- **3** the meaning is recoverable, but only by supplying something the text never says.
- **2** imprecise without misleading.
- **1** slightly loose. Don't report it.

### Output

Report the top scorers, grouped by the level each was found at. One line each on what breaks, not on what to do about it.

> **Sentence, 4 — jargon standing in for a claim.** "The binding constraint moved to trust." Names no stage and no measurement, so nothing here could be false.

Stop when the findings stop earning the reader's attention, not at a fixed count. If they cluster at the section and document levels rather than the sentence level, say that and stop listing: the draft needs restructuring, and auditing sentences that are about to be rewritten wastes both passes.

Then stop. Fix nothing in this phase: the list has to be complete before anything is repaired, and a fix applied here is one Phase 2's walk can no longer sort.

### Rules for auditing

- Don't manufacture findings. If a level is clean, say it's clean.
- Don't soften scores. A 5 reported as a 3 wastes the pass.
- Read literally, on purpose, against your instinct to supply the missing sense. Fluent and meaningful are different properties.
- Flag your own writing hardest. Knowing what you meant is what stops you from seeing that the words don't say it.

## Phase 2: Remediate

Runs on the finished audit — straight away in repair mode, and after the author agrees when the audit ran alone. Either way the input is the whole list, never one finding at a time.

A finding is **found** at the lowest level where it's visible and **repaired** at the lowest level with enough context to repair it. Those are frequently different, in both directions. "Evaporated on contact" is found in a sentence and repaired from the paragraph that says what it hit. Term drift is visible only across the whole draft and is repaired one word at a time.

So walk the levels bottom-up, in the order the audit used. At each level:

1. Repair what this level has the context to repair.
2. Re-audit the repairs made below it. A sentence fix that introduced an undefined term is a finding now.
3. Counterbalance where that's cleaner than reverting — defining the term at document level beats undoing the sentence.
4. Carry the rest forward.

Whatever survives the document pass goes back to the author. That is all "structural" means: not a judgment made up front, but the residue of a walk that ran out of context. An orphaned concept can be cut or given a job, and only the author knows which.

Never repair in file order. A sentence fix can be undone by a section fix, and top-to-bottom applies them in an order that ignores the dependency.

### Rules for fixing

- **Supply exactly what the defect removed, and nothing else.** "Recover from" costs no words. "With the pan" costs two. If a repair costs a clause, you're importing content the draft doesn't have, and the finding belongs one level up.
- **Don't hold the length sentence by sentence.** A repair usually costs words, because the defect was almost always something missing. Check length across the whole pass instead.
- **Rewrite instead of deleting.** Each phrase was trying to say something. Say that thing plainly.
- **Re-audit each rewrite against the whole list, not the category you were repairing.** The defect most likely to survive is the one you weren't looking at, and it's usually an unfilled referent or an invented quantity.
- **Pick one term** per referent and use it throughout.
- **Keep the voice.** Plain, not generic.
- **List every change**, one line each, with the level it was repaired at.

## When to run it

Last, after the content is settled and after the deslop and readability passes. Auditing prose that's still being restructured wastes both passes.

Re-auditing rewrites is built into the Phase 2 walk, so it needs no separate pass. What does deserve a fresh run is a draft that changed substantially after remediation — new sections, a new thesis. That's new prose, not repaired prose.

## Sources

- The use–mention distinction, which is what separates an exhibit from a quotation.
- Gordon Pennycook et al., "On the reception and detection of pseudo-profound bullshit" (*Judgment and Decision Making*, 2015) — an instrument for the property scored here, sentences that sound meaningful without being meaningful.
- Daniel Dennett's "deepity", in *Intuition Pumps and Other Tools for Thinking* (2013): a statement true on a trivial reading and profound only on a false one. The asserted-paradox entry from the other side.
- Harry Frankfurt, *On Bullshit* (2005), for the distinction that makes fluent prose hard to audit: indifference to truth is not the same as lying.
- George Orwell, "Politics and the English Language" (1946), for dying metaphors and the referent test.
