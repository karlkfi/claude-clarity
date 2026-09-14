# Decisions behind semantic-remediation

Why [`semantic-remediation`](../../skills/semantic-remediation/SKILL.md) is shaped the
way it is.

This file carries the reasoning a maintainer needs in order to decide whether to
*change* a rule; the skill carries what a reader needs in order to *apply* one.
The repo's `CLAUDE.md` is the authority on that split.

**Every entry names what would reverse it.** An entry recording only what was
chosen leaves the next maintainer re-deriving the argument from scratch, and a
decision nobody can retire is indistinguishable from a rule.

Most of these came out of running the skill on its own text before it landed.
That is worth stating because it sets how much they are worth: they are findings
from one document, audited once, not a measurement over a corpus.

---

## The audit and the repair never run in one pass

The audit runs bottom-up — sentences, paragraphs, sections, document — because a
section-level finding is usually an accumulation of sentence-level ones, and you
cannot tell which it is until the sentences are done.

Repairing as you go destroys that evidence. Fix the sentences one at a time and
the pattern they formed is gone before the section pass can see it. The sort
also needs the finished list, since it groups findings by the level that can
repair them.

The author agreeing before any prose changes is a third reason, and the weakest
one on its own.

**Reverses if** the audit stops being cumulative — if section and document
findings turn out to be independent of the sentence pass rather than built from
it, the two phases can merge and the skill gets much shorter.

## A finding is repaired at a different level than it surfaces at

A finding surfaces at the lowest level where it is visible, and is repaired at
the lowest level carrying enough context to repair it. Those differ in both
directions. "Evaporated on contact" is visible in one sentence and cannot be
fixed there, because nothing in the sentence says what was contacted; the
paragraph does. Term drift is invisible in any single sentence, since each is
fine alone, and is repaired one word at a time.

So Phase 2 walks up the levels, repairing what each level has context for and
re-auditing the repairs below it. "Structural" is defined as whatever survives
the document pass — the residue of a walk that ran out of context.

An earlier draft sorted findings into mechanical and structural up front and
applied the mechanical ones in file order. File order applies a sentence fix
that a later section fix silently undoes, and the up-front sort has to guess at
exactly what the walk determines.

**Reverses if** the two levels turn out to coincide in practice. If real drafts
almost always repair at the level that found the finding, the walk is
machinery for a rare case and a flat pass is cheaper.

## Exhibits are identified by inference, not by markup

A skill that teaches by quoting bad sentences is full of sentences that fail a
literal read on purpose, and so is any style guide. A naive sentence pass flags
every specimen, plus every diagnosis attached to one — "Contact with what?" is a
fragment whose referent is the exhibit beside it.

Identification therefore uses two properties and no convention: a span is an
exhibit when another specimen of its class could replace it without changing
what the passage claims, and the surrounding text takes a position on it. Markup
was rejected because the skill has to audit `deslop`'s catalog and outside
drafts, which will never carry a marker, so the inference rule is needed anyway
and the markup would only ever be a second mechanism.

**Reverses if** a linter is wanted. Nothing here is mechanically checkable
today, but catalog *shape* is — every entry has a diagnosis, no unlabelled
specimen — and a script needs markers to find them. That would mean marking
exhibits across `deslop`, `code-restraint` and `verify-claims` too.

## Severity is scored apart from category

The original scale ran 1 to 5 but mixed the two: levels 4 and 3 named specific
defects while 5 and 2 named severity, so two findings of different kinds could
not be ranked against each other. Severity now says how badly the meaning fails
and the category says how, recorded together as "axis error, 4".

**Reverses if** the category turns out to predict severity closely enough that
one number carries both, which would make the pair redundant bookkeeping.

## A repair has no word budget

The draft capped net change at about 50 words and told the auditor that fixes
"should shrink or hold". That rule was generating defects: three of nine trial
repairs picked up a fresh unfilled referent or an invented number, and every one
came from reaching for a tighter phrase when the plain one was available. The
one repair that ignored the pressure was the longest and the only clean one.

The replacement is to supply exactly what the defect removed and nothing else,
which also dissolves the apparent conflict with "add nothing new" — a repair
that costs a clause is importing content, and that finding belongs one level up.

**Reverses if** the opposite failure shows up at volume. If repairs start
bloating drafts rather than filling gaps, a budget checked across the whole pass
(never per sentence) comes back.

## Findings stop by clustering, not by count

"Report ten or so, past fifteen the draft needs rewriting" was two invented
numbers with an unexplained band between them, and it fired wrongly on the
skill's own text: eighteen findings across four levels, needing six targeted
fixes rather than a rewrite. A count also scales with document length and rule
density rather than with how broken the prose is.

What the number was reaching for is the level the findings sit at. Clustered at
the section and document levels, the draft needs restructuring; spread across
all four, it needs fixes.

**Reverses if** the clustering signal proves unreadable in practice and a count,
however arbitrary, turns out to be the more useful stopping rule.

## Two catalog entries carry no repair

"Impossible as stated" and "jargon standing in for a claim" show an exhibit and
a diagnosis and no rewrite, because both need context a sentence does not have.
That is the found-at/repaired-at split made visible in the catalog itself, and
it is the signal Phase 2's sort reads.

The cost is that it looks like an unfinished list. The skill says so explicitly
underneath the entries.

**Reverses if** a reader keeps filing it as a gap despite the note, at which
point the entries need a fuller worked example rather than a disclaimer.

## Repair is the default, and a question is what holds it

The skill originally gated Phase 2 on the author reviewing the audit and
agreeing with it. That gate made every invocation interactive, including the
ones nobody wanted to sit through — a pass over a PR body, a `SKILL.md`, code
comments, release notes, where the audit is a list of defects in generated text
and reading it before the fix buys nothing the fixed draft would not show.

The gate was never load-bearing. *The audit and the repair never run in one
pass* records that the author agreeing "is a third reason, and the weakest one
on its own"; the two that carry the split — repairing as you go destroys the
pattern the section pass reads, and the sort needs the finished list — are
properties of the walk and hold with nobody watching. So the phases stayed and
the gate became a mode.

The default is to repair, because the interactive case is the narrower one.
What selects the other mode is the shape of the invocation rather than the kind
of document: a turn phrased as a question about a draft ("does this actually
make sense", "review it with fresh eyes") wants an answer, and answering it with
a diff is the wrong reply whatever the default. Routing on document type — blog
interactive, generated output non-interactive — was rejected because that
classification is a judgement made per run, which is not a default.

Unattended repair raises one risk the gate used to absorb: a finding repairable
only by supplying content the draft never carries. The skill already refuses
those — severity 3, the two catalog entries with no repair, and *A repair has no
word budget*'s rule that a repair costing a clause belongs one level up — so the
mode note restates the line rather than adding a mechanism.

**Reverses if** unattended repairs start inventing content at volume. The
existing refusals are stated in prose and checked by nothing, so if repair-mode
output shows fabricated referents or quantities, the gate comes back for
findings above some severity rather than for the whole pass.
