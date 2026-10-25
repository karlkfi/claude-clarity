# Trusting a check

`SKILL.md` sends you here before a gate, a CI run, a sweep, or a probe is trusted to say something is clean, covered, or gated. An italicised rule name that is not in this file is
in `SKILL.md` or in a sibling file under `references/`.

**A probe with two verdicts forces every failure onto one of them.** *The probe is not the gate*
keeps a probe honest about the question it answers; this one is about the answers it can give. A
hand-rolled check whose output space is `LIVE`/`DEAD`, `CLEAN`/`CONFLICT`, present/absent has
no room for *I could not tell*, so a lookup that failed, a name that never resolved and a
genuine negative all arrive at the same arm and print the same word. Nothing marks it, because
what comes back is a well-formed verdict rather than the empty result that means *not there* —
the probe ran, it produced output, and the output is simply not the answer the state warrants.
Three probes can return three wrong verdicts
each shaped exactly like a right one: `git merge-base --is-ancestor "$ref" origin/main && echo
IN-MAIN || echo LIVE` printed `LIVE` both for a well-formed SHA absent from the object store
and for a ref that does not resolve at all — raw exit 128, `fatal: Not a valid object name`,
swallowed by the `||`. A sibling merge probe returned a false `CLEAN` against a base that had
moved under it, and a link sweep a false `DEAD` on a line its parser could not read. None was
caught by inspecting the probe. Each was caught by an independent source disagreeing, which is
why *write probes carefully* is not the fix.

Give the failure path a value of its own, and make it name what could not be read:

```bash
if sha=$(git rev-parse --verify --quiet "$ref^{commit}"); then
    git merge-base --is-ancestor "$sha" origin/main && echo IN-MAIN || echo LIVE
else
    echo "UNRESOLVABLE: $ref"   # not a verdict
fi
```

A committed checker usually does this already: a read it cannot take records *unmeasurable* and
says which read failed. That asymmetry is the whole gap — the checks a project commits refuse to
guess, while the one-line checks its sessions type into a shell still land on an answer, and the
shell one is the one deciding something right now. Enumerate the ways the probe can fail before
you write the branch, and where a failure has nowhere to go but a verdict, that verdict is not
evidence.

**Extracting a call argument by name breaks wherever two functions share the name.** A scan that
pulls an argument out of a call site keys its table on the callee's name, and two functions sharing
a name hold that argument at different positions — normal in any codebase with wrappers. It then
fails in both directions at once: it reports a neighbouring argument as a hit, and reports nothing
at all for the calls whose index it guessed past. Read the position off each callee's own
declaration, and fail loudly on a call you cannot place. Two sub-traps: a variadic declaration's
arity counts the trailing parameter, and a parameter of the enclosing function forwards rather
than decides the value.

**A scan that tracks enclosing scope must clear it at the end of the block.** An `awk` or `grep`
pipeline that remembers which function, section, or block it is inside and never resets attributes
every later top-level match to the last block it saw. It shares the failure mode above: a
confident positive rather than a silence, so nothing in the output looks wrong. The positive
control is what catches it — count one block by hand and require the scan to agree.

**A rule fires on a subject, so confirm the subject existed when the check ran.** A green check
folds two claims into one — the rule held, and there was something for it to hold on — and when
the second fails the first is vacuous while the output is identical to a real pass. Three
instances in one night, 2026-08-21: a store lint's *a flake row may not vanish* rule taken
against a merge base carrying no such row, a `staticcheck` exclusion still listed in
`.golangci.yml` after the directives it excluded had been deleted, and a fail-open introduced by
an evidence capture, whose failure mode had no fixture until that change created one. Not there
yet, gone, and never exercised are three ways in and one check covers all three: name the
subject, count it, and refuse on zero rather than passing.

**A literal-name search is blind to every site that routes the name through a variable.** A
suite's assertion subjects, a registry's keys, a table's fixture names — two helpers taking the
name as a parameter is enough, and the search then returns a clean subset of the truth with
nothing marking it as a subset. A literal-name sweep for a suite's twenty-five subjects saw
thirteen, on a tree nobody had touched. The blind spot belongs to the *file* rather than to the
change under review, so the size of the miss says nothing about the size of the diff — which is
why a small change is no reason to trust it. Run the suite and read the subjects it reports.

**A sweep that comes back clean has told you about its own representation.** *A literal-name
search is blind* to one such representation, a name reaching its site through a variable. Four
more turned up where three sessions each enumerated every place in a repo asserting one claim so it
could be corrected, and all three sweeps came back falsely clean for different structural reasons.

- **Subject scope.** A sweep requiring the subject term and the claim language in the same
  *sentence* misses every sentence that names its subject anaphorically, and it hides *the* site
  preferentially rather than *a* site: a paragraph names its subject once and refers back
  thereafter, so the sentence carrying the load-bearing claim is the one that has stopped saying
  what it is about. The sentence that motivated the whole correction carried no subject token at
  all, only *the two producers* and *one condition type*. Test the subject over the surrounding
  paragraph, or a few hundred characters, rather than over the sentence.
- **Vocabulary.** A pattern built from a literal string lifted off known instances finds
  restatements of that string and nothing else. Six known sites shared a phrase; six more
  asserted the same claim sharing no literal with it.
- **Inherited vocabulary.** The second sweep, written to fix the axis above, derived its widened
  signature from the first probe's own hits, and a signature built out of the answers it exists to
  validate can only re-find them — *A construction derived from its own answer*, and it looks like
  the fix.
- **Line breaks.** A line-oriented pattern cannot match a claim spanning two comment lines, and
  the site reads as absent. Strip the leaders and join the lines before matching.

**A clean sweep and a blind one both print nothing.** Fire it at a state where instances are known
to exist — the commit before the corrections landed — and require all of them before trusting what
it says at head. Pick that known positive to be the hard case: the control is what exposed the
subject-scope axis at all.

**A correction that looks complete is what stops the search for the claim's other copies.**
Fixing a false sentence where you found it leaves a diff with the sentence gone and a commit
message saying why, which is exactly what you would see if the claim also stood somewhere nobody
opened. A code comment called a fixture the one case in its file built outside the loader; two
tests there already were, the comment was fixed, and the claim survived verbatim in the PR body. A
claim written once was usually written twice, out of the same paragraph of thinking. So sweep for
the claim, not the file you edited, before correcting it while the phrasing is still to hand — and
make the sweep able to see, by the two rules before this one.

**A scan counts text, and text describing a command cannot be told from text that ran it.** The
same blindness as a false positive — and where the population is your own transcripts it feeds
itself, since writing about a command adds instances of it. Anchoring to command position narrows
it and cannot close it: only a parser that knows a heredoc body, a quoted string and a comment are
data tells a word from an invocation. An anchored count of `git merge-tree` calls held at 264 over
four readings and returned **265** on the fifth — the extra hit the reviewer's own session, writing
a probe script that contained it. The tell is a count that moves between readings hours apart with
no new events, always upward, and it is legible only if you predict the direction first: one unit
against an expected-stable figure otherwise reads as noise. The anchor is in
[`references/shell-traps.md`](shell-traps.md).

**A sound instrument still answers only its own question.** This is the one that survives "check
more", because nothing is missing — *A probe with two verdicts forces every failure onto one of
them* gives a failure somewhere to go, and here nothing fails. Nobody writes the gap down because
the probe and the claim share their vocabulary: *is this string in the file* and *does this
program print this string* differ by one verb. It comes in two shapes. The instrument answers a
**narrower** question than the claim: a grep of a merged script for a message its change had added
returned **0**, the message being assembled from f-string fragments that exist at runtime and
nowhere contiguous in the source. Or it answers an **adjacent** one — a different quantity, object
or definition, at the same type and a plausible magnitude, with nothing in the output marking which
question it answered. `git merge-tree --write-tree` consults `.gitattributes` and returns the
**merge driver's** answer, and drivers are per-clone while the queue building the real candidate
runs none; a two-dot `git diff origin/main..HEAD` against a moved base renders the base's own
commits as the branch changing them.

**Ask what question the instrument answers, not whether its answer looks right.** What does
`merge-tree` consult; what quantity does this reading measure, and under what conditions;
what is in the cited file. An *over-sourced* citation is the one that gets through: a real file
with a real number trips none of the reflexes tuned to flag thin sourcing. A hedge rescues none
of this: it sits on the inference, and the error is upstream in the probe. Both halves of the
sentence are written in the same words, so ask what this instrument would report if the claim
were false **in a way it cannot see**.

**Being right by luck is indistinguishable from being right by construction.** An instrument
answering an adjacent question can still return the right verdict, as both git instruments above
did against correct re-runs, and nothing in the agreement marks it. That is a different argument from *a negative needs a positive
control*: there the answer is suspect, here it is right and the method still gets checked,
because it is reached for again where the luck does not hold. Each adjacency instance behind this
rule was caught by another seat and none by its author: the remedy is a second reader, not more
care.

**A tool you run has two copies, and a grep finds whichever one you pointed at.** An installed
plugin, hook, or CLI sits under a versioned cache directory; the project it came from has a
`main` that is usually ahead of it. A claim about how the tool behaves is checkable against
either, they disagree exactly when a release is pending, and reading the wrong one returns a
confident negative — nothing found, on a real file, in a real checkout, with no hint that the
answer came from a different artifact than the claim. An issue asserted that
pr-sentinel denies a `gh pr create` overlapping an open PR, and named
`PR_SENTINEL_OVERLAP_ENABLED` as the knob that disables it. Neither string appears anywhere in
the installed 0.9.0; both are on the project's `main`, in a file that release does not ship. The
local grep would have reported the issue wrong on its own evidence. Ask which copy the claim is
about — an issue, a release note, or someone's PR is almost always about the branch it was
written against — and say which one you read.

**A claim about what a change did needs a before-and-after.** Scanning the after-state answers a
different question than "which of these did this change produce", and the two numbers differ
by more than you expect. Run the probe against the base tree too, and diff.

**A two-tree comparison is controlled only where both trees carry the mechanism.** *A claim about
what a change did needs a before-and-after* sends you to the base tree; this one is about what you
find when you get there. *A rule fires on a subject* catches a check that passed with nothing to
check. Inside a comparison the same vacuity surfaces as a *row*, where it reads as fixed rather than
as absent — a zero in a before-and-after table is what a fix looks like. A leak table reported the
trunk clean on six of seven shapes because the package implementing those six did not exist on the
trunk, so six "before" cells were blanks. `git ls-tree` exits 0 on a path that is not there, so the
blank arrives with a clean status and no mark on it; confirm each tree contains the mechanism its
row is about before reading the row, and say which rows are blanks rather than befores.

**Ask what a check would still pass on**, then check whether the thing you care about is in that
set. A gate named for a class covers one mechanism inside it, and the name is what makes the
rest of the class feel guarded. Say in the check itself what it does not read. And a
fail-closed refusal must name the condition it actually detected — "unrecognized record format"
routes the reader at a migration; "the value was empty" routes them at a corrupt file they do
not have.

A gate also trains a habit, and the habit is scoped to the gate's pattern rather than to the
claim's class. A session that re-checked a quoted test line after a rebase, crediting the citation
linter that flags stale `path:N:text` pointers, left a commit count in the same PR body that the
same rebase had falsified. Where a gate covers part of a class of claim, name the members its
pattern cannot see, and treat them as unchecked rather than as covered by the habit.

**Green checks say the run passed, never that your change is gated.** The two come apart exactly
when a gate is new, which is when nobody looks. Verify by naming the gate's *job* in the run's
job list, not by the run's conclusion. `gh run list --commit <sha>` cannot do that — it reports
conclusions per run, and a run whose heavy job skipped while its `-gate` job passed concludes
`success`. `gh api repos/:owner/:repo/commits/<sha>/check-runs?per_page=100` is the read that
lists jobs and their `skipped` conclusions, and it is the only one that separates a lane that
ran from a lane that reported on behalf of one that did not.

**To learn what CI actually checked out, reproduce the merge ref's tree; do not read a run log.**
*Green checks say the run passed* names the job in the job list, which settles whether your gate
ran. This settles what it ran *over*, and a log line is the wrong instrument for it — a log says
what one job did on one attempt, and a rerun, a stale annotation or a skipped job each leave a line
that reads the same. The tree hash says what the ref is. `git merge-tree --write-tree <base> <head>`
prints the id of the tree a merge would produce, and it compares directly against
`refs/pull/N/merge^{tree}`, an identity that rests on no path taking a custom merge driver, since
`merge-tree` applies whatever driver this clone has and a merge-queue candidate is built with none.
Where one is configured, reproduce the ref rather than compute it.

**A merge ref recomputes on a push to the PR branch, not when the base moves.** So a green check can
be scoped to a merge base that no longer exists, and nothing in the PR marks it: the checkmark, the
head SHA it names and the ref it ran over are all still exactly what they were, and only the base
has changed underneath. *Was this green* and *was this green against what is on the trunk now* are
two questions, and the second needs the merge base the ref was built on, read against the base
branch's current head.

**A count is the wrong instrument for "did every check run".** *Green checks say the run passed*
sends you to the job list, where the reflex is to compare two heads by how many runs each has. A
total cannot separate a duplicate from a substitution, and two offsetting changes leave it
unmoved — the reading that looks most like proof. Ask instead which job families are
present at one head and absent at the other; only the name sets answer it. A drop from 38 check
runs to 37, all `SUCCESS`, was a duplicate run from a PR body edit with no family lost.

```bash
gh pr view <N> --json statusCheckRollup \
  -q '.statusCheckRollup[] | "\(.conclusion // .status)\t\(.name)"' | sort
```

Reduce each head to `cut -f2 | sort -u` and `comm -3` the two: a lost family lands left, a gained
one right, a substitution as one of each. Keep the conclusion and a job that merely changed colour
reads as a loss and a gain; keep duplicates and the duplicate run reports itself as a difference.
The rollup is about the head the PR carries, so an earlier head takes the `check-runs` read
above and the same cut. Both list the jobs that exist, which is what makes the name set the whole
instrument: a path-filtered job is visibly `SKIPPED` there, while an absent one is not listed at
all, and absence is what a set difference reports and no total can. Absence reads three ways,
the third being *not scheduled yet*: settle the run, nothing `in_progress` or `queued`,
before a difference decides anything, and otherwise resolve each absent family against its
`needs:`. An absent `-gate` aggregator beside a running job is the tell: an aggregator is scheduled
last.

**A coverage claim searched for as a mechanism finds one implementation and reports on every
route.** *A count is the wrong instrument for "did every check run"* swaps a total for the name
set; this swaps the subject. The claim is about an effect — this linter runs in CI — and what gets
written is a search for the mechanism the author expects to carry it, so a second route to the same
effect is invisible, and the zero reads as a coverage hole rather than as a search that could not
have found one. A `run: make` sweep over a repo's workflows came back empty for one linter and
nearly shipped *it is gated nowhere*; the linter runs on every push, through a test in the root
suite that no pattern over `run:` lines can reach. Ask what would have to be true for the effect to
occur by **any** route, and settle it downstream of the mechanism — plant a violation and watch
something go red. It names what a family of such probes share: each **searched for the
mechanism its author expected rather than the effect its author was claiming**.

**A completeness claim inherits the blind spots of its inventory.** A derived inventory can
answer "nothing is missing"; a curated one answers "nothing that someone recorded is missing",
and those diverge exactly where it matters. Say which kind you read before the answer carries a
decision. Correspondingly, a gate that derives its own inventory has to **fail on an input it
cannot place** — under-derivation is not a missing refusal, it is a refusal that will never be
attempted, and nothing turns red when the check that would have fired is the one that went
missing.

**Check for an existing recorded observation before booking a live measurement.** "Measure it"
does not always mean "run it". A committed capture, an archived results table, or a constant
some earlier live run corrected in a comment may already hold the answer. The corollary is why
it stays unfound: a capture with no test asserting against it is decoration, and it ages into a
file everyone assumes someone else is checking.

Also in `SKILL.md` §2, in [`further-rules.md`](further-rules.md): *Agreement
with the enforcer is not evidence when one detail could fool both*; *A measurement that reproduces a
call is not a test of the code that makes it*; *The checker is a fourth subject, and that check
cannot count it*; *Two causes that predict the same count are not distinguished by that count*.
