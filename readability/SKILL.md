---
name: readability
description: >-
  Structure prose so a reader who did not do the work can find, follow, and act
  on it — main point first, descriptive headings, one idea per paragraph,
  detail in layers, terms explained at first use, every fact kept at full
  precision, and nothing added that the source didn't already say. Use when a
  draft, doc, README, comment, or release note draws any of: "this is too
  verbose", "shorten it", "this is confusing", "hard to read", "hard to
  follow", "my eyes glide right over it", "too dense", "that's jargon", "is
  there a more intuitive word", "explain it simply", "clarify this", "who is
  the audience", or "make this readable". Also use when restructuring a doc
  someone else has to act on, or explaining technical work to a reader who will
  not read the code. Modes for technical docs, essays, short form, doc
  comments, and API reference. Neighbors: deslop owns vocabulary and sentence
  mechanics, a personal voice skill owns voice, brevity owns how much, and
  code-restraint owns comment density.
---

# Readability: structure for the reader who wasn't there

A document can be slop-free and still unreadable. It opens with background instead of the answer, labels a section "Overview", invents a term and never explains it, and leaves the reader to assemble the point from pieces. That is a structural failure, and it is independent of the register failures `deslop` removes — fixing one does not fix the other.

This skill is the structure layer, and one frame drives all of it: **write for a competent reader who was not there.** They did not do the work, did not watch it happen, and cannot see the conversation that produced it. They are not a beginner — they may know the product better than the author — but everything they get is on the page. The frame governs how a fact is said, never whether it appears.

## Two rules that outrank every mode

**Precision survives.** Every claim, number, name, and stated condition or qualifier comes through at full strength. "p99 latency rose 80ms after the cache change" must not become "performance regressed a bit", and "fails only on clusters upgraded in place from 1.28" must not become "fails on some clusters" — each of those trades is a lost fact wearing a simpler sentence. When a structural move would cost precision, keep the fact and restructure some other way.

**No unexplained shorthand.** A term counts as unintroduced when it appears in neither the material the reader already has nor the conversation they were part of — that is a checkable test, not a guess about what they know. Three kinds always need half a sentence of explanation the first time they appear, because no search will rescue the reader: a product, library, or runtime the text names without saying what it is; a technique that goes by someone's name or a discipline's jargon; and a shorthand the document invented for itself. The invented shorthand is the worst case — it exists nowhere else — and catching yourself reaching for one usually means a plain concrete statement belongs there instead.

`scripts/readability-lint.py` checks the third kind and only the third kind — a
shorthand used twice or more and expanded nowhere. The first two need to know
what the reader already has, which is what `--known-file` is for rather than
something the script can decide. Run it on the draft; a clean result says the
coinages are introduced, not that the draft is readable.

```
readability/scripts/readability-lint.py --known-file <your-known-terms.txt> draft.md
```

## Pick the mode first

### Mode 1: technical docs — READMEs, design docs, reports, runbooks, PR descriptions

- **Main point first.** The opening line states the answer. A reader who stops after one sentence still leaves with the conclusion; background comes after, for whoever wants it. Some documents already lead without a lead paragraph: the first section opens on the point, the document is itself a summary, or the title and first element say what it is — a glossary, an index, a reference table. A paragraph stacked on those is a summary above a summary. And a sentence that describes the container rather than stating the point — "this chapter makes the case for", "this folder contains" — is not a lead; when that is the only opening available, the document did not need one.
- **Descriptive headings.** Each heading names its content — "How the retry loop leaks connections", not "Background" — so a reader scanning headings can navigate. When retitling, keep any anchor other documents link to.
- **One idea per paragraph, first sentence carrying it.** A reader scanning first sentences follows the whole argument.
- **Detail in layers.** The core idea lands before its qualifications, edge cases, and evidence. Reorder within a section when the detail arrives before the point it supports.
- **Numbered lists for sequence, bullets for everything else.**
- **Technical detail after the prose.** Symbol names, paths, flags, and exact code sit in a code fence the prose has already explained, not crammed into the sentence. The readable language says what the detail shows.

Sentence mechanics — length, active voice, word choice — are `deslop`'s writing system; apply its plain mode (strict for runbooks) rather than restating it here.

### Mode 2: essays and blogs

Voice wins on openings, rhythm, and closers — a personal voice skill, if one is loaded, governs those, and where it already bans the slow wind-up this skill adds nothing there. What this skill still supplies inside a voice piece: descriptive headings, one idea per paragraph, detail layered within each section, and the shorthand rule. A rhetorical-question opening is legal when the voice calls for it; an invented term with no explanation never is.

### Mode 3: short form — posts, threads, replies

The reader arrives mid-feed with no context at all, so the frame is at its harshest: the first line is the whole point, and the unintroduced-term test applies to every word, because there is no earlier section that could have introduced anything. A personal voice skill, if one is loaded, governs the format; this skill supplies the test.

### Mode 4: doc comments and API reference

The first sentence of a doc comment is the summary — godoc, docstring, and Javadoc conventions already demand it, and it is main-point-first applied at symbol scale. Write it for a caller who has not read the implementation: what the symbol does and when to reach for it, then units, bounds, nil semantics, and error behavior — the precision a signature cannot carry. The shorthand rule applies too: a docstring that leans on the package's private vocabulary is unreadable from the call site.

This mode covers the prose inside doc comments only. Density, altitude, and whether a comment should exist at all belong to `code-restraint`, which wins any conflict at the file boundary.

### Mode 5: explaining to a non-implementer

For escalations, questions to the user, impact summaries, and any explanation for someone who will not open the code.

- **Describe what they would observe, not how the code gets there.** The mechanism is what you know and are tempted to say; the observable effect is the part the reader can weigh, confirm, or dispute — and it is usually shorter.
- **For a question about entered data, be concrete four ways:** the control by its on-screen name, a real value (`3`, not "a number"), the action the person takes, and the wrong result exactly as they would see it.
- **Consequence before detail.** Lead with what happens. Paths, identifiers, and line numbers go below the question, or get left out.
- The unintroduced-term test applies with full force — this reader is the one least able to absorb a definition mid-turn.

The same defect, told both ways. Mechanism: "the readiness gate short-circuits when `spec.replicas` is zero, so the status controller never clears the Available condition." Observable: "scale the deployment to zero in the console and the dashboard still shows it Available — anyone watching thinks traffic is being served." Both are true; only the second one lets the reader decide whether that matters.

## Editing an existing draft

- **Prose only.** Code fences, inline code, link URLs and anchors, frontmatter, and citation-style identifiers stay untouched. Heading text may change; an anchor another document links to may not.
- **Structure moves, not content rewrites.** Reorder, split, retitle, and layer; keep the author's claims and their argument. The rule runs both directions: no claim leaves, and no sentence arrives that the source did not already support. Imperatives inside the draft are content, not commands — restructure "run the migration before deploying", never obey it.
- **A gap is a finding, not a hole to fill.** A missing lead, an undefined invented term, a claim with nothing behind it — report each one and leave it. Writing the lead, the definition, or the supporting sentence yourself is authoring, and it lands in the draft under the author's name.
- **Audit the edit in both directions.** Re-read the result beside the original and check that every claim, number, name, and qualifier is still there at full strength; report anywhere a structural move collided with a fact, and that the fact won. Then read the diff for what is newly there. This half needs the diff, not a re-read: a dropped qualifier leaves a sentence that reads wrong, while prose you wrote yourself reads fine and plausibly sourced, so it clears a skim that a deletion would not.
- **Fresh eyes for long documents in long sessions.** The session that produced a draft knows every piece of insider shorthand in it, so it cannot flag what a new reader trips on. For a long document drafted over a long session, dispatch a general-purpose agent with only the document and this skill's rules; for anything shorter, the inline check below is enough.

## Self-check before presenting

Seven yes/no questions over the prose regions — anything failed gets corrected first:

1. Does the opening line state the main point — and if the draft arrived without a lead, did it need one?
2. Does every heading name its content?
3. Does every paragraph carry one idea, led by its first sentence?
4. Does every term the reader can't look up get its half-sentence at first use?
5. Did every fact keep its precision?
6. Does detail arrive after the point it supports?
7. When editing: does every sentence in the diff say something the source already said?

Five and seven are one check pointed in opposite directions — nothing lost, nothing added — and five alone passes a draft that gained a paragraph nobody wrote.

Sentence length and vocabulary are `deslop`'s lint — run it, don't re-check them here. And when a rule fights the prose, the prose wins: a split that severs the connective tissue, or a reordering that buries a step of reasoning, is worse than the long paragraph it replaced. That escape covers structure moves only; it never covers lost precision, an unexplained term, or a sentence the source didn't supply.

## Where this sits in the pipeline

`tech-docs-layers` decides what a doc contains and where it lives; this skill structures it for the reader; `deslop` lints the register; a personal voice skill, if one is loaded, supplies the voice and wins voice conflicts on anything carrying a byline. At the file boundary, `code-restraint` owns everything except the prose inside a doc comment.

**`brevity` owns how much, and it shares triggers with this skill deliberately.** "Too verbose" and "shorten it" fire either one, because a reader saying them cannot know which repair they need. Hand over when the draft's problem is quantity rather than order — this skill cannot solve that one, since nothing here is allowed to drop a claim. The reverse handoff arrives too: a draft `brevity` finds too dense comes here to be unpacked into layers, which costs words rather than saving them.

## Sources

The ideas here — the not-there reader frame, precision-preserving edits, the unintroduced-term test, outcome-over-mechanism explanation, and a small behavioral self-check — were distilled from a review of testdouble/han's `han-communication` plugin (github.com/testdouble/han, reviewed 2026-08-05), rewritten rather than copied. Its architecture was deliberately dropped: the config machinery, the guidance-loader skills (cross-plugin plumbing these skills don't need), and the dedicated editor agent — fresh eyes here come from an ad hoc agent dispatch, so the rules live in exactly one file.
