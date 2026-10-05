---
name: verify-claims
description: Check that the evidence behind a statement could have shown you the opposite, before the statement decides anything. Use when a gate, test, or CI result is about to be reported or trusted, when a claim about where code came from, who wrote it, or how a repo is laid out decides something, when reporting a reading of someone else's file taken earlier, when ticking a PR checklist box or writing release notes, when chasing a flake or a regression, when working out a root cause or reproducing one, when asking whether a check actually ran, when a probe, grep, scan, or count is about to justify a decision, when writing or reviewing a test or gate, and when explaining why a system behaved as it did. Covers exit status lost through pipes and background chains, empty output from a command that never matched, a sound instrument whose question is narrower than the claim, hand-rolled probes standing in for gates, provenance read off resemblance, and proving a fix by deleting the mechanism. Not for deciding what to build.
---

# Verify claims

A verdict is only as good as the signal under it, and the expensive failures are not
corrupted signals — they are sound instruments answering a narrower question than the
sentence they get quoted in.

## The move

Name the signal the claim actually rests on. Ask what that signal would read **if the
opposite were true**. If the answer is "the same", the reading cannot settle the question,
however sound the instrument is — find the signal that would differ, and read that one.

Everything below is this move aimed at a particular moment.

## Fire this when

- A verdict is about to leave your mouth: passed, failed, clean, done, fixed, empty, none.
- A number or a superlative is about to go in a sentence — "six of them", "the only one
  without a test", "none of the workflows".
- A timestamp, a duration, or an interval is about to go in a sentence, and it came from
  somewhere other than the clock.
- A measured value is about to go into a document, and the setup that document describes is not
  the one you measured in.
- You are diagnosing a failure, and especially when it resembles one you recognize.
- A probe, grep, scan, or count is about to decide what you do next.
- Two steps in a plan read and write the same log, counter, or record, and one runs first.
- A gate or a suite is running in the background, and you are about to write a file it reads.
- You are writing a test, a gate, or an assertion.
- You are about to explain *why* a system behaved as it did.
- A sentence is about to say where something came from, who wrote it, or how a repository is
  arranged.
- You are about to report a reading you took a while ago, of something you do not control.
- You are filling in a PR body, a release note, or a status report — a ticked checkbox and an
  enumerated bullet are claims, whatever the template makes them feel like.
- You are about to repeat, in a PR body or a summary, something the issue or the brief asserted.

## Where an unfalsifiable check comes from

The move answers yes or no. When it answers no it does not say where the gap is, and *nobody ran
a check that could have come out the other way* is a true account of nearly every miss and a
useless one: four separate causes collapse onto it, and each is searched for differently. The
first three were measured 2026-08-25 over the misses in one review.

- **A construction derived from its own answer.** The instrument was built out of the result it
  exists to validate — a search pattern widened from the hits it already had, a fixture generated
  from the output under test, a sample drawn from the population it is meant to characterise. Ask
  where the pattern, the fixture, or the sample came from. If the answer is "from the thing I am
  checking", it cannot fail. A cross-check has this shape when it is an identity rather than a
  comparison: `added − displaced = after − before` agrees exactly whenever `added` was computed
  from the other three, wrong values included. Ask where each term came from; a real cross-check
  reaches the quantity by two routes that could have come apart.
- **An untested input class.** The claim was checked across the inputs someone thought of, and one
  class was never run at all. A guard read `prev != nil && !isSessionSourced(prev.Reason)`, and the
  prose describing it was checked against every non-nil `prev` and never against nil, which is
  where the behaviour inverts. Ask what class the claim quantifies over, then which member of it
  has never been through the check.
- **An unexamined case.** Reasoning stopped at the case that agreed with the conclusion. An author
  defending their own phrasing traced the scenario where it held, and not the scenario their own
  design document contemplates, where it inverts. Ask what case would make this false, and whether
  you traced it.
- **An unsampled population.** The claim quantified over a population nobody looked at, while the
  instrument that would sample it was already built. A predicate for sessions that edited source
  listed `.ts`, `.tsx` and `.rs` from recall, matching zero sessions in the corpus, and omitted
  `Makefile`, which matched 92; deriving the list took one pass over a script already in hand. Ask
  what the cheapest check you did not run was. A small agreeing spot-check is worse than none here:
  the corrected denominator moved only 734 → 741, so a wrong claim can survive nearly intact.

Only the third feels like a lapse while you are committing it, and the fourth feels like nothing,
since nothing was believed checked. The first two feel like finished work, which is why they
survive a review that is looking for the third.

## 1. Reading a result

**Exit status is easy to lose.** A pipeline reports its last stage, so a gate piped into a
filter reports the filter's success. Backgrounded, the completion notification reports the
whole compound's last command, which is rarely the gate: a chain ending in `echo` always
ends 0, so the failing gate arrives as `completed (exit code 0)` — the most
authoritative-looking signal available and the only wrong one. A chain ending in a *grep for
failure lines* is worse, because it inverts rather than flattens. On `make check > log 2>&1; echo "EXIT=$?"; grep -E "FAILED|Error [0-9]|^make:" log`, a failing gate notified `completed (exit code 0)` and a clean one notified `failed with exit code 1`,
the grep having matched in the first case and not the second. Preserve the status explicitly
— `cmd > out.log 2>&1; rc=$?; exit $rc`, with the `exit` last so a trailing filter cannot
overwrite it — and reconcile it against the log, because a gate exiting 0 while its own
output carries a failure line is the other half of the same trap. And a check *sequenced*
before a mutation does not gate it: `lint; git commit` runs the commit whatever the linter
said.

**A process probe whose pattern sits in its own command line matches itself.** Asking whether a
job is still running with a pattern the asking command also carries as text answers "running" for
as long as you keep asking. That is worse than having no probe: the reading is stable, plausible,
and decoupled from whether the job is alive, so it survives every re-check. A background job's
verdict comes from its completion status and its output, never from a process probe. Where one is
genuinely needed, break the self-match and confirm it against a case whose answer you know.

**Silence has three causes and they look identical.** The thing is absent; the command never
ran; the command ran and asked after a name that does not exist. Only the first is a finding.
A tool that exits 0 having printed nothing may have checked nothing — when a verification's
whole value is that it ran, make it emit something assertable rather than trusting status.

**A legend emitted beside a command decides its reading before the output exists.**
`echo "(empty = all green)"` printed next to a check that has not run yet converts all three
causes above into a finding, in advance and for every later reader: the transcript then carries
an interpretation with nothing under it, in the register of a result, and the one form of
emptiness that would have been informative is the one it reads past. It is the completion
predicate above one step earlier — the verdict is fixed before the instrument reports — and it
is cheap to do repeatedly, because it looks like labelling rather than concluding. Print the command's own output; write what
it means after reading it.

**An empty value in a filter argument widens the query instead of narrowing it.** Empty *output*
has the three causes above; an empty *input* has one effect and it is the inverse of silence — the
command answers about a wider population than you asked about, in the shape of a successful
filtered read. The general form is any `--flag "$VAR"` fed from a read that can fail, where empty
means *no filter* rather than *no match*: under an API outage a SHA read came back empty, and
`gh run list --commit ""` then listed every run in the repository, exit 0, with a plausible green
row for the branch in question. So check the value's *form* before it filters anything, and check
it against what it should be rather than against emptiness — a 40-character test refuses the
truncated reads and error strings that `-n` accepts — then confirm it from a second source, here
`git ls-remote`. **Do it unconditionally**: a guard reached for on suspicion is absent wherever the
failure is quiet.

**A negative needs a positive control.** This is the sharpest rule here. A wrong positive gets
argued with by the thing it names; a wrong negative simply agrees with whatever you already
suspected, so nothing pushes back. Before an absence decides anything, run the same probe
against a value you know is present. A misspelled config key, a build target matching no rule,
an alternation mangled by quoting — each returns the empty result that means "not there", and
each agreed with the defect being investigated and went on agreeing after it was fixed.

**Some instruments could not have gone positive at all, and care does not recover the
difference.** *A negative needs a positive control* treats the control as a check on a probe
that might be broken. The sharper case is a probe that is written correctly, run correctly and
read correctly, whose answer was fixed before it ran: no state of the world reachable from where
it was pointed would have made it say anything else. Reading it more carefully returns the same
reading, and each of the three below was run by a session applying these rules correctly in the
direction it was looking.

- **An assertion whose two endpoints cannot move relative to each other.** A suite asserted an
  ordering on two needles the function emits whether or not the mechanism runs between them, so
  deleting the mechanism left it green. Anchor on a marker only the mechanism itself emits.
- **A green the instrument reports *in order to* report the absence.** A workflow whose heavy job
  skips while its `-gate` job passes concludes `success`, so at run level "ran and passed" and
  "correctly skipped" are the same row by construction. `--commit` fixes *which commit*, which is
  why it reads as the guarded form, and says nothing about *which job*.
- **A probe fired where the code path had already emptied its subject.** A search of a captured
  file for a string returned 0 hits from a point after the script had exited without writing it,
  so the file was empty for any string.

So before a zero or a green decides anything, name the state of the world that would have made
this instrument say something else, and go and put it in front of it: the string where it is
known to be, the tree with the mechanism deleted, the job whose skip you can already see. Where
no such state exists at the point the instrument is aimed, the reading is not weak evidence —
it is none, and the fix is a different instrument rather than a closer look.

Where the instrument is right, the missing state is an input you build. Name the input that would
make the check fail, then look for one in the population: cannot name it, and the check is not
scoped yet; named and absent, build it, or the run is a tautology. A `git cat-file --batch` parser,
which fails by shifting offsets rather than by erroring, agreed with a per-file walk on all 260 rows
of a tree holding no empty blob, where size arithmetic off by one shows, and no two paths sharing a
blob, which misaligns a reader that de-duplicates its input. Three lines built both. The
differential stays the right move; this question is what finishes it.

**An empty result from a filtered query is a fact about the filter's subject before it is a
fact about the query.** *A negative needs a positive control* covers the query that could
never have matched — a misspelled key, a build target no rule builds. This is the query that
would have matched yesterday: the search worked, the object is still there, and a predicate
moved underneath it. Both return the same nothing, and the mechanism reading is the
interesting-sounding one, so it is the one that gets drawn. A `gh pr list --state open` search
came back empty and was read as a search-index lag; the PR had merged minutes before, and one
command against the object rather than the query, `gh pr view <n> --json state,mergedAt`,
settled it. The shape is any filter that can move while the object sits still — a time-windowed
log query, a status-scoped API call, a `--since` that has passed the event.

**A control has to vary the cause you suspect, not the term you happened to type.** The
session above did run one: it searched a distinctive phrase from the same PR's title and got empty
again, and read the second zero as confirmation. Both queries carried `--state open`, so the
control re-ran the failing filter with a different word inside it and could only ever agree.
Vary the suspected cause — here the state scope, never the search term — and where the
hypothesis was already in mind when the probe ran, treat that zero as the one owed a second
reading. An empty result is consistent with the explanation you arrived with, which is what
makes it easy to read past rather than explain.

**A control drawn from inside the enumeration it is testing cannot fail.** *A control has to vary
the cause you suspect* is satisfied, on a literal read, by a control that varies a *member* of a
list when the *list* is what you doubt. A sweep for `gh` invocations across a repo's workflows
matched `gh\s+(pr|api|issue|repo|release|run)` and missed `gh attestation verify`; its positive
control injected `gh pr view`, whose `pr` is already inside the alternation, so it proved the
pattern worked for what the list already covered and was structurally incapable of showing the list
to be incomplete. Any probe keyed on a table of known values has this shape — a per-command table
deciding which token is a path, an extension allowlist, a set of recognised error strings — and the
control has to come from outside the table: an input you know the subject accepts and the table does
not name. The asymmetry is what makes this worse than forgetting a control: a missing one is
visible, and this one *passes*.

Where the table is an index the probe built from its subject, outside the table is not far
enough. A probe of which skill rules reach sessions keyed each rule on word sequences unique to it
within the body, and its self-test fired those markers at the text they came from — so it passed
on a build reporting 43 of 93 rules unmeasurable, the most-cited among them, because the
uniqueness filter had removed exactly the phrases readers write. That control checks the
derivation and is silent on whether the right thing was derived. Take the known positive from the
world rather than the artifact: `positive control` appeared in 73 of 85 reader sessions, and
re-keyed on rule leads, that rule topped the table.

**A control must exercise the needle itself, somewhere it is known present.** *A control drawn
from inside the enumeration it is testing cannot fail* is about a control whose *input* was too
weak; this is one whose *pattern* is. A neighbouring string in the same region establishes that
the file and the section are reachable and nothing more — a line wrap, a smart quote, an em
dash, a case difference each break the needle and leave the anchor matching, so the control
passes while the probe stays broken. A clause wrapped mid-phrase returned empty from a
single-line grep at three commits, two of which carried the text, while a neighbouring-string
control matched at all three. The interpretable form runs the same pattern over known-present
cases: a row where the line-grep is False over text that exists convicts the probe rather than the
file, and without one there is nothing to read the absent case against. History usually supplies
the known-present case for free — an earlier commit carrying the string. Where it does not, plant
it and confirm the probe finds it before trusting any zero.

**A census that returns nearly its whole population is evidence about the predicate.** *A
negative needs a positive control* sends you to a known-good input before believing a zero. The
same control is owed before believing a near-total, and nothing prompts it, because a near-total
reads as a major finding where silence reads as an absence. The tell is not that the number is
large. It is that a predicate mismatched to the shape the data normally takes fails on **every**
instance of that shape, and the normal shape is most of the population — so a mismatched
predicate is the one cause whose hit count scales with the population, while a real defect
distribution is scattered by construction: some instances rot and most do not. A census over every `path:N:fragment` citation in a backlog store reported 16 of 19
stale, three of them citations the same session had re-pointed and verified by hand an hour
earlier. The predicate asked whether the fragment *started with* the line rather than whether the
line *contained* the fragment, so it failed for every citation whose fragment sits mid-line,
which is most of them. The control was already in that session's own history and cost one
command: run the census over the inputs you have personally verified before believing what it
says about the rest.

**Uniformity across inputs you varied is a finding about the instrument, whatever the answer is.**
*A census that returns nearly its whole population* is one instance of a wider shape, and reading it
as being about censuses leaves the shape unnamed: a probe returning the *same* verdict for every
input you deliberately varied has told you about itself rather than about the inputs. A zero and a
near-total are the two variants that get looked at, because both read as results; a uniform
plausible-looking answer is the one that gets used. Three mechanisms produce it. A `case`-based
shell harness whose `case` was the script's last command, so all four shapes inherited its status
and returned `rc=1` — the variant to lead with, because it produced a wrong answer rather than a
false clean. A three-dot diff against an ancestor: `git diff origin/main...origin/main~1` is empty
by construction, the merge base *being* `main~1`, and the form that answers is
`origin/main~1...origin/main`. And two fixtures whose mutation landed and was then neutralised
downstream by a rule that is itself correct, so they passed against every implementation variant. So
when the answers stop varying, stop reading them: fire the probe at a case whose answer you already
know, and where no such case exists, build one — the ref sweep above was cleared by constructing a
diverged branch for it to find. A real population is scattered by construction. The instrument is
what can be uniform.

**A control tests the probe's logic and says nothing about whether its input is current.**
*Uniformity across inputs you varied* sends you to a case whose answer you already know; a probe
over a cache passes that while answering about a stale world: the remedy fires, passes, and licenses
the wrong answer. A ref sweep's control fired while `git branch -r` listed 19 refs against 4 real
remote heads. Ask the remote (`git ls-remote --heads origin`); a tracking ref reports the last
fetch.

**A zero for a category is refuted by the mechanism that would produce it, and that check
is free.** *A negative needs a positive control* needs a control run; this one needs only a fact
already in front of you. Before a count of zero becomes a finding, name what would have had to be
dead for the category to be empty, and look for it in your own output. A census of `permissionDecision` records across six Claude Code guard plugins returned `allow` and
`ask` and no `deny` at all — printed in the same session as a list of the six `*_OVERRIDE`
variables those plugins ship. An override exists to lift a deny, so the result carried its own
refutation and was read as a finding anyway; denies were arriving by a channel the probe never
sampled. The tell is a zero that would require a whole documented mechanism to be vestigial.
Where a zero survives that reading it has earned the positive control; where it does not, the
probe is already known to be wrong.

**A step that narrows a population reports both sizes, or its result is unreadable.** *A zero
for a category is refuted by the mechanism that would produce it* is answered from a fact already
in hand, and *A negative needs a positive control* by a second run. This one needs neither: print
how many records the step reached and how many survived it, so a zero over a population the
narrowing never entered is distinguishable from a zero over one that is genuinely empty. Do it
**wherever the narrowed result is about to decide something** — not everywhere, because a repo
narrows a population in most of its pipelines, and a rule firing on all is dead in a day.
`wc -l` either side of the step, or the count beside the verdict, catches it in the same command
that introduces it.

A *broken* narrowing is the easy half: a transcript scan reported `inbound peer messages scanned:
0` beside its `hits: NONE`, because a type filter had skipped every record. The two zeros want
opposite fixes — an unreached population indicts the filter, a reached one settles the absence.

The hard half is a narrowing that is *correct*: the dedup is right, the flag is right, and it
removes what the reading needed anyway, so re-reading finds nothing. A checker that printed a fixed
line on zero findings and never said how many pull requests it had examined was byte-identical over
twenty and over none, and a workflow closed its tracking issue on that line. A `sort -u` over a
link-label key dropped one of two rows sharing a label, which was exactly the substitution the
comparison existed to catch; key on label plus path, keep duplicates, and `comm` both directions.
The wrapped-prose grep and the `--state open` filter above are this rule with the narrowing living
in a pattern and in a flag.

**Where it stops: a reference that moved is not a population that shrank.** Printing both sizes
would not have caught this one. A session reconciled a branch's rows against `origin/main` as a live
ref rather than against the branch's own merge base, got two spurious extra rows, and was one
message from reporting a fabricated defect in a peer's rebase. Both readings were correct when taken
and nothing narrowed, so the fix differs: pin to a SHA or to `git merge-base` before anything
compares against it. And `origin/main` does not go *stale*: `refs/remotes` lives in git's **common**
dir (`git rev-parse --git-common-dir`), not the per-worktree one, so in a clone carrying many
worktrees and sessions it is shared mutable state owned by other processes, and it can change
between two of your own commands while you run nothing. Which fetch forms move it, and the two
measurements behind that: [`references/shell-traps.md`](references/shell-traps.md).

**A comparison validated in one state is silent about the others.** Where a change must hold in
several trees, each is a different left operand, and a probe correct in the one you ran comes back
clean there and says nothing about the rest. A citation audit run against a stacked branch's head
rather than the PR's base returned three confident misses where all four citations resolved against
`main`; three branches each run through `git merge-tree --write-tree origin/main` came back clean,
correctly, for a set that still conflicted, because the first merge moves the line the second cites.
Ask which states the thing must hold in, and build a merge sequence in order. A ref handed over in a
message is re-measured before it becomes an operand: *#179's ancestry reaches `b9d91ae7`* was true,
and was used as a diff base where the merge-base `dbd19eb4` was needed.

**One response, two causes — and a positive control cannot separate them.** *A step that narrows a
population reports both sizes* catches a probe that is broken. This catches a probe that works
perfectly and answers a narrower question than the one being asked. `gh api repos/<o>/<n>/pages`
returns the same 404 for "no Pages site is configured here" and for "this account cannot have one on
a private repo", and the first reading is the one that agrees with wanting to build on it. Running
the probe against a repository that *does* publish returns 200 and confirms the probe works, which
is exactly no help. So when a result is about to decide something, name the readings that produce it
and pick a probe that separates them — `gh repo view --json visibility` answers the second question
and could not have answered the first. The tell is that the response was consistent with the
hypothesis: a result you expected is where a second cause goes unenumerated, because nothing prompts
the search. The same shape has a ready-made fix, and release or merge-policy reasoning runs into it:
`gh api repos/<o>/<n>/branches/main/protection` answers *does the legacy API hold a record*, not *is
this branch protected*, so on a repository moved to rulesets it returns `404 Branch not protected`
where `gh api repos/<o>/<n>/branches/main --jq .protected` returns `true`.

**A probe's setup step can silently define what its teardown restores to.** *A step that narrows a
population reports both sizes* and *One response, two causes* are about a probe that is broken and
one that is sound but narrow. This is a third: the probe is sound, the question is right, and the
*baseline* it compares against is the previous run's output rather than the original state. The
second measurement then reads the first. Testing whether a linter's escape hatch works, a setup
staged the tree with `git add -A`, so the later `git checkout -- <file>` restored from the index —
which already held the planted defect — and the "reverted" file still carried it. The probe reported
the escape hatch failing on a line that was never the exhibit. Nothing errored, and a revert that
does not revert is reported by nothing.

The shape is wider than reverts: a baseline copied *after* a mutation, a fixture generated once
and reused across cases, a temporary directory not removed between runs. Each makes run two a
reading of run one, and the direction of the error is unconstrained — here it manufactured a
failure, but the same setup can as easily manufacture a pass.

What makes it expensive is standing: a probe is trusted more than the thing it measures, so its
artefact arrives as a finding *about the code*, and the probe above appeared to have found a defect
of exactly the class the session was already working on. So re-derive from a fresh baseline rather
than a restored one — extract the tree again, use a new directory, append rather than
plant-and-revert — and treat agreement between two runs sharing a setup as one reading, not two. A
benchmark control fails the other way: it licenses comparing two arms only from inside the same
process, because across two sittings it moves with the machine, and one lane's two separate runs
read as a 2× regression while its control arm had itself dropped by half. Compare runs only where
their controls agree, and say that they do. A mutation of state you share needs its undo armed
*before* the mutation, not appended after it; measure in a throwaway clone in the session scratchpad
where you can.

**One field is a projection of a mutable object, and several of its states project onto the same
value.** Read straight after a push, `gh pr view <n> --json headRefOid` returned the pre-push SHA
— which is what you would see if the push had failed, and equally what you get once the PR has
merged, because a merged PR's `headRefOid` is a stored value that stops following the branch. (It
still reports a SHA for a branch the merge deleted; `git ls-remote` finds no such ref.) The field
that separates those two states is sitting in the same object, so the fix is to widen the read
rather than to take it again — `--json headRefOid,state` costs one word and returns `MERGED`.
Before a field decides anything, ask which states of the object project onto the value you got,
and read a field they disagree on in the same call.

**The far end of an instrument can be sick, and it answers in the shape of a finding.** Three
readings can settle the same way and all be wrong. `gh run list --commit <sha>` returned `HTTP 404:
Not Found` for three PRs, which reads as *no runs on this commit* — indistinguishable from the
path-gated workflow that silently skipped, a real hazard and the reading you would go and chase; `gh
pr checks` on the same PRs returned four passing jobs each. Later that day GraphQL answered HTTP 503
where the REST pulls endpoint answered normally, twice within an hour. So the move is *Re-reading an
ambiguous output cannot disambiguate it* pointed at a remote: **a different endpoint on the same
data**, not a retry. Retrying is the obvious advice and the weaker one, because it re-reads the sick
instrument, and the sickness clears on the platform's schedule rather than yours.

**A status page starts an investigation or stops one; it cannot clear the instrument.** Read it
before spending one — in the first of those incidents it named Actions and API Requests degraded
and stopped a wasted search. But its evidence is asymmetric: red on the component you were using
is a finding, and all-green is not a clearance, because the tail of an incident is exactly where
the page reads clean. Read it per *component* — a blanket "the platform is down" over-attributes
exactly as badly, and the one-line blended indicator is the wrong reading for that — then treat
even a component read as insufficient and settle it on a second endpoint. Over-attribution runs
the other way too: in that same session a `git fetch` failed with git's stock `Please make sure
you have the correct access rights and the repository exists`, the incident took the blame, and
the cause was local. Treat a reading from a degraded component as unverified and a failure on a
healthy one as your own — a status page that disagrees with your theory is a finding, not noise.
Both incidents in full, the pages and their per-component JSON, and how to find one for a
provider not listed: [`references/status-pages.md`](references/status-pages.md).


**The shell is an instrument too, and it fails in the same shapes.** Every rule above assumes the
command you wrote is the command that ran. Often it is not: a pipeline hands back its filter's
status, `PIPESTATUS` is empty in zsh and reads as success, a `$var:` followed by a colon expands
as a modifier and mangles the path, an unquoted glob dies before the search starts, `grep -c`
counts lines rather than matches, and BSD `sed` on macOS accepts a GNU pattern, matches nothing
and exits 0. Each returns a well-formed result that is about a different question. The mechanics,
with the invocation to use instead: [`references/shell-traps.md`](references/shell-traps.md).

**A failed read hands its error to whatever consumes the read.** *The shell is an instrument too* is
about a command answering the wrong question; this is one that answers nothing and has the refusal
recorded as data. `git show <commit>:<path> > f 2>&1` on a path absent from that commit writes
`fatal: path '<path>' does not exist in '<commit>'` into `f` and exits 128, so a reviewer
establishing whether a file is identical on two commits by extracting both and running `cmp`
compares an error message against real content. It reports *differ*, which is the expensive shape: a
plausible refutation of the claim under test rather than a check that stopped, so it changes a
verdict instead of raising one. Compare ids instead — `git rev-parse --verify <commit>:<path>`
returns the blob id, and a missing path is an error rather than a value, so there is nothing for the
comparison to make a verdict out of. Keep the `--verify`: the bare form echoes its own argument on
stdout, which compares unequal exactly as a difference does.

**A count asserts a population and a scan width.** Both go stale the moment the tree moves, and
a scan you ran earlier in the session for another purpose does not transfer — re-derive the
number as you write the sentence, and say what population it is true of. Specifics:

- **A round total is a truncation until shown otherwise.** Paginated APIs answer with one page
  and still exit 0, so a query whose answer is a list quietly becomes a query about its first
  hundred entries. An exact 100, 30, or 1000 is the tell; an empty grep over that page is a
  correct search of the wrong population, which reads as a clean negative rather than an error.
- **An aggregate counter cannot count distinct participants.** `retries >= 3` is a claim about
  how many times, not how many actors — one actor in a loop satisfies it alone, and the looping
  actor is usually the fast path, so the threshold clears before the shape it names occurs. Give
  each actor its own counter and count the actors that moved.
- **A count grouped by symptom is not a measurement of cause.** A tool groups by whatever its
  normalizer could see, which is seldom what shares a mechanism. Re-derive along the axis the
  claim needs — time, construct, actor — and when the claim is causal, exercise the system that
  would produce the effect rather than counting records that correlate with it.
- **A total is bounded by what the instrument observes, and an event it never saw leaves no
  gap.** Establish the blind spots before quoting the number, because nothing in the output
  will. Quote a total with the shape it cannot see named beside it.

**The measurement that justifies a change is taken on the tree without the change in it.** *A count
asserts a population and a scan width* has a number going stale because the tree moved; this is the
case where your own branch is what moves it, so a census taken to argue for a diff is falsified by
that same diff, and the two readings are a rebase apart. Nothing marks the difference and nothing
can go red: a gate reads the tree, while a number already written into a document is prose. Seven
figures went stale under one worker across five rebases with `make check` green through every one —
a suite count, a store total that moved 54 → 53 → 54 → 55, an invisible-citation total, a documented
highest ID — and one census was re-invalidated by its own thread three times before it landed.
Re-derive every figure against the head you are about to publish from, and where a figure counts a
population your own diff edits, say which side of the change it is true of.

**A measurement of recent activity, taken while your own work is changing that system, samples
your own work.** Everything else here has something wrong with the instrument. This has nothing
wrong with it — the scan is complete, the query is right, the figure reproduces — and the
population it drew from is you. That is why it survives the checks that catch the rest: a
reviewer re-runs the query, gets the same number, and agrees, because the agreement is about the
number while the defect is in what the number was *of*. In one repository, of the 60 most recently merged pull requests, 7 still had their branch and 53 did not, splitting
cleanly by recency. Two sessions reproduced it independently and it shipped as evidence that
merged branches are pruned eventually rather than at merge. Nothing there prunes at all. The 7
were the 7 that evening's own coordinator had merged, with a command that had stopped passing the
delete flag.

**A population read off the failure list is missing every case that recovered.** The bullets
under *A count asserts a population and a scan width* are all about the instrument — what it
never saw, what it grouped by, how far it scanned. Here the instrument has no blind spot: it saw
every case, and the count was taken from a view of its output that outcome had already filtered.
It is survivorship bias backwards — the survivors are absent because you are reading the
casualty list, and every case on that list is real. A finding about peers addressed by the title
of the task chip that started them was derived from the listing of messages that never landed,
which is filtered to the terminal failures, and found three. Re-derived from the address-form
classifier, which sees every send, the class had six members across five sessions. The three that were missing had
been retried under a real name and so never entered the casualty list — and they are what shows
the failure is usually recoverable, which is the half that decides what the rule should say.

Two things make it expensive. The finding survives a re-read, because it is true and merely
smaller — three of those sends really were abandoned. And it is invisible to review: the diff
carries a clean finding rather than a missing half. Neither a wider scan nor a second run of the
same query reaches it, since both re-read the same filtered view. What reaches it is re-deriving
the population from a different starting point — the instrument's own unfiltered output, or a
second instrument that sees the whole set — before the number decides anything.

**A local gate disagreeing with CI indicts your toolchain first.** CI builds its tools fresh
from the pin; your build directory holds whatever it held last time. A stale binary takes no
flag it does not know, prints plausible output, and names real files — nothing about the run
looks wrong. Rebuild and re-run before reporting anything about the repository. And a repeated
claim gains authority without gaining evidence, so the second and third restatements are the
expensive ones.

**A suite result is only valid for the tree state that held for the whole run.** *A local gate
disagreeing with CI* and *A failure on your branch is not yours until the base fails too* hand a
red result to somebody else — your toolchain, or the base. This one hands it back,
and not through the change under test: a file written while the suite runs is read half-written
by whatever executes next. A gate started in the background and an edit made while it ran is the
ordinary shape, and neither step feels like it touches the other.

How far the corruption reaches is decided by how the suite loads the subject. An imported module
is read once at import, so an edit after that lands in the next process. A helper that spawns the
subject as a **subprocess** re-reads the file from disk on every call, so a mid-run write breaks
whichever case happens to run during it: comment edits made while `make check` ran in the
background failed one unrelated test with `SyntaxError: '(' was never closed` inside its assertion
text, and the settled tree passed.

It misleads in two directions at once. The result is red, so *could this have shown me the
opposite?* answers yes and the failure passes the check that catches most of this section. And it
names an innocent test — whichever one ran during the write — so the obvious next move is to
debug code that was never wrong. The tell is a syntax or import error arriving inside a test
assertion rather than as a collection error: a subject the suite never imports cannot fail
collection, so its unparseable state has nowhere to surface but whatever case was running. So
before believing a failure, ask whether anything under test was written during the run; before
starting an edit, ask whether a suite is in flight. Where both already happened the run measured
nothing either way, and only a re-run over a settled tree replaces it.

Also in this section, in [`references/further-rules.md`](references/further-rules.md): *A completion
predicate must key on what ends the run, not on a string that appears in it*; *An approved
permission prompt leaves no trace in the result*; *A correct reading of the wrong field is a wrong
measurement with nothing defective in it*; *Re-reading an ambiguous output cannot disambiguate it*;
*A capability is a claim, and it is load-bearing before the design, not after*; *The tell is a
boundary that coincides with your own start*; *Two instruments pointed at one observable are one
instrument*; *One observation is not a steady state*; *A failure on your branch is not yours until
the base fails too*.

## 2. Trusting a check

**The probe is not the gate.** A hand-rolled stand-in answers a slightly different question and
its answer looks exactly like the real one: a raw `grep -c` where the gate excludes code spans,
a bare linter where the gate passes a flag that follows sourced files, a cached test result
where the change touched a file the cache cannot see, an anchored search for a check name that
misses `integration-test` because it matched on `^integration`. When a probe's answer is about
to decide something, run the gate. When the gate is too slow for the loop, keep the probe but
give it a case whose answer you already know, and disbelieve it when the two disagree.

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
[`references/shell-traps.md`](references/shell-traps.md).

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
`merge-tree` consult; what quantity does this reading measure, on what hardware, at what ratio;
what is in the cited file. An *over-sourced* citation is the one that gets through: a real file
with a real number trips none of the reflexes tuned to flag thin sourcing. A hedge rescues none
of this: it sits on the inference, and the error is upstream in the probe. Both halves of the
sentence are written in the same words, so ask what this instrument would report if the claim
were false **in a way it cannot see**.

**Being right by luck is indistinguishable from being right by construction.** An instrument
answering an adjacent question often returns the right verdict anyway, and nothing in the agreement
marks it. That is a different argument from *a negative needs a positive
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

Also in this section, in [`references/further-rules.md`](references/further-rules.md): *Agreement
with the enforcer is not evidence when one detail could fool both*; *A measurement that reproduces a
call is not a test of the code that makes it*; *The checker is a fourth subject, and that check
cannot count it*; *Two causes that predict the same count are not distinguished by that count*.

## 3. Writing a check that can fail

**Delete the mechanism.** The only way to settle "this code causes that outcome": remove the
mechanism, require red *for the reason you expect*, restore, confirm green in the same sitting.

- Delete the mechanism, not the assertion. Removing the assertion proves nothing.
- Delete one mechanism, not the branch around it. A deletion coarse enough to redden every
  assertion has measured only that the path is reached.
- Where a change can fail in two directions, too strict and too permissive, mutate each. Reverting
  an order-independent compare to the exact-string one reddened the headline test and made the
  function *stricter*, so it never showed the controls guarding the *permissive* side could fail;
  replacing the body with a constant `()` reddened those too. The skipped direction is the one the
  headline test does not point at, and a control is one only once some mutation has reddened it.
- Read the failure, not the colour. Red from a compile error is not evidence.
- Key the mutant run on the assertion's own report, not the suite's exit status. A suite exits
  non-zero whether your assertion caught the defect or the run died before reaching it. Require
  both — that assertion's own pass line absent, and its own failure text present; absence alone
  passes a defect destructive enough to abort, since a traceback suppresses the pass line exactly
  the way a catch does.
- A green after deletion can mean the assertion cannot see the defect class, or that a redundant
  guard upstream is standing in — not that the mechanism is dead. Ask what the assertion actually
  observes, and what *other* code is keeping the test green.
- Size the fixture to the threshold. A test for a cap written with an input far from the
  boundary passes either way and pins nothing.
- The mirror, for a gate: inject the defect it is supposed to catch. Reading the matcher only
  predicts the answer; a regex is exactly the kind of thing that looks like it covers a case it
  does not.

**An escape hatch is a code path, and it is the arm the falsification skips.** A waiver comment, a
skip flag, an allowlist entry, an override variable — each settles the gate's verdict as surely as
the detector does, and each is the arm its author exercises least and a reader in a hurry reaches
for first. The asymmetry arrives as a shape rather than as a gap anyone would notice: a fenced-code
gate here mutation-tested every detection arm, and gave its waiver one happy-path assertion in the
single construction its author had written. The waiver broke on first contact with somebody else's
spacing — the check read the line at `start - 2`, so a comment separated from its fence by a blank
line was never looked at, and the gate stayed red with nothing saying a waiver had been seen and
rejected.

**What made that unfalsifiable rather than merely untested was the failure message.** It told the
author to waive the block with a comment *above the fence*, and a comment one blank line up is
above the fence — so the text did not under-specify the behaviour, it described a gate that had not
been written. A happy-path assertion cannot catch that, because the happy path is the one case
where the sentence and the code agree. So derive the hatch's cases from the message's own words
rather than from the branch you wrote: every construction a reader following that sentence could
produce is a case, and each one needs an arm. What skipping them costs is not a red gate, which is
loud, but a silently unusable hatch — and a waiver nobody can make fire gets routed around, after which the waivers that do exist stop carrying reasons.

Both arms need a control, for the reason *size the fixture to the threshold* gives above. Against
a fenced-code gate of my own:

```bash
q='```'                       # keep the fence marker off the start of a line
prog=$'import os\nx = 1\ny = 2\nz = x + y\nprint(os.getcwd())\nprint(z)'
printf '%s\n' '<!-- check-fenced-code: worked example -->' '' "${q}python" "$prog" "$q" > gapped.md
printf '%s\n' '<!-- check-fenced-code: worked example -->'    "${q}python" "$prog" "$q" > adjacent.md
printf '%s\n'                                                 "${q}python" "$prog" "$q" > control.md
for f in control adjacent gapped; do
    scripts/check-fenced-code.py "$f.md" >/dev/null 2>&1; echo "$f=$?"
done
rm -f control.md adjacent.md gapped.md   # untracked *.md is in the gate's own list
```

`control=1` is what makes the other two readable. A fixture one statement under the gate's
five-statement threshold reports `control=0` beside them, which reads as *the waiver is honoured
in both constructions* off a run where the gate found nothing to waive. Both waiver arms pass
here now, and the suite has grown arms in both directions — the gapped form, a comment behind
prose it must not reach past, one carrying an indent, and mentions of the syntax that must not
waive at all. That is what a falsified hatch looks like, and the probe is how you check yours is
one.

**A test that supplies the value the mechanism would have supplied tests nothing.** The mutation
runs, the mechanism is genuinely gone, and the assertion still passes — because the test handed
the code the answer on the way in. Testing a default by passing the value explicitly, a fallback
by providing the primary, or an inference by stating the thing to be inferred all have this
shape, and all of them look like ordinary careful test-writing. A wrapper meant to supply a
default output path was covered by a test that passed `--out` on every call; deleting the default
left the suite green. The check is to read the invocation and ask which argument the mechanism
exists to produce, then stop passing it. Copying a neighbouring test's invocation is how the
extra argument usually arrives, so a suite where every case is set up identically is where to
look first.

**An assertion fed only values the subject already validated cannot fail.** *A test that supplies
the value the mechanism would have supplied* has the test handing the subject an answer; this is the
same trade running the other way, with the subject handing the test one. Where the code under test
checks its own inputs, every value it gives back has been through that check one call earlier, so a
value that would fail your assertion raises *inside* the subject instead. The assertion re-runs a
check that has already run: it reads as a guarantee and is a tautology. This is not a sampling
weakness a wider fixture would fix — the argument holds for every input the assertion can see. A
suite asserting that every key a sort-key allocator generates satisfies the key checker read only
keys it had fed back to the allocator, which checks them, so an illegal key aborted the run before
the assertion ever saw one. The repair is to find a value the subject has not already approved, such
as output written straight to the store and never fed back.

**Repeated passes do not validate a flake fix.** A green run of twenty is equally consistent with
"the race is closed" and "the race did not fire" — and on an idle machine the second is more
likely. Invert the fix and confirm the suite fails. A fix you cannot make fail on demand has not
been shown to be load-bearing. When the inverted form refuses to fail either, that is the
finding: the diagnosis is wrong. And one red does not settle an inversion, which fails worse: an
expected red is the one result a spurious failure flatters, since a flake delivers exactly the
observation you wanted. Where the subject involves concurrency, timing, ordering or a claim of
intermittency, sample until the distribution stops moving and report the ratio, not the verdict.
A test said to pass with its watch deleted went red once on that mutant and the claim was
dismissed; ten runs gave 9 FAIL and 1 PASS, which confirms it — vacuous one run in ten is vacuous.

**A negative assertion must be able to fail for only one reason.** "It didn't fire" passes when
the mechanism is absent, and equally when it is present but misdirected, misconfigured, or
erroring out early. Pair it with a positive assertion somewhere in the suite — if nothing asserts
the mechanism *works*, the negative is unfalsifiable. Prefer asserting the specific wrong thing
did not happen over asserting nothing happened. And a poll or sampler bounds how often something
was *observed*, never whether it *happened*.

**A negative control that an empty run satisfies is not a control.** Deleting the mechanism and
asserting the number goes *down* leaves a second way to pass: a mutant that fails outright
produces nothing, and nothing is fewer. One such control fired eight allocators at once against a
version whose reservation step had been removed, and asserted the fleet took fewer than eight
distinct ids; the broken allocator emitted zero, which cleared the assertion while showing
nothing about the reservation. Assert the floor as well as the ceiling, and report the empty
case as the control having failed to run rather than as a pass. The shape is general: any
conclusion resting on *lower*, *fewer*, or *absent* than a baseline is satisfied by a run that
died before producing anything. This surfaced by accident, because an unrelated bug produced
zero on the *positive* case too; had the mechanism worked first time, the vacuous branch would
have shipped green and stayed green.

**A containment test is satisfied by the needle your own change emptied.** `needle in
haystack` reads as asking whether the thing is still there, and it answers True for every
empty needle — so a probe checking that a quoted excerpt still appears in the file it
quotes passes for a *deleted* quote as readily as for a correctly trimmed one. It is *a
negative control that an empty run satisfies is not a control* arriving on a positive: the
degenerate output clears the predicate rather than failing it, and the reviewer who named
that failure mode in prose then shipped a probe that had it. So assert a quantity that
moves with the repair — a length, a line count, a match position — alongside any test
whose empty case is a pass, and reject an empty needle before comparing.

**A mutation is confirmed by reading the file it mutated, not by the exit status of the
command that wrote it.** A control breaks a checker's input and demands red; where the break
silently fails to land, the checker sees clean input, passes, and the control reports green —
testing nothing, and reading exactly like a control that worked. The tool fails more quietly than
the logic does, because a flag the installed binary rejects, or a GNU pattern under a BSD one,
leaves no mark on the control's own status: under BSD `sed`, `sed -i 's/…/…/' file` takes the
expression as a backup suffix, so a mutation driven that way never applies and its arm comes back
green. Assert the file actually changed before reading the arm. And a green arm is evidence for
whichever hypothesis predicted green, including the one you were already drafting.

**Generate a fixture with the producer's own code.** A hand-written fixture encodes what its
author believed the producer emits; when that belief is wrong it is wrong in the same direction
as the parser written beside it, so both agree and both are wrong. Escaping, quoting, numeric
precision, field order, and null-versus-absent are where memory is unreliable, and all five fail
silently.

**Adjusting a fake to make a test pass is a finding about the real interface.** Teaching the stub
to send the missing field is one line and always works — and the suite stops describing the
system and starts describing itself. Ask what the real service sends, and get the answer from a
capture or a live call, not from the code under test. Two worse variants:

- **Omission.** When a stub does not model a piece of state at all, the bug class is not merely
  untested, it is unrepresentable, and nothing ever points at the gap. The tell is a defect report
  describing state your suite cannot express.
- **The interface grows a call the fake answers anyway.** A fake that replies to every path alike
  is modelling an interface with one call. Add a second and it answers that too, in the shape it
  was written for. Route by method and path the moment there are two, and fix the fake rather
  than raising the expected numbers.

**An assertion against live state must keep its subject's output.** Against a fixture, the failure
can only be the condition asserted, so a fixed message is fine. Against a mutable tree or a real
service, it can be a missing directory, an unreadable file, or something transient — capture the
output and exit code and print both. "Re-run it yourself for the report" is not a remedy: in CI
nobody is at that shell, and a transient cause is gone for good on the green re-run.

**Derive a backstop from the subject's own budget.** A flat timeout picked as a round number
beside the subject's configured waits can expire *inside* the window the same test just
configured. Bind the two to one variable so they cannot drift, and say in the failure text which
of "wedged" and "slow" the reader is looking at.

**A bulk mechanical change proves itself by reconciliation, not an empty leftover query.** Grepping
for the old form and seeing nothing cannot distinguish "no sites remain" from "my query never
matched" — and the rewrite and its verification are usually written minutes apart from the same
wrong mental model, so they fail together. Three checks, and the first is the one that catches it:

1. A positive control — name one site you know must change and assert it did.
2. Reconcile counts. "762 rewritten" means nothing; "762 rewritten, 762 found beforehand" is the
   claim worth making.
3. Take the baseline with a query spanning every shape the change touches. Two numbers from the
   same too-narrow query agree while the sweep is half done.

Then note which way reconciliation runs: it accounts for what was *removed* and is blind to
anything the change *added*. That is the whole content of a mechanical rename, so the three checks
settle it. It is not the whole content of a prose edit, where an invented connective can change
what a sentence refers to while every count reconciles.

**A throwaway harness is a measuring instrument.** It is written without the checks the suite
itself would get, and every failure mode produces a confident wrong verdict: the load never
started, the cleanup killed the thing being measured, the oracle misclassified real samples, or
the subject changed mid-run because you kept working. Assert the harness's own preconditions,
print the raw figure it measured, and freeze the tree for the duration.

**A check with one binary outcome cannot report that you were right for the wrong reason.** *Delete
the mechanism* settles whether a mechanism is load-bearing; this is what to ask for when somebody
else runs the check. *Is this real?* comes back yes and stops, leaving whatever mechanism was
asserted beside the defect unread — and the mechanism is the half a fix gets written against.
Separate the existence of the problem from the explanation of it, so the run can disagree on either
axis independently: a run told to "re-derive independently, and file nothing if it refutes" came
back confirming the defect and refuting its stated mechanism. Ask for the mechanism to be re-derived
rather than confirmed, and give the run somewhere to put an answer that is neither yes nor no.

Also in this section, in [`references/further-rules.md`](references/further-rules.md): *A mutation
aimed at a constant tests the constant*; *A payload chosen for being harmless is often exempt for
the same reason*; *A positive can be vacuous too*; *Assert the recovery property, not the mechanism
believed to deliver it*; *Probe the environment, never infer it*.

## 4. When the signal moves in time

Flakes, races, and anything measured under load. The move is the same, but the signal is not
stable, so "I ran it again and it passed" is not the check it looks like.

- **A rerun that passes is half the evidence, not a dismissal.** Where attempts are kept
  separately, one run holds a failing and a passing log over the same commit — a controlled
  experiment already run for you. What the failing side contains and the passing side does not is
  usually one line, and it often reclassifies the fix before any code is read.
- **Wait on the same signal you assert on.** Two effects of one operation almost never land
  together, so blocking on the earlier and reading the later races a real gap that no timeout
  closes. Ask which component has to observe the state for the assertion to mean what it claims.
- **Time the unit alone before believing "under load".** Slow under the full gate and fast
  standalone is the load story; slow both ways is not.
- **Repetition shares process-global state.** A test asserting an absolute value on a global
  counter or registry passes once and fails from the second repetition on. The tell is the
  inverse of a flake's: any load, always at repetition ≥ 2, `actual = expected × count`.
- **A stress loop measures the host too.** Long single-process repetition exhausts ports, file
  descriptors, or pool slots far from the cause. Run the identical loop against the unmodified
  tree before calling it a second bug.
- **Never assert on wall-clock time you actually spent.** Stub the sleep and assert on what the
  stub recorded. A margin too large to plausibly elapse, elapsing anyway, is the tell that the
  assertion is not measuring the quantity it names.

Depth on all of these — synchronization gaps between participants and between cached and direct
readers, pinning a process whose signal comes out of its memory, virtual clocks, and calibrating a
throwaway load harness — is in
[`references/timing-and-concurrency.md`](references/timing-and-concurrency.md).

## 5. Explaining behaviour

An explanation offered to a reader is a claim, and it is the shape that escapes every check above,
because it is prose asserted from reasoning rather than read from anywhere. Before explaining why
a system behaved as it did, search the project's own record — the issue tracker, the plan doc of
the release that shipped it, the runbook. An explanation that contradicts one of them is the
finding.

- **A resemblance to a known issue is a hypothesis, not a diagnosis.** The same surface symptom can
  have a different cause each time. Take a direct measurement from the failing system before
  spending a re-run, a fix, or a state-changing command on the remembered cause.
- **A reproduction you built shows the symptom is achievable that way, never that it happened that
  way** — and the closer the match, the more convincing the wrong answer. Promote it to a diagnosis
  only on a reading taken from the failing system that no rival mechanism could produce.
- **Source reading tells you what should happen, not what does.** Treat findings derived from it as
  unverified until confirmed end to end. The elimination runs the other way and is decisive: where
  the source shows that the mechanism a hypothesis needs cannot exist, nothing has to be run, and
  that read is cheaper than the probe it retires.
- **A cause you can watch happening is still a hypothesis, and a real one does not crowd out a
  second.** This is hardest exactly when the first cause is genuine, concurrent, and sufficient to
  explain the symptom. Ask what else produces this exact output before closing.
- **Capture evidence before it is destroyed.** Re-running a red job replaces the view of the failure
  you are diagnosing, and the new attempt's empty failure set looks exactly like "the diagnostic
  never ran".

**Name what the probe would show if the hypothesis were false, before running it.** A probe aimed
at a hypothesis you have already accepted has its outcome pre-classified: the expected reading
confirms, and every other reading is noise. A symptom matching a postmortem in the same repository
is how a hypothesis gets accepted ahead of any measurement, so the probe runs as a formality and
its result is read to close the question rather than to decide it. Writing the refuting outcome
down first is what keeps the run legible, and for a causal hypothesis that outcome is always a
*change* — an outcome identical to the one being diagnosed is the refutation, not a null. A gate
reporting `ok` matched a postmortem about a stale build artifact; deleting the artifact and
re-running returned the identical `ok`, which was read as consistent with staleness when it was
the refutation of it.

## 6. Stating a fact nobody measured

Every moment above starts from something already in hand — a status, a count, a log, a system
misbehaving in front of you — and the move is to ask what that thing would read if the opposite
were true. A sentence resting on nothing trips none of it, and reads as background rather than as
a claim. Suspicion cannot be the trigger either, because the ones that bite are the ones nobody
was unsure about. What has to prompt the question is the claim's *role*: something is about to be
decided on the strength of a sentence, and nothing was ever read to write it.

**A pre-written form field hides the claim's role.** A checkbox in a PR template, a cell in a
status table, a bullet in a release note — each asserts something a reviewer then acts on, and
none of them reads as reporting a result, because the wording arrived with the template and
ticking it feels like completing paperwork rather than saying anything. `- [x] make check is
green` went out ticked without the run, on a PR whose entire subject was that self-attested boxes
are unreliable; a release note enumerating new tests named three that do not exist, written from
the code diff rather than from the artifact. So tick the box after the run, and
build an enumeration by reading the thing it describes rather than the change that produced it.
The document is where a claim gets consumed: a wrong belief held privately is corrected by the
next command, and the same belief in a PR body is what a reviewer approves on.

**A list asserts a symmetry its sentence never stated.** A sentence naming one mechanism and then
listing members lets a reader distribute the mechanism over every member. *Every handler returns
0 or 1 through `sys.exit(main())`, argparse contributes 2, and an uncaught exception contributes
1* is true, and its three members exit three ways: a return through `sys.exit(main())`, a
`sys.exit(2)` inside argparse with `main()` never returning, and CPython's top-level handler. A
later row compressed it into one cause and stated a false `because`. Checking each member does not
catch it — argparse genuinely calls `sys.exit`; what is false is the composed `sys.exit(main())`.
Check each member against the mechanism as written, at the granularity written, or move the
mechanism out of a sentence that covers several sources.

**An actor or author field names the credential, not the person.** Where someone and their agents
share one account, every action any of them takes is stamped with it — `actor.login` on a GitHub
timeline event, and the author of a commit, comment or review made through `gh`, report which token
was presented and nothing about who decided. `performed_via_github_app` is null for a CLI call, so
nothing in the API separates a human's click in the web UI from a session's. Reading the field as
the person yields a confident false statement about what they did, and one that turns load-bearing:
*the maintainer drafted it deliberately* is a reason to leave a wrong state alone. The correction
carries a second error, and it is the one that survives — the API cannot resolve the actor, which is
not the same as nobody can. The agent runtime's own transcripts are an instrument the service has no
access to; Claude Code writes each session's commands *and their results* under
`~/.claude/projects/**/*.jsonl`, so a walk for the object's id and the verb finds the session that
acted, with the service's own confirmation line beside it. A session that diagnosed the token trap
correctly then called the actor unresolvable while its own transcript held the `gh pr ready
--undo` that answered it.

**A reading of a file you do not control is a snapshot, and it decays silently.** The audit was
right when it was taken; by the time it is acted on, someone has merged. Nothing prompts a re-read,
because there is no measurement to re-examine — only a reading whose subject moved, and the report
still looks exactly as it did when it was true: an audit of two repo docs was obsoleted 35 minutes
later by an upstream merge, in the one section it had deliberately kept. Record what each reading
was taken from — a SHA, a fetch time — and take it again when it is about to decide something,
rather than when it is written down.

**Context you did not read carries no read time, so a negative taken from it dates to nothing.** *A
reading of a file you do not control* is a reading you took and can stamp; this is text that arrived
with no command in front of it. A file opened with `cat` announces when it was opened, because the
invocation sits in the transcript above its output. Context the harness injects — a `CLAUDE.md`, a
memory file, a skill body — has no such line, and was loaded when the session started rather than at
the moment you quote it. Positives survive the gap, since a sentence you quote is one somebody can
go and find; negatives do not, because *the skill says nothing about X* and *the copy handed to me
at session start said nothing about X* read identically and only the second is supported. A session
reported a gap in the global `CLAUDE.md` as unfiled about three hours after the fix had been
committed. Re-invoking is not the repair, and it returns as though it were: an installed skill
resolves through a symlink into a working checkout, so the second call re-injects the identical body
and reports success. `git fetch origin && git show origin/main:<path>` is the read that can come
back different from the one you are holding.

**A figure lifted from ambient context was never read from an instrument.** A harness banner, a
status header, a neighbouring row: each carries numbers that are right for what they describe and
wrong for nearly everything else, and quoting one costs nothing and reads as a measurement. Time
is where it bites hardest, because an interval is derived rather than read — subtracting two
stamps you did not take yields a plausible number instead of an obvious error, and the more real
the stamps are, the more plausible the number. A harness banner's `12h 3m since the previous turn`,
which measures from the session's first prompt, went out as twelve hours of idle time where the
real window was ten minutes. It went out in a message, which is where this escapes: nothing lints a
message. Read the clock when you take the reading, and where a receiver only needs the reading,
send it undated and let them stamp it.

**A figure committed to the tree is anchored to a revision or a date, never to a wall time.** A
message is read once; a backlog row, a PR body or a commit message outlives every session that
could re-derive it. `read at 8adb878` or `measured 2026-09-07` can be re-taken from the tree
whatever the producing clock was doing, while `14:32 PDT` is checkable against nothing once the
session has gone, and its timezone suffix makes a guess read as a reading. Grep what a branch adds
for a clock time: each hit cites a record carrying its own timestamp, or is a claim nobody can
re-take.

**A selectivity rate is not a throughput prediction.** A rejection rate says how often work is
skipped. Turning it into a speed needs the share of total cost the skipped work carries, and
without that measurement the rate licenses a claim about work avoided and none about wall-clock. A
4.9% rejection rate framed as a speedup measured neutral, because the skipped work was not where
the time went.

**A claim you inherited becomes yours the moment you repeat it.** An issue, a ticket, or a brief
arrives as the frame for the work rather than as a set of claims inside it, so its assertions get
read to plan against and never to check — and the ones about files the change does not touch are
exactly the ones the work will not incidentally verify. Repeating one in a PR description or a
summary republishes it under your name, with the original author's confidence and none of their
evidence. An issue proposing a hook fix argued its trade-off was free because
a second script validated its input the same way; the PR body repeated that as settled, and it went
unchecked until a reviewer asked, one turn after it had shipped. It was true — the ordinary
outcome, and the reason the habit survives long enough to be expensive once. The tell is a
sentence about a file outside your diff. Attribute it to the issue, or spend the one command
that settles it.

**A measured value is a function of the venue it was taken in, and the document names a different
one.** *A reading of a file you do not control is a snapshot, and it decays silently* is this
failure in time; this is it across setups. The author did go and measure, and the number
reproduces — which is why it survives, because the re-run restores the venue along with the value,
so the one check that would catch it cannot be another measurement. Read the surrounding text
instead: ask which properties the value turns on — a path depth, a file somebody created, a
platform's symlink layout, a hostname, a clock — then whether the text states them. So state the
property, or **pick an exhibit whose value the claim fixes rather than the setup**: a pair
differing only in the construct under test resolves identically from every reader's root, and the
gap between its two verdicts is the defect itself, which one command naming a correct-looking path
could not isolate. A worked case over three review rounds:
[`references/shell-traps.md`](references/shell-traps.md).

Also in this section, in [`references/further-rules.md`](references/further-rules.md): *Provenance
is a claim, and one of the cheapest to settle*; *A figure you derived is not a figure you read*.

## Sources

Distilled from the failure record of a production Kubernetes CI gateway and a set of Claude Code
guard plugins, where each rule was paid for by a wrong verdict that reached a document, a pull
request, or a release. Examples naming a repository, commit, or pull request are quoted from it;
the rest are rewritten. The incidents in full, with their dates, repositories and counts, are in
[`references/exhibits.md`](references/exhibits.md), keyed by rule lead.
