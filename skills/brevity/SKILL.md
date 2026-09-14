---
name: brevity
description: >-
  Decide how much to write and what to remove — cutting whole units rather than
  compressing sentences, and stopping at the floor where the reader has to
  reconstruct what you deleted. Use when a draft draws "too long, shorten it",
  "feels verbose and defensive", "still extra verbose", "way too much prose on
  this page", "too long to read", "this paragraph is dense, give me clear line
  items" or "eating up the context window". Also before shipping a document
  that is re-read on every use — a skill body, a CLAUDE.md, a prompt, a system
  message — and when an edit would add to a document already at its length.
  Covers the three quantities "too long" can mean, the ratchet that grows prose
  one justified addition at a time, what to cut in order of size, moving detail
  instead of deleting it, and five floor tests for a cut that went too far.
  Neighbours: deslop owns the words inside a sentence, readability owns order
  and refuses to drop a claim, this one owns how much gets written.
---

# Brevity: cut units, not information

Shortening a draft by compressing its sentences keeps every idea and hands the reader the bill. That is the failure this skill exists to prevent, and it is why "make it shorter" and "make it denser" are opposite instructions.

The move that works is to remove whole units the reader does not need, at full sentence length, and to leave what remains as loose as it was. Deleting extraneous material is the best-evidenced intervention in this whole area — Mayer's coherence principle held in 23 of 23 experiments with a median effect size of 0.86. Packing more ideas into the same words is the opposite trade: holding word count constant and raising the number of propositions produces longer reading times and lower recall (Harrag et al. 2025).

**Effectiveness outranks brevity**, and that ordering is not a tie-break to reach for when the two are close. A document that came out shorter and no longer does its job has failed at the only thing it was for, so a cut that costs the reader the decision, the step, or the caveat is a loss however much length it bought. The floor tests below are how the ordering gets enforced rather than merely asserted.

The exception is worth knowing because it is where shortening earns real effort instead of a tidy-up: a document read many times rather than once **pays twice**. The attention goes on every read, and for anything a model loads — a skill body, a `CLAUDE.md`, a prompt, a tool description — so do the tokens. Two currencies, both charged per reading.

## Three quantities hide behind "too long"

Find out which one before cutting.

- **Length** — how many words. Costs the reader time and attention.
- **Density** — ideas per word. Costs the reader working memory.
- **Load** — what the reader must supply themselves to follow it. Costs them the ability to follow it at all.

Cutting length by raising density moves the cost sideways and usually up. A draft that drew "too long" and a draft that drew "my eyes glide right over it" need opposite edits: the first needs units removed, the second needs the surviving units *unpacked*. When a reader says a passage is dense and asks for line items, they are asking you to spend more words on fewer ideas.

The floor is a property of the reader, not of the text. Explanation that a novice needs is dead weight to an expert (Kalyuga's expertise reversal effect), and the bridging sentence between two facts helps a low-knowledge reader and can measurably hinder a high-knowledge one (McNamara and Kintsch's reverse cohesion effect, refined by O'Reilly and McNamara 2007 — the benefit of the gappier text holds for high-knowledge readers who are *less* skilled comprehenders). So name the reader first. Everything below is scored against that one person.

## Why the draft got long: the ratchet

Nobody writes a bloated document. They write a short one and then make sixty defensible additions to it. Each addition answers a real question, cites a real case, closes a real gap — and no single edit is the one that should have removed something instead.

The exhibit is a procedure skill I maintain. It went from 7,604 words to 28,602 in fifteen days, across 61 edits — 57 grew it, 4 shrank it. Every one of those edits was reviewed. The aggregate was not, because no reviewer sees an aggregate.

Two consequences:

- **An addition to a document at its length has to name what it displaces.** Not "is this worth adding" — everything is worth adding — but "is this worth more than the paragraph it pushes out". If nothing loses, the document had no length and will not have one next week either.
- **Price a re-read document by size times readings.** A paragraph in a document read once costs a paragraph. The same paragraph in one resident for a hundred turns costs a hundred. Ordinary prose gets a length; these get a budget, and the budget is spent rather than filled.

## Cut in order of size

Work top-down and stop when the draft fits. Every step below the one that fixes it is wasted effort, and the bottom two steps almost never fix anything on their own.

1. **The document.** Does it need to exist, or does it duplicate one that does? The largest available cut is always the whole thing.
2. **Sections answering a question nobody asked.** For each section, write the question it answers. If the named reader would not have asked it, cut the section — not its adjectives.
3. **Provenance and process.** How you found out, what you tried first, what the project used to believe. The reader applying a conclusion needs the conclusion and its mechanism. The audit trail belongs where an auditor will look for it.
4. **Restatement.** The intro announcing what follows, the summary restating what preceded, the second sentence saying the first one again in other words. If the reader needed the summary, the section was too long — fix the section.
5. **The redundant exhibit.** Two examples teaching the same thing: keep the one that would survive being the only one. Two teaching different things are both load-bearing.
6. **Qualifiers that qualify nothing.** A hedge that narrows *when the rule applies* is a fact. A hedge that narrows nothing is decoration.
7. **Words.** Meaningless words, doubled words, what the reader can infer, phrases replaceable by a word, negatives statable as affirmatives — Williams's list. This is `deslop`'s pass, and it is last because it is worth about a tenth of step 2.

**Across many documents, run the ladder breadth-first, not depth-first.** The order above is written for one draft, and applied to a corpus it is ambiguous: "largest first" can mean the largest document or the largest cuttable class, and those give opposite plans. Take one step across every document before descending to the next in any of them. A defect class is usually repo-wide — the same habit produced it everywhere — so step 3 over twenty files finds more than steps 3 through 7 over the biggest one.

Picking the largest document instead is the trap, because it is also the one with the strongest case for attention. Measured 2026-09-03 over a 24-skill collection: a pass opened the file holding 48% of all context cost, worked down to sentence-level trimming inside it for several rounds, and recovered 1.8 KB. One step-3 sweep across all 24 then found two small files spending a quarter to a third of their body on provenance, and moving it recovered 7 KB in two edits. The cost measurement was correct and answered a different question than the one being asked: where the bytes are is not where the defects are.

## Move it, don't delete it

Cutting and deleting are different operations, and the good version of "too long" is usually relocation. Detail that a minority of readers need goes where they can reach it: a linked doc, a collapsed block, an appendix, a footnote, the reference page. The main path gets shorter and nothing is lost.

Three cuts are almost always moves. Long-form background behind a warning or a release note ("detail for the docs that the release can link to"). Provenance leaving a rule (step 3 above — it goes into a companion doc, a commit message, or a PR body). And the second worked example, which becomes a link.

Say where it went. A cut that silently vanishes a fact and a cut that relocates it look identical in the diff and are opposite acts.

## Five floor tests

Run these over the *result*, against the named reader. A failure means the cut went past the floor — restore the unit, then find the length somewhere else.

1. **Reconstruct.** Can the reader restate the cut fact from what is left? If they would have to guess, it was not redundant — it was the bridge.
2. **Antecedent.** Does every "it", "this", "that", "the above" still have a referent on the page? Deletion orphans pronouns, and the orphan reads fine to the author who remembers the missing sentence.
3. **Given–new.** Does each sentence still open on something the reader already has? Cutting the given half leaves a sentence that is short, grammatical, and unparseable in place.
4. **Condition.** Did any qualifier that changes *when* a claim holds get cut as padding? "Fails only on clusters upgraded in place from 1.28" is not a longer way to say "fails sometimes".
5. **One exhibit.** Does every rule that survived keep at least one concrete case? A rule stripped to its abstraction reads as advice and gets ignored — which is a compression that saved words by deleting the reason anyone would comply.

## The pass

1. Name the reader and the one thing the document has to let them do.
2. Decide which quantity is wrong — length, density, or load. If it is density, stop and hand it to `readability` — detail in layers and one idea per paragraph are its rules, and unpacking is its work, not this skill's.
3. Mark each unit with the question it answers. Cut the unasked ones, largest first, per the order above.
4. Run the five floor tests. Restore anything they catch.
5. Hand the survivors to `deslop` for the sentence level.
6. Report the delta as a ledger: what was cut, what moved and where, and the before/after size. Not a summary of the document — that is the restatement defect arriving in the report.

## What never counts as length

Exact numbers, proper names, units, versions, and stated conditions. These are the densest words in any technical document and the cheapest to keep — trading "p99 rose 80ms" for "latency regressed" buys four words and spends the only fact in the sentence. When a draft is over length and only the numbers are left, the draft is not too long. It is a different document than the one that was needed.

## Where this sits

`readability` structures a draft and holds every claim in it — its rule is that nothing leaves. This skill is the one allowed to remove content, and only by the tests above: it drops *units the named reader does not need*, and never precision inside a unit that stays. Where both apply, brevity decides whether a unit survives and readability decides how it reads.

**The two share triggers on purpose, and each routes to the other.** "Too long" and "too dense" arrive in the same breath and name opposite repairs, so whichever skill fires first hands over when the complaint turns out to belong to its neighbour: a draft that is dense goes to `readability` to be unpacked, and one that is merely long stays here. Narrowing either description to end the overlap is the wrong repair — a mis-fire costs one hop, and a missing trigger costs the whole skill.

`deslop` owns words inside a surviving sentence and runs after this. `tech-docs-layers` decides where a moved section lands. `code-restraint` owns the same problem in source, where comment density is the axis.

## Sources

The ratchet exhibit was measured 2026-08-31 over 61 commits in the preceding fifteen days. It is not public, so those figures are reported rather than checkable.

Grice's maxim of quantity supplies the frame — as informative as required, and no more. The empirical claims come from Mayer's coherence principle (Cambridge Handbook of Multimedia Learning, "Principles for Reducing Extraneous Processing"), Harrag, Sabil, Radvansky and Conceição, "Too Dense to Comprehend — Or Perfectly Packed?" (Discourse Processes 62:5, 2025), Kalyuga's expertise reversal effect, and McNamara and Kintsch's reverse cohesion effect with O'Reilly and McNamara's 2007 refinement. The step-7 deletions are Joseph Williams's, from *Style: Lessons in Clarity and Grace*. Those five were read as abstracts and secondary summaries rather than full texts; treat the directions as sound and any figure quoted here as worth re-reading at the source before it decides anything.
