---
name: code-restraint
description: Keep authored source from reading as machine-written by matching the host file's comment density, altitude, defensiveness, and code shape. Use when the user asks for "code restraint" or "code-restraint" on a diff, and when a review says "this reads as AI generated", "the comments are too long", "the dense narrative style", "too many comments", "too defensive", "why all the try/catch", "match the existing style", "why didn't you use the existing helper", "remove the dead code", or flags duplicated blocks, over-long functions, or leftover scaffolding. Also use before committing a code diff, and when comments in a PR look like they belong in docs instead. Covers comments in source (density, altitude, mechanism over argument, anchoring, no change-narration, one explanation in one place) and code shape (reuse existing helpers, match median function length and naming register, extract near-identical blocks, no speculative structure, no dead weight in the diff). Not for prose — deslop owns slop in text.
---

# Code restraint: source that reads like the file it landed in

The tell that code was machine-written is rarely one bad sentence. It is proportion. A block with 10x the comment density of its neighbours reads as generated before anyone parses a word of it, and three near-identical 50-line functions read as generated even with no comments at all. Both come from the same root cause: writing self-contained blocks instead of going to look at the local idiom first.

This skill is two halves. The code-shape half matters more — no amount of comment discipline saves a 60-line spec that should have been 8.

## How to use this skill

Measure the host file before writing (step 1). Apply the shape rules, then the comment rules, while writing (steps 2 and 3). Re-measure the diff before handing it over (step 4).

Step 1 is the one that gets skipped and the one that does the work.

### Step 1 — Measure the host file first

Three numbers, all from the file being edited. Take them before writing a line.

**1. Comment density.** Comment lines over non-comment, non-blank lines. The exact definition matters less than using the same one on both sides of the comparison.

```bash
awk '
  /^[[:space:]]*$/ { next }
  { if ($0 ~ /^[[:space:]]*(\/\/|\/\*|\*)/) c++; else t++ }
  END { printf "%d comment / %d code = %.2f\n", c, t, c/t }' path/to/file.go
```

For `#`-comment languages (Python, Ruby, shell) swap the pattern for `/^[[:space:]]*#/`; for SQL and Lua, `/^[[:space:]]*--/`.

**2. Median size of the construct you are adding.** Compare like with like: top-level functions against top-level functions, test cases against test cases, table entries against table entries. Span between successive declarations is a good enough proxy.

```bash
rg -n '^func ' path/to/file.go | cut -d: -f1 \
  | awk 'NR>1{print $1-p} {p=$1}' | sort -n \
  | awk '{a[NR]=$1} END{printf "median %d lines over %d\n", a[int((NR+1)/2)], NR}'
```

Change the anchor for the construct in question: `'ginkgo\.It\('`, `'t\.Run\('`, `'^[[:space:]]*(it|test)\('`, `'^[[:space:]]*def '`.

**3. Helpers that already exist.** Grep the file for the nouns in the thing you are about to build, then the package, then the shared test-helper package.

```bash
rg -n '^func ' path/to/file.go
rg -n 'func .*(Handler|Probe|Spec|Client)' path/to/
```

Do this even when the thing to build is small. Rebuilding a helper that sits 200 lines up the same file is the most visible version of this failure.

**Check the baseline is worth matching.** Matching assumes the file's style is human idiom. On a codebase largely written by earlier AI sessions, the measurement can come back already sloppy, and matching it locks the slop in. Signs the baseline is machine-written: implementation-file density far above idiomatic for the language (a Go or Python implementation file near or above 1.0 comment/code), uniform wrapped paragraphs above ordinary statements, comments narrating past diffs or ticket numbers. Any of those — or the user saying the existing style is too verbose — means do not match the file. Calibrate to idiomatic terse style for the language instead, and treat the file's distance from that as part of what the change or review should fix. Narrative rationale still has a venue — docs and PR descriptions — and doc-comment conventions on exported symbols (godoc, CRD field descriptions, API docs) stay exempt as in Scope.

### Step 2 — Code shape

- **Search before you build.** If a helper for this already exists in the file, the package, or the project's test-helper package, use it. If it exists but does not quite fit, extend it or say in the PR description why a second one is warranted — do not silently fork it.
- **Match the median.** A new function 3x the file's median for that construct means a helper is missing. Pull the setup out, leave the intent in the body.
- **Two near-identical blocks means extract, not copy.** By the third the extraction is not optional. Three 50-line blocks that differ in two literals are one helper and three short call sites.
- **Match the file's existing decomposition, not a better one you have in mind.** If every test in the file builds its pod spec through a constructor, yours does too. Restructuring the file is a separate change.
- **Match the file's defensiveness.** Validate where the file validates — usually the boundary where untrusted input enters. A try/catch, nil check, or fallback default that the function's siblings don't have reads as hedging against invariants you didn't check, and the fallback hides the failure it wraps. If the input is guaranteed upstream, trust the guarantee and let real failures stay loud.
- **No structure for a use case that has not arrived.** One implementation means no interface; one product means no factory; one caller means no option parameter. Add the seam when the second consumer shows up — it will tell you where the seam goes.
- **Ship only what the change needs.** No unused imports, parameters, or exports left from an earlier draft; no commented-out code (git is the archive); no `as any` or `# type: ignore` to route around a type error instead of fixing the type.
- **Match the file's naming register.** If the file says `checkAuth` and `mkPod`, a new `handleUserAuthenticationValidation` is a tell. Identifier length and vocabulary are local idiom like everything else.

### Step 3 — Comments

1. **Match the density you measured.** Being an order of magnitude denser than the surrounding file is the tell, independent of what any single comment says. If the file runs 0.04 and the new block runs 0.46, cut until they are close. If step 1 flagged the baseline as machine-written, the file's own number is the defect — match idiomatic density for the language instead and let the diff run leaner than its surroundings.

2. **Describe the mechanism, not the argument.** A comment explains what the code does and why it must be this way for a future reader. If a sentence would fit in the PR description, put it in the PR description.

3. **Sit above or below the code's altitude, never at it.** A comment below the code's altitude adds precision the code cannot carry: units, whether a bound is inclusive, what nil means here. A comment above it adds intent: what the block is for. A comment at the same altitude paraphrases the line under it and is the first thing to rot when that line changes — delete it.

4. **Describe the code, not the change.** `// now uses the shared client`, `// no longer retries` — comments addressed to the diff reviewer turn into nonsense the moment the diff merges. Code reads as if it had always been this way; what changed and why goes in the commit message.

5. **A comment arguing with a hypothetical reviewer belongs in the review thread.** This is the sharpest test of the set. `// Returning the error rather than logging it is deliberate: ...` was written to stop someone from reverting the change, not to help anyone read the code. Name the comment's audience out loud. If the audience is "whoever might question this change", the venue is the PR thread, not the file.

6. **Anchor the comment to the line it explains.** A comment about an assertion goes above the assertion, not above the script variable six lines up that happens to start the block.

7. **One explanation, one place.** The same reasoning appearing at three call sites means a named constant or helper is missing. Name the thing, explain it once at the declaration, and let the name carry the meaning at the uses. Cross-reference rather than restate.

8. **No metaphors.** "Plumbing", "under the hood", "wiring", "glue", "magic", "behind the scenes". Name the mechanism instead: not "handles the plumbing" but "propagates the request context into the watch goroutine". Metaphor is essay craft; in source it costs a reviewer a round trip asking what you meant.

9. **Vary or omit.** Uniform three-sentence paragraphs wrapped to identical width are a tell by themselves. Real comments in real files are terse and uneven — a trailing `// unused; kept for the interface` next to a five-line block next to a hundred lines with nothing. When varying feels forced, delete instead: a comment that merely restates its line already failed the altitude test.

**Worked example.** The comment that drew "this comment reads as AI generated", sitting above a shell script variable:

```go
// On SIGTERM the container stops passing its readiness probe but keeps
// running for the rest of the grace period. Staying alive is what lets
// the assertion tell "the readiness probe ran and failed" apart from
// "the container is gone", see waitForTerminatingPodNotReady.
```

Four rules at once: too dense for its file, arguing the design rather than describing it, unanchored, and paragraph-shaped. Moved to the line it is about and cut to the mechanism:

```go
// The container outlives the probe failure, so NotReady means the probe ran.
framework.ExpectNoError(waitForTerminatingPodNotReady(ctx, f, pod))
```

The design rationale that got cut is not lost — it goes in the PR description, where a reviewer is actually looking for it.

### Step 4 — Re-measure before handing it over

Run the same density number over the added lines and compare it to the file:

```bash
git diff -U0 -- path/to/file.go | awk '
  /^\+\+\+/ || /^\+[[:space:]]*$/ { next }
  /^\+/ { if ($0 ~ /^\+[[:space:]]*(\/\/|\/\*|\*)/) c++; else t++ }
  END { printf "added %d comment / %d code = %.2f\n", c, t, c/t }'
```

Then check, in order:

- Added density within roughly 2x the file's — or of the idiomatic target, when step 1 flagged the file as machine-written. Over that, cut comments until it is not.
- Every new function within roughly 2x the median for its construct. Over that, extract.
- No two added blocks that differ only in literals.
- Every helper you wrote checked against the grep from step 1.
- Every added comment anchored to the line below it and addressed to a reader, not a reviewer.
- No added comment at the same altitude as its line, and none narrating the change.
- No added defensive check its sibling call sites lack; failure paths stay loud.
- No unused imports or parameters, commented-out code, or suppression casts left from an earlier draft.

## Anti-patterns

- Writing the block first and reading the file afterwards, or not at all.
- Measuring a machine-written file's 1.2 comment/code ratio and preserving it as "local idiom to match".
- Rebuilding a helper that already exists 200 lines up the same file.
- A comment above each of three call sites explaining the same magic number, instead of one named constant.
- Explaining the design decision in the code because the PR description felt like the wrong place for it. It is the right place.
- Uniform wrapped paragraphs above every block, at a density nothing else in the file comes close to.
- Wrapping a call in try/catch that no sibling call site has, on a path already validated upstream.
- An interface, factory, or option parameter with exactly one consumer, added "for flexibility".
- `// now handles the empty case` — a comment narrating the diff instead of describing the code.
- Silencing a type error with a cast instead of fixing the type.
- Restructuring the file's decomposition mid-change because the existing shape is not the one you would have picked.
- Treating "the tests pass" as done. The tests passing is orthogonal to whether the diff reads like the file.

## Scope

Applies to source files: implementation, tests, build scripts, anything a reviewer reads as code.

Two things this does not mean:

- **Doc comments on exported symbols are convention, not density.** Godoc, docstrings, Javadoc, JSDoc on public API are required by the file's convention and already counted in its baseline. Match the convention — one per exported symbol, in the house format — and let the density number cover the rest.
- **Generated files, vendored code, and config formats with comment-as-documentation conventions are out of scope.** Do not apply density matching to a Dockerfile or a heavily annotated CI config.
- **Correctness is a different review.** Wrong logic, missed edge cases, and APIs that don't exist are bugs, not style — this skill will not catch them, and passing it does not mean the change works.

Related skills:

- A personal voice skill, if one is loaded, covers the prose that this skill moves things *into* — PR descriptions, issues, and review comments. Reach for it when a comment gets cut from a diff and needs a venue.
- A voice or essay guide's advice on metaphor stops at the file boundary. Committing to an extended metaphor is essay craft, and "handles the plumbing" is what that register produces once it reaches a comment. In code, rule 8 wins.
- `tech-docs-layers` covers repo-resident user-facing docs, not in-code comments.
- `deslop` is this skill's prose counterpart and shares its trigger phrases ("deslop this", "remove the AI slop"). Source files are this skill; docs, READMEs, and PR descriptions are that one.
