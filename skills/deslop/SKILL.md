---
name: deslop
description: Remove AI slop from prose, or write prose that never contains it. Use when asked to "deslop" a draft, to "use the deslop skill", or to humanize or clean up a draft; when told text "sounds like AI" or "sounds like ChatGPT"; when drafting a Bluesky post or a release announcement; when writing docs, READMEs, articles, release notes, error messages, or runbooks that must read human; or as a final editing pass on any prose deliverable. Covers detection (the tell catalog), generation (the writing system), and editing (the deslop pass). Not for code.
---

# deslop

AI slop is not one bug. It is two: form-slop (the register, rhythm, and vocabulary that mark machine text) and content-slop (claims that sound specific but say nothing, significance nobody measured, attribution to nobody). Fixing the form of a hollow paragraph produces a well-written hollow paragraph. Fix both.

One finding governs this whole skill: in cross-model testing, handing a model a banned-words list cut slop by 3% on Claude. Handing it a complete writing system (ASD-STE100, distilled) cut it by 74%. Do not work from the blacklist. Write inside the system, then use the blacklist only as a final lint.

## Step 1: pick a mode

Match strictness to the document. Never apply a stricter mode than the document type calls for.

**strict** — runbooks, procedures, error messages, safety text, API reference. Full system below, both sentence caps, no exceptions. This is where STE was born (1986 aircraft maintenance manuals, written for non-native readers who must not misread a step) and where it belongs.

**plain** — READMEs, docs pages, PR descriptions, release notes, commit messages, technical reports. The full system minus the vocabulary lockdown: keep the sentence and paragraph discipline, active voice, and verb-first style, but use the word range normal technical writing needs.

**voice** — essays, articles, blog posts, anything with a byline. Remove the tells (Step 4) and the content-slop (Step 3), and touch nothing else. Voice pieces need fragments, contractions, asides, rhythm breaks, and opinions; the strict rules would sand all of that off. If a personal style skill is loaded (for example a user's own writing-style skill), it wins every conflict with this one.

## Step 2: the writing system (generation)

Apply in strict and plain modes. These are positive rules, not prohibitions; text written inside them has nowhere for slop to live.

Words:
- One name for one thing. Never alternate between two names for the same component to avoid repetition. Repetition of the right word is clarity, not a flaw.
- The short common word: use (not utilize or leverage), start (not initiate), help (not facilitate), before (not prior to), about (not regarding), get (not obtain), show (not demonstrate), also (not additionally, furthermore, or moreover).
- A verb for an action: "analyze the log", not "perform an analysis of the log". Watch for nominalizations shaped like "the Xtion of Y".
- No stacked auxiliaries or hedged verb chains. "It may be important to consider enabling X" is nine words hiding one: "Enable X" or "X helps when..." with the actual condition.

Sentences:
- One idea per sentence. In strict mode, cap instructions at 20 words and descriptive sentences at 25. In plain mode, treat those caps as a smell threshold rather than a wall.
- Put the condition before the command: "If the pool is full, decline the job", never "Decline the job if the pool is full" in procedures.
- Active voice whenever the actor is known. "The controller deletes the pod", not "the pod is deleted".

Structure:
- One topic per paragraph, six sentences maximum.
- Steps go in a numbered list, one action per item, imperative form.
- Prose stays prose. Do not convert an argument into bullet fragments; bullets are for parallel items, not for avoiding the work of connecting ideas.

Output hygiene:
- Write only the requested text. No preamble ("Here's the revised version..."), no closing summary, no "I hope this helps", no offer to do more.

## Step 3: content-slop (all modes)

These are the expensive ones, because they survive any amount of line editing.

- **Vague attribution.** "Studies show", "experts agree", "many developers find". Name the study, name the person, or delete the claim. A specific weaker claim beats a vague stronger one.
- **Unearned significance.** "Plays a vital role", "underscores its importance", "is a testament to", "marks a pivotal moment". If the significance is real, state the mechanism or the number that makes it so. If you can't, the claim was decoration.
- **False ranges.** "From small startups to global enterprises", "from simple scripts to complex pipelines". Sounds like a spectrum, specifies nothing. Replace with the actual cases or cut.
- **Fake experience.** "Picture this:", "As a developer, you know the frustration of...". Never manufacture anecdotes or simulate lived experience the author does not have.
- **Tacked-on analysis.** A participial clause bolted to a fact to imply meaning: "...growing 40% last year, highlighting the shift toward cloud-native tooling". The fact earned its sentence; the analysis didn't. Either argue the analysis properly or drop the clause.
- **Rounded-to-vague numbers.** "Significantly faster", "a fraction of the cost", "numerous issues". Use the exact number or say you don't have one. Exact numbers are the single cheapest credibility signal in technical prose.
- **Both-sides filler.** "While X has advantages, it also has drawbacks." True of everything, information about nothing. Commit to a judgment or present the actual trade-off with specifics.

## Step 4: the tell catalog (detection and lint)

Run this as the final pass over any prose, in every mode. Quote each hit, name the pattern, fix it.

Vocabulary (replace on sight, all modes): delve, tapestry, landscape (metaphorical), realm, beacon, journey (metaphorical), symphony, intricate, pivotal, crucial, vital, seamless, robust, leverage, foster, empower, unlock, unleash, elevate, streamline, supercharge, game-changing, cutting-edge, state-of-the-art, best-in-class, battle-tested, enterprise-grade, transformative, revolutionary, comprehensive, multifaceted, myriad, plethora, ever-evolving, fast-paced, synergy, paradigm shift, demystify, holistic, groundbreaking.

Phrases (delete or rewrite): "it's important to note", "it should be noted", "it's worth noting", "in today's digital age", "in the ever-evolving world of", "let's dive in", "at its core", "at the end of the day", "in conclusion", "in summary", "in essence", "ultimately" as a paragraph opener, "no discussion would be complete without", "but here's the kicker", "that's only half the story", "here's the truth", "I hope this helps", "let me know if", "great question".

Structure:
- **Negative parallelism.** "It's not just X, it's Y." / "This isn't about X. It's about Y." One per document is a device; two is a tic; the default is zero.
- **Rule of three.** Triplets of adjectives, clauses, or examples, reflexively, everywhere. Break the symmetry: use two, or four, or one.
- **The balanced paragraph.** Three sentences of nearly equal length, every paragraph, forever. Vary it. Short sentence somewhere. Then a longer one that takes its time getting where it's going.
- **"No X. No Y. Just Z."** and its cousins. Once, maybe. As a habit, it's a fingerprint.
- **Compulsive summarizing.** A closing paragraph or section that restates what was just said. If the reader needs a summary, the section was too long; cut the summary, fix the section.
- **Every section the same shape.** Header, two-sentence intro, bullet list, one-line wrap-up, repeat. Structure should follow the content, and content varies.

Punctuation and formatting:
- Em dash density. One or two per page is punctuation; several per paragraph is a signature. Replace with commas, periods, colons, or parentheses. (STE itself only bans the semicolon; the em-dash rule is the 2020s addendum.)
- Semicolons in technical prose: write two sentences instead.
- Bold overuse, especially the "**Term:** definition" pattern outside an actual glossary.
- Title Case Headings where the house style is sentence case; emoji in headers; horizontal rules between every section.
- Curly quotes and other word-processor artifacts in markdown.

`scripts/deslop-lint.py` checks the machine-checkable part of this catalog. Run it on the draft, per mode:

```bash
skills/deslop/scripts/deslop-lint.py --mode voice draft.md
```

It reports violations per 100 words. Read the delta between two drafts, not the absolute number — the score is a smell meter, not a gate, and it cannot tell a slop word used from one quoted as an example. Everything in Step 3 that needs a reader is invisible to it: a paragraph of unsourced claims can score zero.

## Step 5: the deslop pass (editing an existing draft)

1. Read for content-slop first (Step 3). Mark every claim that names no source, no number, and no mechanism. Fix or cut these before touching style; polishing them wastes the polish.
2. Lint against the tell catalog (Step 4). Quote each hit with the pattern name so the author can see the diagnosis, not just the rewrite.
3. Rewrite at the sentence level in place. Preserve meaning, preserve the author's ordering and argument. Do not restructure the document unless asked.
4. Delete before you rephrase. Most slop sentences are not bad sentences; they are unnecessary ones. The 41%-shorter version that says the same thing is the better version.
5. Re-read the result for rhythm. If every sentence now has the same length and shape, you traded one fingerprint for another; break the pattern deliberately.
6. Report the delta briefly: what patterns appeared, how often, what was cut. Not a lecture, a ledger.

## Anti-overcorrection (all modes)

- Do not inject fake informality: no manufactured typos, no forced slang, no "real talk". Over-corrected text is its own tell.
- Do not flatten a real voice. If the author uses fragments, contractions, profanity, or long parenthetical asides, those stay. The target is their prose minus the machine residue, not STE.
- Do not delete hedges that carry real uncertainty. "Probably" backed by incomplete data is honesty; "it's worth noting" backed by nothing is filler. Calibration stays, decoration goes.
- Do not let the word list make text worse. If the accurate word is on the blacklist (a report genuinely about a "landscape review"), keep it. The list flags defaults, it doesn't ban words.

## Related skills

- `code-restraint` is the code-side counterpart, and it answers to some of the same requests ("deslop this", "remove the AI slop"). Route by artifact: source files, tests, and build scripts go there; prose goes here. A PR description in a code review is prose.
- A personal voice skill, if one is loaded, outranks this skill in voice mode, and in any mode when the deliverable carries a byline. Use this one afterward as a lint, and drop any hit that conflicts with that documented style.
- `tech-docs-layers` decides what a docs page should contain and where it sits; this skill decides how its sentences read. Structure first, then deslop.

## Sources

Distilled from ASD-STE100 (asd-ste100.org — Issue 9 is free but copyrighted; do not reproduce the spec), Wikipedia's "Signs of AI writing" catalog, and the woosal1337 "cure for AI slop" kit (github.com/woosal1337/blog, ep01), whose cross-model experiment supplied the system-beats-blacklist finding and whose MIT-licensed `ste-lint.py` is the ancestor of the bundled `scripts/deslop-lint.py`.
