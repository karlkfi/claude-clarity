---
name: code-restraint
description: Keep authored source from reading as machine-written, with comments cut to what a later reader of the file needs and code shaped like the host file. Use when the user asks for "code restraint" or "code-restraint" on a diff, and when a review says "this reads as AI generated", "the comments are too long", "the dense narrative style", "too many comments", "need to be in the code comment or better for the PR?", "too defensive", "why all the try/catch", "match the existing style", "why didn't you use the existing helper", "remove the dead code", or flags duplicated blocks, over-long functions, or leftover scaffolding. Also use before committing a code diff, and when comments in a PR look like they belong in docs instead. Covers comments (the later-reader test, where history, rationale and ticket numbers go instead, length) and code shape (reuse existing helpers, match median function length and naming register, extract near-identical blocks, no speculative structure). Not for prose — deslop owns slop in text.
---

# Code restraint: source that reads like the file it landed in

The tell that code was machine-written is rarely one bad sentence.
It is proportion.
A block with 10x the comment density of its neighbours reads as generated before anyone parses a word of it, and three near-identical 50-line functions read as generated even with no comments at all.
Both come from the same root cause: writing self-contained blocks instead of going to look at the local idiom first.

The two halves use the host file differently.
Code shape is matched to it.
Comments are held to a test the host file may itself fail, so its comment density is a ceiling on the diff and never a target.

This skill is two halves.
The code-shape half matters more — no amount of comment discipline saves a 60-line spec that should have been 8.

## How to use this skill

Measure the host file before writing (step 1).
Apply the shape rules, then the comment rules, while writing (steps 2 and 3).
Re-measure the diff before handing it over (step 4).

Step 1 is the one that gets skipped and the one that does the work.

### Step 1 — Measure the host file first

Three numbers, all from the file being edited.
Take them before writing a line.

**1.
Comment density.** Comment lines over non-comment, non-blank lines.
The exact definition matters less than using the same one on both sides of the comparison.

```bash
awk '
  /^[[:space:]]*$/ { next }
  /^[[:space:]]*(\/\/|\/\*|\*)/ { c++; next }
  { t++ }
  END { printf "%d comment / %d code = %.2f\n", c, t, c/t }' path/to/file.go
```

For `#`-comment languages (Python, Ruby, shell) swap the pattern for `/^[[:space:]]*#/`; for SQL and Lua, `/^[[:space:]]*--/`.

**2.
Median size of the construct you are adding.** Compare like with like: top-level functions against top-level functions, test cases against test cases, table entries against table entries.
Span between successive declarations is a good enough proxy.

```bash
~/.claude/skills/code-restraint/scripts/construct-median.sh '^func ' path/to/file.go
```

Change the anchor for the construct in question: `'ginkgo\.It\('`, `'t\.Run\('`, `'^[[:space:]]*(it|test)\('`, `'^[[:space:]]*def '`.

**3.
Helpers that already exist.** Grep the file for the nouns in the thing you are about to build, then the package, then the shared test-helper package.

```bash
rg -n '^func ' path/to/file.go
rg -n 'func .*(Handler|Probe|Spec|Client)' path/to/
```

Do this even when the thing to build is small.
Rebuilding a helper that sits 200 lines up the same file is the most visible version of this failure.

**The density number is a ceiling, not a target.** A diff denser than its file is the tell, so the file's number caps what the diff may add.
It licenses nothing: a comment that fails the test in step 3 goes even when the file would absorb it unnoticed.

**A file whose own comments fail that test is not a baseline at any density.** Read a handful before trusting the number.
Paragraphs above ordinary statements, narration of past diffs, ticket numbers for finished work, and arguments for the design are what earlier sessions leave behind, and a file can carry all of them at half the density of one that looks obviously bloated.
Matching it reproduces them.
The same holds when the user says the existing style is too verbose.
Write to step 3 regardless of the neighbours and let the diff run leaner than its surroundings.

### Step 2 — Code shape

- **Search before you build.** If a helper for this already exists in the file, the package, or the project's test-helper package, use it.
  If it exists but does not quite fit, extend it or say in the PR description why a second one is warranted — do not silently fork it.
- **Match the median.** A new function 3x the file's median for that construct means a helper is missing.
  Pull the setup out, leave the intent in the body.
- **Two near-identical blocks means extract, not copy.** By the third the extraction is not optional.
  Three 50-line blocks that differ in two literals are one helper and three short call sites.
- **Match the file's existing decomposition, not a better one you have in mind.** If every test in the file builds its pod spec through a constructor, yours does too.
  Restructuring the file is a separate change.
- **Match the file's defensiveness.** Validate where the file validates — usually the boundary where untrusted input enters.
  A try/catch, nil check, or fallback default that the function's siblings don't have reads as hedging against invariants you didn't check, and the fallback hides the failure it wraps.
  If the input is guaranteed upstream, trust the guarantee and let real failures stay loud.
- **No structure for a use case that has not arrived.** One implementation means no interface; one product means no factory; one caller means no option parameter.
  Add the seam when the second consumer shows up — it will tell you where the seam goes.
- **Ship only what the change needs.** No unused imports, parameters, or exports left from an earlier draft; no commented-out code (git is the archive); no `as any` or `# type: ignore` to route around a type error instead of fixing the type.
- **Match the file's naming register.** If the file says `checkAuth` and `mkPod`, a new `handleUserAuthenticationValidation` is a tell.
  Identifier length and vocabulary are local idiom like everything else.

### Step 3 — Comments

**The test.** The reader is someone changing this file later with the code open and nothing else: no PR, no tracker, no memory of this session.
Keep a sentence only if that reader needs it to read the code correctly or to change it safely.
Apply it to each sentence, not to the comment as a whole, because one useful clause is what carries three useless ones past review.

A sentence passes when it gives:

- a reason the code cannot state: the constraint it satisfies, the failure it avoids
- precision the code cannot carry: units, whether a bound is inclusive, what nil or empty means here, which lock is held
- a trap: code that looks wrong or simplifiable and is not, with what breaks
- the contract, in a doc comment: what a caller may rely on and must supply

A sentence that paraphrases the line under it sits at the code's own altitude and is the first thing to rot when that line changes.
Delete it, or rename the thing so the name carries it.

**Move what fails; do not just delete it.** Most failing sentences are true and wanted by a different reader, who looks somewhere else.
Put each one there in the same change, so trimming the comment loses nothing.

| In the draft comment | Its reader looks in |
|---|---|
| what the code used to do: "now", "no longer", "previously" | the commit message |
| why this approach beat another; "deliberately" | the PR description, or a design doc if it outlives the PR |
| the incident, flake or review that prompted the code | the commit message and PR description |
| measurements, dates, run counts | the PR description, or a doc when a later decision rests on them |
| which ticket or PR delivered the code | the commit message, where `git blame` leads |
| an argument against whoever might revert it | the review thread |
| how the subsystem fits together | a design doc, with a one-line pointer left in the comment |
| what a user or operator sees, sets or does | the user-facing docs |

Code reads as if it had always been this way.
To find the venue for a sentence, name its audience out loud: "whoever questions this change" is a reviewer, and a reviewer reads the PR.

**A ticket or PR number stays only when the later reader needs it to change the code safely.** Two cases do: `TODO(ID):` for open work, and a workaround tied to a bug that is still open, where the reference says when the code can go.
A number that only records which item delivered the code fails the test whether or not the tracker keeps finished items.
Blame already reaches it, and where a tracker deletes or renumbers them it points at nothing.
A repo that documents a different convention, such as an issue link on every bug fix, follows its own.

**Length.** These are the defaults where the repo sets none.

- An implementation comment is a line or two.
  A third line is the cue to re-run the test on each sentence.
  Content that still needs a paragraph is a doc: write it there and leave one line pointing at it.
- A doc comment is as long as the contract.
  How the function works inside is not contract.
- A file or script header says what the file is for and how to invoke it.
  Design history and the story of each flag fail the test like any other sentence.

**Placement and register.**

- **Anchor the comment to the line it explains.** A comment about an assertion goes above the assertion, not above the variable six lines up that happens to start the block.
- **One explanation, one place.** The same reasoning at three call sites means a named constant or helper is missing.
  Explain it once at the declaration and let the name carry it at the uses.
- **No metaphors.** "Plumbing", "under the hood", "wiring", "glue", "magic".
  Name the mechanism: not "handles the plumbing" but "propagates the request context into the watch goroutine".
- **Uneven is normal.** Real files hold a trailing `// unused; kept for the interface` next to a hundred lines with nothing.
  Uniform paragraphs wrapped to one width are a tell by themselves; when varying feels forced, delete.

**In a file that fails the test,** new and rewritten comments follow this step anyway.
When changing code, trim the comment that describes it in the same commit and move what fails.
Leave comments on untouched code alone: a sweep is its own change, like any restructuring.

**A repo's own comment rules win** on venues, length limits and ticket format, whether they sit in a doc or a repo-local skill.
This step is the default where there are none.

**Worked example.** The comment that drew "this comment reads as AI generated", sitting above a shell script variable:

```go
// On SIGTERM the container stops passing its readiness probe but keeps
// running for the rest of the grace period. Staying alive is what lets
// the assertion tell "the readiness probe ran and failed" apart from
// "the container is gone", see waitForTerminatingPodNotReady.
```

It fails the test on most of its length: it argues the design to a reviewer, and it is unanchored and paragraph-shaped besides.
Moved to the line it is about and cut to the mechanism:

```go
// The container outlives the probe failure, so NotReady means the probe ran.
framework.ExpectNoError(waitForTerminatingPodNotReady(ctx, f, pod))
```

The design rationale that got cut is not lost — it goes in the PR description, where a reviewer is actually looking for it.

### Step 4 — Re-measure before handing it over

Run the same density number over the added lines and compare it to the file's ceiling:

```bash
git diff -U0 -- path/to/file.go | awk '
  /^\+\+\+/ || /^\+[[:space:]]*$/ { next }
  /^\+[[:space:]]*(\/\/|\/\*|\*)/ { c++; next }
  /^\+/ { t++ }
  END { printf "added %d comment / %d code = %.2f\n", c, t, c/t }'
```

Then check, in order:

- Added density no higher than roughly 2x the file's.
  Over that, cut comments until it is not; under it proves nothing, so read on.
- Every sentence in an added comment passes the later-reader test, and everything cut is in the commit message, the PR description or a doc.
- No ticket or PR number, date, or change-narration word in an added comment, outside a `TODO(ID)` or an open-bug workaround.
- No added implementation comment over two lines without a sentence-by-sentence reason.
- Every new function within roughly 2x the median for its construct.
  Over that, extract.
- No two added blocks that differ only in literals.
- Every helper you wrote checked against the grep from step 1.
- Every added comment anchored to the line below it.
- No added defensive check its sibling call sites lack; failure paths stay loud.
- No unused imports or parameters, commented-out code, or suppression casts left from an earlier draft.

## Scope

Applies to source files: implementation, tests, build scripts, anything a reviewer reads as code.

Three things this does not mean:

- **Doc comments on exported symbols are convention, not density.** Godoc, docstrings, Javadoc, JSDoc on public API are required by the file's convention.
  Write one per exported symbol, in the house format, as long as the contract.
- **Comments that are published documentation keep their length.** API field descriptions that generate reference docs, and annotated config a user reads as its manual, are docs that live in source.
  The test still applies to them; the length defaults do not.
- **Generated files and vendored code are out of scope.**
- **Correctness is a different review.** Wrong logic, missed edge cases, and APIs that don't exist are bugs, not style — this skill will not catch them, and passing it does not mean the change works.
  The reverse holds too: passing tests say nothing about whether the diff reads like the file.

Related skills:

- A personal voice skill, if one is loaded, covers the prose that this skill moves things *into* — PR descriptions, issues, and review comments.
  Reach for it when a comment gets cut from a diff and needs a venue.
- A voice or essay guide's advice on metaphor stops at the file boundary.
  Committing to an extended metaphor is essay craft, and "handles the plumbing" is what that register produces once it reaches a comment.
  In code, step 3's rule against metaphor wins.
- `tech-docs-layers` covers repo-resident user-facing docs, not in-code comments.
- `deslop` is this skill's prose counterpart and shares its trigger phrases ("deslop this", "remove the AI slop").
  Source files are this skill; docs, READMEs, and PR descriptions are that one.
