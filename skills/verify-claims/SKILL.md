---
name: verify-claims
description: Check that the evidence behind a statement could have shown you the opposite, before the statement decides anything. Use when a gate, test, or CI result is about to be reported or trusted, when ticking a PR checklist box or writing release notes, when chasing a flake or a regression, when working out a root cause or reproducing one, when asking whether a check actually ran, when a probe, grep, scan, or count is about to justify a decision, when writing or reviewing a test or gate, when explaining why a system behaved as it did, when a claim about where code came from, who wrote it, or how a repo is laid out decides something, and when reporting a reading of someone else's file taken earlier. Covers exit status lost through pipes and background chains, empty output from a command that never matched, a sound instrument whose question is narrower than the claim, hand-rolled probes standing in for gates, provenance read off resemblance, and proving a fix by deleting the mechanism. Not for deciding what to build.
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
useless one: three separate causes collapse onto it, and each is searched for differently.
Measured 2026-08-25 over the misses in one review.

- **A construction derived from its own answer.** The instrument was built out of the result it
  exists to validate — a search pattern widened from the hits it already had, a fixture generated
  from the output under test, a sample drawn from the population it is meant to characterise. Ask
  where the pattern, the fixture, or the sample came from. If the answer is "from the thing I am
  checking", it cannot fail.
- **An untested input class.** The claim was checked across the inputs someone thought of, and one
  class was never run at all. A guard read `prev != nil && !isSessionSourced(prev.Reason)`, and the
  prose describing it was checked against every non-nil `prev` and never against nil, which is
  where the behaviour inverts. Ask what class the claim quantifies over, then which member of it
  has never been through the check.
- **An unexamined case.** Reasoning stopped at the case that agreed with the conclusion. An author
  defending their own phrasing traced the scenario where it held, and not the scenario their own
  design document contemplates, where it inverts. Ask what case would make this false, and whether
  you traced it.

Only the third feels like a lapse while you are committing it. The first two feel like finished
work, which is why they survive a review that is looking for the third.

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

**A completion predicate must key on what ends the run, not on a string that appears in it.** A
watcher armed on a marker fires early when the marker is also vocabulary the run emits while it
works, and the early fire looks exactly like the real one. Grep the marker against a full log of
an earlier run before arming anything on it, and prefer the process exiting, which cannot fire
early.

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
means *no filter* rather than *no match*. Under HTTP 503 `gh pr view --json headRefOid --jq
.headRefOid` returned empty, and `gh run list --commit ""` then listed every run in the
repository — exit 0, well formed, and carrying a plausible green row for the branch in question.
Commit-scoped was the entire point of the flag, and branch-scoped is how a stale run reads as a
pass. Re-measured against a healthy API with a control in both directions: `--commit ""` returns
what no filter returns, the 40-character SHA only that commit's runs. So check the value's *form*
before it filters anything, and check it against what it should be rather than against emptiness —
a 40-character test refuses the truncated reads and error strings that `-n` accepts — then confirm
it from a second source, here `git ls-remote`. **Do it unconditionally.** The session that hit this
had been warned about the window it was in, ran the pattern across eight PRs, and guarded one of
them by reflex; a guard reached for on suspicion is absent wherever the failure is quiet.

**A negative needs a positive control.** This is the sharpest rule here. A wrong positive gets
argued with by the thing it names; a wrong negative simply agrees with whatever you already
suspected, so nothing pushes back. Before an absence decides anything, run the same probe
against a value you know is present. A misspelled config key, a build target matching no rule,
an alternation mangled by quoting — each returns the empty result that means "not there", and
each agreed with the defect being investigated and went on agreeing after it was fixed.

**Some instruments could not have gone positive at all, and care does not recover the
difference.** The rule above treats the control as a check on a probe that might be broken.
The sharper case is a probe that is written correctly, run correctly and read correctly, whose
answer was fixed before it ran: no state of the world reachable from where it was pointed would
have made it say anything else. Reading it more carefully returns the same reading, and each of
the three below was run by a session holding these rules and applying them correctly in the
direction it was looking. Measured 2026-08-28 across two sessions on
`actions-gateway/github-actions-gateway`.

- **An assertion whose two endpoints cannot move relative to each other.** A bash suite asserted
  an ordering on two needles the function's own body emits whether or not the mechanism named in
  the assertion runs between them. Deleting the entire block the assertion is named for left the
  suite at 88 ok, 0 FAIL. §3's *Delete the mechanism* is what surfaced it, and the green does not
  mean the assertion cannot see that defect class: it means the two needles were never able to
  separate. Re-anchored on a marker only the mechanism itself emits, the same deletion moved the
  index off 0.
- **A green the instrument reports *in order to* report the absence.** `gh run list --commit
  <sha>` gives workflow-**run** conclusions. A workflow whose heavy job skips while its `-gate`
  job passes concludes `success`, so at run level "ran and passed" and "correctly skipped" are
  the same row by construction — the gate job exists precisely to be green when the heavy job is
  correctly absent. A session read five such greens, wrote into a PR body that five named lanes
  had "ran and passed, confirmed by `gh run list --commit` rather than by branch", and told its
  user twice. The check-runs API showed all five heavy jobs **skipped**, only the gate jobs
  reporting, and no `security-scan` job run at all. Note where the care went: `--commit` fixes
  *which commit*, which is why it reads as the guarded form, and it says nothing about *which
  job*, which is what the sentence needed.
- **A probe fired where the code path had already emptied its subject.** A reviewer searched a
  captured-manifests file for a string and got 0 hits, seconds from reporting it. The probe sat
  after a loop exercising an abort path, where the script exits before writing any manifest — so
  the file was empty by construction and would have been empty for any string.

So before a zero or a green decides anything, name the state of the world that would have made
this instrument say something else, and go and put it in front of it: the string where it is
known to be, the tree with the mechanism deleted, the job whose skip you can already see. Where
no such state exists at the point the instrument is aimed, the reading is not weak evidence —
it is none, and the fix is a different instrument rather than a closer look.

**An empty result from a filtered query is a fact about the filter's subject before it is a
fact about the query.** *A negative needs a positive control* covers the query that could
never have matched — a misspelled key, a build target no rule builds. This is the query that
would have matched yesterday: the search worked, the object is still there, and a predicate
moved underneath it. Both return the same nothing, and the mechanism reading is the
interesting-sounding one, so it is the one that gets drawn. `gh pr list --search "Q1009"
--state open` came back empty for a pull request whose body cites Q1009, and the session
concluded that GitHub had not yet indexed a PR opened fifteen minutes earlier — a conclusion
that went into a code comment as design rationale. The PR had merged six minutes before the
probe, so `--state open` was excluding it correctly; re-run as `--state all` it returns for two
different body-only IDs, which is the opposite of what was concluded. What settled it was one
command against the object rather than the query, `gh pr view 1759 --json state,mergedAt`.
Measured on `actions-gateway/github-actions-gateway`, 2026-08-27. The shape is any filter that
can move while the object sits still — a time-windowed log query, a status-scoped API call, a
`--since` that has passed the event.

**A control has to vary the cause you suspect, not the term you happened to type.** That
session did run one: it searched a distinctive phrase from the same PR's title and got empty
again, and read the second zero as confirmation. Both queries carried `--state open`, so the
control re-ran the failing filter with a different word inside it and could only ever agree.
Vary the suspected cause — here the state scope, never the search term — and where the
hypothesis was already in mind when the probe ran, treat that zero as the one owed a second
reading. An empty result is consistent with the explanation you arrived with, which is what
makes it easy to read past rather than explain.

**A control drawn from inside the enumeration it is testing cannot fail.** The rule above is
satisfied, on a literal read, by a control that varies a *member* of a list when the *list* is
what you doubt. A sweep for `gh` invocations across a repo's workflows matched
`gh\s+(pr|api|issue|repo|release|run)` and missed `gh attestation verify`; its positive control
injected `gh pr view`, whose `pr` is already inside the alternation, so it proved the pattern
worked for what the list already covered and was structurally incapable of showing the list to be
incomplete. Any probe keyed on a table of known values has this shape — a per-command table
deciding which token is a path, an extension allowlist, a set of recognised error strings — and
the control has to come from outside the table: an input you know the subject accepts and the
table does not name. The asymmetry is what makes this worse than forgetting a control: a missing
one is visible, and this one *passes*.

**A control must exercise the needle itself, somewhere it is known present.** *A control drawn
from inside the enumeration it is testing cannot fail* is about a control whose *input* was too
weak; this is one whose *pattern* is. A neighbouring string in the same region establishes that
the file and the section are reachable and nothing more — a line wrap, a smart quote, an em
dash, a case difference each break the needle and leave the anchor matching, so the control
passes while the probe stays broken. Measured 2026-09-01 on `karlkfi/claude-spill-guard`: a
clause in `docs/queue/Q107.md` wrapped between "a" and "finding" returned empty from a single-
line grep at three commits, two of which carried the text. One session read that empty as
"(empty = gone)". A second ran a control first — the neighbouring `No allowing arm meets that`,
count 1 at all three heads — and still nearly drew the same conclusion, because the anchor does
not cross the break the claim does. The interpretable form carries known-present cases for the
same pattern:

```
head       anchor   line-grep   unwrapped
77e59d4    True     False       True
34e1038    True     False       True
2fe79a9    True     False       False
```

The two rows where `line-grep` is False over text that exists are what convict the probe rather
than the file; without them there is nothing to read the third against. History usually supplies
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

**Uniformity across inputs you varied is a finding about the instrument, whatever the answer
is.** The rule above is one instance of a wider shape, and reading it as being about censuses
leaves the shape unnamed: a probe returning the *same* verdict for every input you deliberately
varied has told you about itself rather than about the inputs. A zero and a near-total are the
two variants that get looked at, because both read as results; a uniform plausible-looking
answer is the one that gets used. Three mechanisms produce it. A `case`-based shell harness whose
`case` was the script's last command, so all four shapes inherited its status and returned
`rc=1` — the variant to lead with, because it produced a wrong answer rather than a false clean.
A three-dot diff against an ancestor: `git diff origin/main...origin/main~1` is empty by
construction, the merge base *being* `main~1`, and the form that answers is
`origin/main~1...origin/main`. And two fixtures whose mutation landed and was then neutralised
downstream by a rule that is itself correct, so they passed against every implementation
variant. So when the answers stop varying,
stop reading them: fire the probe at a case whose answer you already know, and where no such
case exists, build one — the ref sweep above was cleared by constructing a diverged branch for
it to find. A real population is scattered by construction. The instrument is what can be
uniform.

**A control tests the probe's logic and says nothing about whether its input is current.** The
rule above sends you to a case whose answer you already know; a probe over a cache passes that
while answering about a stale world: the remedy fires, passes, and licenses the wrong answer.
Measured 2026-09-03 on `karlkfi/claude-spill-guard`, a ref sweep fired at a known positive and the
control fired, while `git branch -r` reported 19 refs against 4 real remote heads and none for two
that had merged. Ask the remote (`git ls-remote --heads origin`); a tracking ref reports the last
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

A *broken* narrowing is the easy half. Measured 2026-09-04, a transcript scan reported `inbound
peer messages scanned: 0` beside its `hits: NONE` with three such messages known to exist: user
records store `message.content` as a plain string rather than a list of blocks, so an
`isinstance(content, list)` filter had skipped every one. The two zeros want opposite fixes — an
unreached population indicts the filter, a reached one settles the absence.

The hard half is a narrowing that is *correct*: the dedup is right, the flag is right, and it
removes what the reading needed anyway, so re-reading finds nothing. Three instances from one
parallel-dispatch run on `actions-gateway/github-actions-gateway`, 2026-09-16.

Lead with the report that carried no denominator at all, because the person who wrote its fix
filed it as a different kind of defect until the rule was stated — which is the argument for
naming it. `scripts/ci/check-withheld-runs.sh` printed a fixed line on zero findings and never
said how many pull requests it had examined, so a scan over twenty and a scan over none
were byte-identical: stubbed both ways, exit 0 each time and `cmp` reporting no difference. A
watch workflow then closed its tracking issue on the strength of that line, commenting that every
open PR's checks had been released. Fixed by printing the reach count, and by having the workflow
quote the checker's own line rather than restate its verdict.

Then `sort -u` over a lossy key. Reconciling the row sets of `scripts/README.md` across a
merge-driver resolution, the comparison keyed on the markdown link *label* alone and put the
keys through `sort -u`. The file has 263 rows and 262 distinct labels — `dev/setup.sh` and
`dogfood/setup.sh` collide — so the dedup dropped a row, and a dropped `setup.sh` row was exactly
the substitution the check existed to catch. Re-keyed on label plus path with no dedup, compared
both directions with `comm`, it holds — and a disagreement about the row total does not reach the
verdict, so long as one definition is applied to both sides. The wrapped-prose grep and the
`--state open` filter above are this rule with the narrowing living in a pattern and in a flag.

**Where it stops: a reference that moved is not a population that shrank.** Printing both sizes
would not have caught the third instance. A session reconciled a branch's rows against
`origin/main` as a live ref rather than against the branch's own merge base, got two spurious
extra rows, and was one message from reporting a fabricated defect in a peer's rebase. Both
readings were correct when taken and nothing narrowed, so the fix differs: pin to a SHA or to
`git merge-base` before anything compares against it. And `origin/main` does not go *stale*:
`refs/remotes` lives in git's **common** dir (`git rev-parse --git-common-dir`), not the
per-worktree one, and that clone carried 264 worktrees under roughly 28 concurrent sessions — so
it is shared mutable state owned by other processes, and it can change between two of your own
commands while you run nothing. Which fetch forms move it, and the two measurements behind that:
[`references/shell-traps.md`](references/shell-traps.md).

**One response, two causes — and a positive control cannot separate them.** The denominator
rule above catches a probe that is broken. This catches a probe that works perfectly and answers a narrower
question than the one being asked. `gh api repos/<o>/<n>/pages` returns the same 404 for "no
Pages site is configured here" and for "this account cannot have one on a private repo", and the
first reading is the one that agrees with wanting to build on it. Running the probe against a
repository that *does* publish returns 200 and confirms the probe works, which is exactly no help.
So when a result is about to decide something, name the readings that produce it and pick a probe
that separates them — `gh repo view --json visibility` answers the second question and could not
have answered the first. The tell is that the response was consistent with the hypothesis: a
result you expected is where a second cause goes unenumerated, because nothing prompts the search.
The same shape has a ready-made fix, and release or merge-policy reasoning runs into it:
`gh api repos/<o>/<n>/branches/main/protection` answers *does the legacy API hold a record*, not
*is this branch protected*, so on a repository moved to rulesets it returns `404 Branch not
protected` where `gh api repos/<o>/<n>/branches/main --jq .protected` returns `true`.

**A probe's setup step can silently define what its teardown restores to.** The two rules above
are about a probe that is broken and a probe that is sound but narrow. This is a third: the probe
is sound, the question is right, and the *baseline* it compares against is the previous run's
output rather than the original state. The second measurement then reads the first. Testing whether a linter's escape hatch works, a setup staged the tree with `git add -A`, so the later `git checkout -- <file>` restored from the index — which already held the planted defect — and the "reverted" file still carried it. The probe reported the escape
hatch failing on a line that was never the exhibit. Nothing errored, and a revert that does not
revert is reported by nothing.

The shape is wider than reverts: a baseline copied *after* a mutation, a fixture generated once
and reused across cases, a temporary directory not removed between runs. Each makes run two a
reading of run one, and the direction of the error is unconstrained — here it manufactured a
failure, but the same setup can as easily manufacture a pass.

What makes it expensive is standing: a probe is trusted more than the thing it measures, so its
artefact arrives as a finding *about the code*, and the probe above appeared to have found a
defect of exactly the class the session was already working on. So re-derive from a fresh
baseline rather than a restored one — extract the tree again, use a new directory, append rather
than plant-and-revert — and treat agreement between two runs sharing a setup as one reading, not
two. A mutation of state you share needs its undo armed *before* the mutation, not appended
after it; measure in a throwaway clone in the session scratchpad where you can.

**An approved permission prompt leaves no trace in the result.** A hook that decided `allow`, a
hook that decided nothing, and an `ask` the user approved all hand back the same thing — the
command's own output, with nothing marking that a prompt happened. Only a refusal is visible: a
rejected `ask` returns `The user doesn't want to proceed with this tool use`, and a `deny` arrives
as the hook's own reason text. So "the command ran" is never evidence about what a hook decided
or about which version of a hook is live. The signal is correct and the command genuinely did
run; three upstream decisions collapse onto one observation. Settling whether an in-session
plugin update had taken effect, a session ran four probes and tabulated all four as evidence. Three ran under either
version, one of them a case both versions decide `ask`, so nothing could have differed; the
session read one of those three as proof the old version was still live, with the
identical-decision probe sitting unread in its own table. The single probe the new version
*denies* was the only one that could separate them. Two instruments recover what a re-probe
cannot — run the hook script directly on the
same stdin and read its `permissionDecision`, which works offline against any installed version;
and to learn whether a prompt appeared at all, ask the user, who is the only one who saw it. That
is the rare case where a question beats another probe.

**A correct reading of the wrong field is a wrong measurement with nothing defective in it.**
Every other check here passes on it: the command is the one the claim needs, it ran, and its
output is right. The unchecked step sits between that output and the sentence, which is where a
green gate also means less than it looks — the instrument ran, and the reading off it was never
checked. The tell is the field you want sitting beside a field you do not, at the same type and
a similar magnitude, so the wrong value is plausible rather than absurd: a `wc -l` over the
filtered stream against the unfiltered one, a percentage whose denominator is not the population
the sentence names, a unified-diff hunk header, which carries two `start,count` pairs and reads
like one. Measured 2026-09-10, where two branches editing
adjacent paragraphs of one file needed to know how close the edits were.
`git diff -U0 origin/main -- CLAUDE.md` returned `@@ -68,9 +71,14 @@`, and the `14` — the
**new**-side count — went out as an old-side span, which reads as no gap against a peer's
`@@ -78,8`. The old spans are 68–76 and 78–85, line 77 separates them, and the two branches
were never editing the same sentences.

So **derive the quantity instead of reading it**. Where the claim is a span, compute both
endpoints; where it is a count over a population, compute the population too. Prefer a one-line
`python3` printing the thing you are about to assert over an eyeball on a tool's native format,
which was laid out for a different reader. A cleaner specimen than the hunk header, which needs
the reader to know the field's structure: a verdict line printed the opposite of the SHAs sitting
directly above it, because `before` had been captured from two commands, so the string compare
ran against a two-line value. So **print the raw value beside the verdict and read both** — a
derived sentence with its inputs missing is unfalsifiable on the page. The `sort -u` case above
is this rule from the other side, where `comm` was the right instrument and the key fed to it was
not. Sending the command beside the claim does not close this, and it is the habit most likely to
be mistaken for closing it: it buys provenance, not agreement, so both ends can re-run the
command, agree on every character of its output, and still disagree about what it says. Here the
peer recomputed and caught it, and no gate could have. *A figure you derived is not a figure you
read* is the same step failing the other way, so a span you derived is checked too rather than
trusted for having been derived.

**One field is a projection of a mutable object, and several of its states project onto the same
value.** Read straight after a push, `gh pr view <n> --json headRefOid` returned the pre-push SHA
— which is what you would see if the push had failed, and equally what you get once the PR has
merged, because a merged PR's `headRefOid` is a stored value that stops following the branch. (It
still reports a SHA for a branch the merge deleted; `git ls-remote` finds no such ref.) The field
that separates those two states is sitting in the same object, so the fix is to widen the read
rather than to take it again — `--json headRefOid,state` costs one word and returns `MERGED`.
Before a field decides anything, ask which states of the object project onto the value you got,
and read a field they disagree on in the same call.

**Re-reading an ambiguous output cannot disambiguate it.** The instinct on a surprising result is
to run it again and look harder, but if two states produce the same output then the second reading
produces it too, and the only thing that grows is confidence. What breaks the tie is a second
instrument that would have disagreed: a log file against a task notification reporting `exit code
0`, another field against the one you read. Reach for a different measurement, not a closer look.

**The far end of an instrument can be sick, and it answers in the shape of a finding.** Three readings can settle the same way and all be wrong. `gh run list --commit
<sha>` returned `HTTP 404: Not Found` for three PRs, which reads as *no runs on this commit* —
indistinguishable from the path-gated workflow that silently skipped, a real hazard and the reading
you would go and chase; `gh pr checks` on the same PRs returned four passing jobs each. Later that
day GraphQL answered HTTP 503 where the REST pulls endpoint answered normally, twice within an
hour. So the move is the rule above pointed at a remote: **a different endpoint on the same data**,
not a retry. Retrying is the obvious advice and the weaker one, because it re-reads the sick
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

**A failed read hands its error to whatever consumes the read.** The rules above are about a
command answering the wrong question; this is one that answers nothing and has the refusal
recorded as data. `git show <commit>:<path> > f 2>&1` on a path absent from that commit writes
`fatal: path '<path>' does not exist in '<commit>'` into `f` and exits 128, so a reviewer
establishing whether a file is identical on two commits by extracting both and running `cmp`
compares an error message against real content. It reports *differ*, which is the expensive
shape: a plausible refutation of the claim under test rather than a check that stopped, so it
changes a verdict instead of raising one. Measured during a six-PR run on
`karlkfi/claude-spill-guard`, 2026-08-27. Compare ids instead — `git rev-parse --verify
<commit>:<path>` returns the blob id, and a missing path is an error rather than a value, so
there is nothing for the comparison to make a verdict out of. Keep the `--verify`: measured here
on git 2.55.0, the bare form exits 128 having echoed its own argument, `HEAD:no/such/file.md`, on
stdout, and that string compares unequal to a real blob id in exactly the way a difference does.
`--verify` leaves stdout empty at 128; `--verify --quiet` leaves it empty at 1.

**A capability is a claim, and it is load-bearing before the design, not after.** Whether the
platform can do the thing at all is upstream of every option built on it, so an unchecked
capability does not produce one wrong step — it deletes the alternatives from the menu, and the
work proceeds soundly toward something that cannot ship. Establish it before offering choices
that rest on it, and state it as an assumption where offered.

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

**The measurement that justifies a change is taken on the tree without the change in it.** The
bullets above have a number going stale because the tree moved; this is the case where your own
branch is what moves it, so a census taken to argue for a diff is falsified by that same diff, and
the two readings are a rebase apart. Nothing marks the difference and nothing can go red: a gate
reads the tree, while a number already written into a document is prose. Seven figures went stale
under one worker across five rebases with `make check` green through every one — a suite count, a
store total that moved 54 → 53 → 54 → 55, an invisible-citation total, a documented highest ID —
and one census was re-invalidated by its own thread three times before it landed. Re-derive every
figure against the head you are about to publish from, and where a figure counts a population your
own diff edits, say which side of the change it is true of.

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

**The tell is a boundary that coincides with your own start.** When the outliers are the most
recent N, and N begins at the hour you did, that alignment is the finding rather than the
mechanism you were about to read out of it. So ask what the outliers *are* before asking what they
mean — a question about the sample rather than about the count, and the one nothing in a review
prompts. *Did I cause this?* is not that question and will answer no: where several sessions share
a system, the contaminating action is usually a peer's, so the session holding the corrupted
sample is honestly certain it changed nothing. Two checks are cheap. Where the mechanism you are
reaching for would be a configured behaviour, read the configuration — one call settles whether
the system does that thing at all. And where you can afford to wait, re-take
the measurement once your activity has stopped: the same 60 pull requests re-read on 2026-08-21,
after that batch ended, split 0 and 60. A finding that does not survive the end of the window that
produced it was a finding about the window.

**Two instruments pointed at one observable are one instrument.** *A measurement of recent
activity, taken while your own work is changing that system, samples your own work* has the
contamination arriving from the work. Here it arrives from the verification: an earlier step
writes into the record a later step reads, so the later reading is of the check itself and would
be identical if nothing under test worked at all. Both instruments are sound and neither is
narrow. What is wrong is the order they were put in, a property of the plan rather than of
either script, so reviewing either one alone finds nothing.

Measured on a dogfood cluster, 2026-08-28. One script attempts an upload against every registry
mirror, to prove the mirrors serve. A second counts content requests in those same mirrors'
access logs, to decide whether a CI job's image pulls rode them. The plan's own sequence runs the
prover first, and it leaves 2 content requests and 1 served on every instance before the job
starts, so the counter reports PASS whether or not a single client was wired: a verdict from an
instrument that measured nothing, on a booked cluster session that costs a node-pool resize to
repeat.

Two repairs, and the weaker one comes to mind first. Discount the interferer, here by client
user agent, written so an unrecognised client under-counts into a failure rather than
over-counting into a pass. That works, and it covers only the writer you thought of. Stronger is to
**take the baseline before the scarce run, with the thing not yet done**, which turns the
verdict into a change from a measured zero rather than a number, and tests the whole path
instead of the one interference you wrote a discriminator for. In that session the baseline
reported all five instances FAIL at zero, twenty minutes before the run, which is what made the
eventual 161 content requests evidence rather than assertion.

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

**One observation is not a steady state.** Before calling a condition permanent, take a second
reading far enough apart to tell churn from stasis, comparing identities not counts.

**A failure on your branch is not yours until the base fails too.** A red gate reads as caused
by the only thing you changed, and a plausible mechanism is always available. Check out the base
and run the same gate before naming a cause. The tell that you are a bystander: a failing test
whose identity moves between runs, or one in a file the diff never touches.

**A local gate disagreeing with CI indicts your toolchain first.** CI builds its tools fresh
from the pin; your build directory holds whatever it held last time. A stale binary takes no
flag it does not know, prints plausible output, and names real files — nothing about the run
looks wrong. Rebuild and re-run before reporting anything about the repository. And a repeated
claim gains authority without gaining evidence, so the second and third restatements are the
expensive ones.

**A suite result is only valid for the tree state that held for the whole run.** The two rules
above hand a red result to somebody else — the base, or your toolchain. This one hands it back,
and not through the change under test: a file written while the suite runs is read half-written
by whatever executes next. A gate started in the background and an edit made while it ran is the
ordinary shape, and neither step feels like it touches the other.

How far the corruption reaches is decided by how the suite loads the subject. An imported module
is read once at import, so an edit after that lands in the next process. A helper that spawns the
subject as a **subprocess** re-reads the file from disk on every call, so a mid-run write breaks
whichever case happens to run during it. Measured 2026-09-09 on karlkfi/claude-bouncer #126:
comment edits applied to `bash-workspace-guard.py` while `make check` ran in the background
returned `FAILED (failures=1)` in a test about remote interpreter scripts, carrying
`SyntaxError: '(' was never closed` inside the assertion text. Re-run over the settled tree:
1,556 tests, OK.

It misleads in two directions at once. The result is red, so *could this have shown me the
opposite?* answers yes and the failure passes the check that catches most of this section. And it
names an innocent test — whichever one ran during the write — so the obvious next move is to
debug code that was never wrong. The tell is a syntax or import error arriving inside a test
assertion rather than as a collection error: a subject the suite never imports cannot fail
collection, so its unparseable state has nowhere to surface but whatever case was running. So
before believing a failure, ask whether anything under test was written during the run; before
starting an edit, ask whether a suite is in flight. Where both already happened the run measured
nothing either way, and only a re-run over a settled tree replaces it.

## 2. Trusting a check

**The probe is not the gate.** A hand-rolled stand-in answers a slightly different question and
its answer looks exactly like the real one: a raw `grep -c` where the gate excludes code spans,
a bare linter where the gate passes a flag that follows sourced files, a cached test result
where the change touched a file the cache cannot see, an anchored search for a check name that
misses `integration-test` because it matched on `^integration`. When a probe's answer is about
to decide something, run the gate. When the gate is too slow for the loop, keep the probe but
give it a case whose answer you already know, and disbelieve it when the two disagree.

**A probe with two verdicts forces every failure onto one of them.** The rule above keeps a
probe honest about the question it answers; this one is about the answers it can give. A
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

**Agreement with the enforcer is not evidence when one detail could fool both.** *The probe is
not the gate* says run the gate, and a *threshold* gate is where that is hardest to follow:
under the limit it exits 0 in silence, so the quantity you wanted is nowhere in its output and
the obvious move is to extract it yourself. That extractor is a second implementation of the
gate's own parser, offered as a check on the first — and it goes wrong by a detail of the format
rather than by carelessness, which is the error its author cannot feel. Force the threshold
instead: load the enforcing module, set its limit to zero, and read the count out of the message
the enforcer itself raises. Over eighteen frontmatter descriptions against a 1024-character cap, three plausible hand-rolled folds of the block each matched the enforcer
exactly on every plain scalar and overshot by two on every `>` block scalar — whose opener the
enforcer reads as a marker while a regex from the key carries it into the fold. Two of the five
checked agreed and three did not, with nothing but that opener between them. A reading that
matches is the reading you get whenever the input happens to be the shape your parser assumed,
and it tells you nothing about the input that is not.

**Extracting a call argument by name breaks wherever two functions share the name.** A scan that
pulls an argument out of a call site keys its table on the callee's name, and two functions sharing
a name hold that argument at different positions — normal in any codebase with wrappers. It then
fails in both directions at once: it reports a neighbouring argument as a hit, and reports nothing
at all for the calls whose index it guessed past. Read the position off each callee's own
declaration, and fail loudly on a call you cannot place. Two sub-traps inside that: a variadic
declaration's arity counts the trailing parameter, and a parameter of the enclosing function is a
forwarder rather than the site that decides the value.

**A scan that tracks enclosing scope must clear it at the end of the block.** An `awk` or `grep`
pipeline that remembers which function, section, or block it is inside and never resets attributes
every later top-level match to the last block it saw. It shares the failure mode above: the wrong
answer arrives as a confident positive rather than a silence, so nothing in the output looks wrong.
The positive control is what catches it — count one block by hand and require the scan to agree.

**A measurement that reproduces a call is not a test of the code that makes it.** Issuing the
request yourself from a harness establishes what the *remote* does with it, and nothing about the
path that will issue it in production. Three axes differ, and each has hidden a shipped bug behind
a green response: where it went (the harness takes ambient config; the product reads a field that
may never be assigned), when it fired (the harness waits for a convenient state; the product fires
on its own schedule), and which client sent it. The flaw is rarely in the measurement — it is in
the sentence that carries it forward and lets a fact about the remote read as a fact about your
code. Write down what the measurement did not exercise, and say which of those a follow-up still
has to confirm.

**A rule fires on a subject, so confirm the subject existed when the check ran.** A green check
folds two claims into one — the rule held, and there was something for it to hold on — and when
the second fails the first is vacuous while the output is identical to a real pass. Three
instances in one night, 2026-08-21: a store lint's *a flake row may not vanish* rule, taken
against a merge base carrying no such row; a `staticcheck` exclusion still listed in
`.golangci.yml` after the directives it excluded had been deleted; and a fail-open introduced by
an evidence capture, whose failure mode had no fixture until that change created one. Not there
yet, gone, and never exercised are three ways in and one check covers all three: name the
subject, count it, and refuse on zero rather than passing.

**A literal-name search is blind to every site that routes the name through a variable.** A
suite's assertion subjects, a registry's keys, a table's fixture names — two helpers taking the
name as a parameter is enough, and the search then returns a clean subset of the truth with
nothing marking it as a subset. A literal-name sweep for a suite's
twenty-five subjects saw thirteen, on a tree nobody had touched. The blind spot is a property of
the *file*, not of the change under review, so the size of the miss says nothing about the size
of the diff — which is exactly why a small change is no reason to trust it. Run the suite and
read the subjects it reports.

**A sweep that comes back clean has told you about its own representation.** The rule above is
one such blindness, a name reaching its site through a variable. Four more were measured in a
single review on 2026-08-25, where three sessions each enumerated every place in a repo asserting
one claim so the claim could be corrected, and all three sweeps came back falsely clean, each for
a different structural reason.

- **Subject scope.** A sweep requiring the subject term and the claim language in the same
  *sentence* misses every sentence that names its subject anaphorically — and it does not hide
  *a* site, it preferentially hides *the* site. A paragraph names its subject once and refers back
  thereafter, so the sentence carrying the load-bearing claim is systematically the one that has
  stopped saying what it is about. The sentence that motivated the whole correction carried no
  subject token at all, only *the two producers* and *one condition type*. Test the subject over
  the surrounding paragraph, or a few hundred characters, rather than over the sentence.
- **Vocabulary.** A pattern built from a literal string lifted off known instances finds
  restatements of that string and nothing else. Six known sites shared a phrase; six further sites
  asserted the same claim sharing no literal with it.
- **Inherited vocabulary.** The second sweep was written specifically to fix the axis above, and
  derived its widened signature from the first probe's own hits. A signature built out of the
  answers it exists to validate can only re-find them. It is nastier than plain vocabulary
  blindness because it looks like the fix — *A construction derived from its own answer* arriving
  inside a sweep.
- **Line breaks.** A line-oriented pattern cannot match a sentence spanning two comment lines.
  `is dropped` on one line and `when the live condition is X` on the next means `is dropped when`
  matches nothing, and the site reads as absent. Strip the comment leaders and join the lines
  before matching.

**A clean sweep and a blind one both print nothing**, so the reading can never come from the
silence. Fire the sweep at a state where instances are known to exist — the commit before the
corrections landed — and require it to find all of them before trusting what it says at head.
Pick that known positive to be the hard case rather than a convenient one: the control is what
exposed the subject-scope axis at all, the sweep having found three of four known sites at the
base commit with the anaphoric sentence as the miss. One of the three sessions did catch that
sentence, on a window it had chosen because a few hundred characters seemed a reasonable amount
of context. A design that is accidentally right is indistinguishable from one that is
deliberately right until the discriminating case turns up, which is the reason to name the
mechanism — naming it is what makes the width reproducible.

**A sound instrument still answers only its own question.** This is the one that survives "check
more", because nothing is missing — *A probe with two verdicts forces every failure onto one of
them* gives a failure somewhere to go, and here nothing fails. Nobody writes the gap down because
the probe and the claim share their vocabulary: *is this string in the file* and *does this
program print this string* differ by one verb. It comes in two shapes. The instrument answers a
**narrower** question than the claim: a worker grepped a merged script for a message its change
had added, got **0**, and was seconds from reporting the merge had dropped it, the message being
assembled from f-string fragments that exist at runtime and nowhere contiguous in the source. Or
it answers an **adjacent** one — a different quantity, object or definition, at the same type and
a plausible magnitude, with nothing in the output marking which question it answered. Four
adjacency instances turned up in one pull request, from four authors, none erroring or returning
empty. Two were git: `git merge-tree --write-tree` consults `.gitattributes` and returns the
**merge driver's** answer, and drivers are per-clone while the queue building the real candidate
runs none, so on a repo configuring one it answers the local driver's question; and a two-dot
`git diff origin/main..HEAD` against a moved base reported 23 changed paths to three-dot's 15,
the extra 8 being the base's own commits rendered as the branch changing them — one a file the
branch never touched, reported as an add. A third reused a sweep showing CPU-seconds flat across
every fan-out width, sound for *oversubscription wastes no CPU*, to doubt a **wall-time** effect
on a machine with a quarter of the cores at four times the ratio, where the cost is scheduler and
memory contention that box cannot observe. The fourth sourced a runner's CPU guarantee to a
cluster-scoped template the tenant references nowhere, its `templateRef` resolving to a
namespaced one of the same shape and twice the request.

**Ask what question the instrument answers, not whether its answer looks right.** What does
`merge-tree` consult; what quantity does this reading measure, on what hardware, at what ratio;
what is in the cited file. An *over-sourced* citation is the one that gets through: a real file
with a real number trips none of the reflexes tuned to flag thin sourcing. A hedge rescues none
of this: it sits on the inference, and the error is upstream in the probe. Both halves of the
sentence are written in the same words, so ask what this instrument would report if the claim
were false **in a way it cannot see**.

**Being right by luck is indistinguishable from being right by construction.** Both git
instruments and both correct re-runs returned the same verdict, and nothing in the agreement
marked either instrument. That is a different argument from *a negative needs a positive
control*: there the answer is suspect, here it is right and the method still gets checked,
because it is reached for again where the luck does not hold. Each of the four was caught by
another seat and none by its author: the remedy is a second reader, not more care.

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

**Two causes that predict the same count are not distinguished by that count.** The rule above
is about one instrument read too widely; this is two explanations competing for one number, and
it is harder to catch because the number is correct and the reasoning from it is fluent.

A table of per-item usage counts put the items written as broad standing advice at the bottom
and the ones naming a specific request at the top. That reads as strong evidence that framing
drives usage. It is equally consistent with a second explanation — the low items quoted trigger
phrasings nobody actually types — and both predict exactly the same table. The discriminator sat
one level down and cost a single query: do those quoted phrasings occur in the corpus at all?
They occurred zero times, and the real defect was vocabulary rather than framing.

Two habits close it. **Write down the rival explanation before the count settles a "why", and
check whether it predicts a different number** — if it predicts the same one, this is not the
measurement you need. And when a pattern looks overwhelming, count the points it rests on: two
items at the bottom of a table is n=2, however cleanly they line up.

**A claim about what a change did needs a before-and-after.** Scanning the after-state answers a
different question than "which of these did this change produce", and the two numbers differ
by more than you expect. Run the probe against the base tree too, and diff.

**A two-tree comparison is controlled only where both trees carry the mechanism.** The rule
above sends you to the base tree; this one is about what you find when you get there. *A rule
fires on a subject* catches a check that passed with nothing to check. Inside a comparison the
same vacuity surfaces as a *row*, where it reads as fixed rather than as absent — a zero in a
before-and-after table is what a fix looks like. A leak table
compared a fixed binary against the trunk across seven shapes and reported the trunk leaking on
one and clean on six. The package implementing those six did not exist on the trunk, so no code
path could have fired: six of the seven "before" cells were blank, and the single real row was
carrying the whole finding. `git ls-tree -r origin/main -- internal/readers` returned nothing
and the same command against the fixed head returned three files — same command, same path, so
the probe demonstrably could come back non-empty. Measured on `karlkfi/claude-spill-guard`,
2026-08-27. `git ls-tree` exits 0 on a path that is not there, so the blank arrives with a clean
status and no mark on it; confirm each tree contains the mechanism its row is about before
reading the row, and say which rows are blanks rather than befores.

**Ask what a check would still pass on**, then check whether the thing you care about is in that
set. A gate named for a class covers one mechanism inside it, and the name is what makes the
rest of the class feel guarded. Say in the check itself what it does not read. And a
fail-closed refusal must name the condition it actually detected — "unrecognized record format"
routes the reader at a migration; "the value was empty" routes them at a corrupt file they do
not have.

**Green checks say the run passed, never that your change is gated.** The two come apart exactly
when a gate is new, which is when nobody looks. Verify by naming the gate's *job* in the run's
job list, not by the run's conclusion. `gh run list --commit <sha>` cannot do that — it reports
conclusions per run, and a run whose heavy job skipped while its `-gate` job passed concludes
`success`. `gh api repos/:owner/:repo/commits/<sha>/check-runs?per_page=100` is the read that
lists jobs and their `skipped` conclusions, and it is the only one that separates a lane that
ran from a lane that reported on behalf of one that did not.

**To learn what CI actually checked out, reproduce the merge ref's tree; do not read a run
log.** The rule above names the job in the job list, which settles whether your gate ran. This
settles what it ran *over*, and a log line is the wrong instrument for it — a log says what one
job did on one attempt, and a rerun, a stale annotation or a skipped job each leave a line that
reads the same. The tree hash says what the ref is. `git merge-tree --write-tree <base> <head>`
prints the id of the tree a merge would produce, and it compares directly against
`refs/pull/N/merge^{tree}`. Measured on `karlkfi/claude-spill-guard` PR #42, 2026-08-27: base
`22378bf1` and head `a14b3ed9` gave `34a960849a998fbf6e0a4a510fc54b9087340bfa`, byte-identical
to the merge ref's own tree — an identity that rests on no path taking a custom merge driver,
since `merge-tree` applies whatever driver this clone has and a merge-queue candidate is built
with none. Where one is configured, reproduce the ref rather than compute it.

**A merge ref recomputes on a push to the PR branch, not when the base moves.** Measured both
directions in that run. So a green check can be scoped to a merge base that no longer exists,
and nothing in the PR marks it: the checkmark, the head SHA it names and the ref it ran over are
all still exactly what they were, and only the base has changed underneath. The window is not
theoretical — the trunk moved twice in about an hour there, and one PR's CI finished 48 seconds
before the next merge landed. *Was this green* and *was this green against what is on the trunk
now* are two questions, and the second needs the merge base the ref was built on, read against
the base branch's current head.

**A count is the wrong instrument for "did every check run".** *Green checks say the run passed*
sends you to the job list, where the reflex is to compare two heads by how many runs each has. A
total cannot separate a duplicate from a substitution, and two offsetting changes leave it
unmoved — the reading that looks most like proof. Ask instead which job families are
present at one head and absent at the other; only the name sets answer it. Measured on
`karlkfi/claude-bouncer` PR #110: 38 check runs at one head and 37 at the next, all `SUCCESS` on
both, the drop a duplicate `release-note` from a PR body edit with no family lost — and the count
cost an investigation each time it moved.

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
last. On `actions-gateway/github-actions-gateway` #1946 a mid-run difference lost
`doc-links-gate` and `unit-test-gate` between byte-identical trees; both were waiting on the two
jobs still running, and settled, the sets matched at 65 families.

**A coverage claim searched for as a mechanism finds one implementation and reports on every
route.** *A count is the wrong instrument for "did every check run"* swaps a total for the name
set; this swaps the subject. The claim is about an effect — this linter runs in CI — and what gets
written is a search for the mechanism the author expects to carry it, so a second route to the same
effect is invisible, and the zero reads as a coverage hole rather than as a search that could not
have found one. A `run: make` sweep over a repo's workflows came back empty for one linter and
nearly shipped *it is gated nowhere*; the linter runs on every push, through a test in the root
suite that no pattern over `run:` lines can reach. Ask what would have to be true for the effect to
occur by **any** route, and settle it downstream of the mechanism — plant a violation and watch
something go red. Measured 2026-09-09 on `karlkfi/claude-bouncer`, where this was one of seven
probes built unable to return the answer they were trusted for, and the one that names what the
other six shared: each **searched for the mechanism its author expected rather than the effect its
author was claiming**.

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

## 3. Writing a check that can fail

**Delete the mechanism.** The only way to settle "this code causes that outcome": remove the
mechanism, require red *for the reason you expect*, restore, confirm green in the same sitting.

- Delete the mechanism, not the assertion. Removing the assertion proves nothing.
- Delete one mechanism, not the branch around it. A deletion coarse enough to redden every
  assertion has measured only that the path is reached.
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

**A mutation aimed at a constant tests the constant.** Where a change ships a lookup table and a
traversal that reads it, inverting the table's membership is the mutation that suggests itself — a
one-line edit to a visible constant, and it goes red — so it gets run and reads as having falsified
the change. It cannot reach the walk, which is where the defect usually is. A guard shipped
`SUDO_RUN_NOTHING`, the sudo flags that run no command, beside a walk over a command's flags;
adding `k` to the set reddened 3 tests and did prove the membership load-bearing, while the walk
matched the set against a whole token. `sudo -uKarl kubectl delete ns foo` read the `K` in the
username as `--remove-timestamp`, concluded sudo would run nothing, and deferred a command sudo
runs — fail-open in a production guard, reached by ordinary usage rather than a crafted bypass, and
caught by a reviewer's own matrix rather than by the author's inversion. Restoring the whole-token
scan reddens 12 tests, so an assertion aimed at the walk would have caught the shipped code
verbatim. A defect in the code that reads a constant needs a mutation aimed at that code. §2's *a
control drawn from inside the enumeration it is testing cannot fail* is the neighbour and not this
rule: there the table is what you doubt, and the repair is an input from outside it; here the table
is right and its reader is not.

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

**An assertion fed only values the subject already validated cannot fail.** The rule above has
the test handing the subject an answer; this is the same trade running the other way, with the
subject handing the test one. Where the code under test checks its own inputs, every value it
gives back has been through that check one call earlier, so a value that would fail your
assertion raises *inside* the subject instead. The assertion re-runs a check that has already
run: it reads as a guarantee and is a tautology. This is not a sampling weakness a wider fixture
would fix — the argument holds for every input the assertion can see. On a sort-key allocator, a suite asserted that every generated key satisfies the key checker. The only keys it read were ones it had handed back to the allocator as neighbours, and the allocator
checks its neighbours, so a planted defect that makes the generator emit an illegal key aborted
the run at the first allocation, long before the assertion. Routing the same illegal key down a path the
assertion did not read left the suite green instead — exit 0, that assertion's own pass line
printed, while the generator emitted the illegal key. The repair is to find a value the subject
has not already approved: here the bulk-import series, generated, never fed back, and written
into the store as it stands, which made it both the failable input and the one nothing was
checking.

**A payload chosen for being harmless is often exempt for the same reason.** The rule above has
the subject approving the test's input; here the test picks an input the subject was never going to
act on. A probe needs something to fire at, and the safe pick — `echo`, `true`, a write to a
scratch file — is safe because the system treats it as inert, which is frequently the very property
the mechanism under test keys on. The probe then measures the harness and reports on the subject. A
hook probe used `echo` as its command because it could do no damage; the guard classifies `echo` as
harmless in every mode, so the probe showed a mode running that does not run, which would have
implied a hole in a guard set shipped an hour earlier. Pick a payload the subject has to make a
decision about, and confirm it sees one: the cheapest evidence is that the probe's verdict *moves*
when you change the setting it claims to be measuring.

**Repeated passes do not validate a flake fix.** A green run of twenty is equally consistent with
"the race is closed" and "the race did not fire" — and on an idle machine the second is more
likely. Invert the fix and confirm the suite fails. A fix you cannot make fail on demand has not
been shown to be load-bearing. When the inverted form refuses to fail either, that is the
finding: the diagnosis is wrong.

**A negative assertion must be able to fail for only one reason.** "It didn't fire" passes when
the mechanism is absent, and equally when it is present but misdirected, misconfigured, or
erroring out early. Pair it with a positive assertion somewhere in the suite — if nothing asserts
the mechanism *works*, the negative is unfalsifiable. Prefer asserting the specific wrong thing
did not happen over asserting nothing happened. And a poll or sampler bounds how often something
was *observed*, never whether it *happened*.

**A positive can be vacuous too.** "X happened" is satisfied by state that predated the test,
and it bites hardest where the chain is fast enough that a real pass and a leftover are
indistinguishable from the timings. Assert against the server's own ordered record of what it
was asked to do, rather than inferring from the client's side.

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
that failure mode in prose then shipped a probe that had it. Measured 2026-09-11 over one
PR's three states, the containment answer read True, False, True while the quote's line
count read 3, 3, 2 — only the pair says a sentence was trimmed rather than the block
dropped, and only the middle False makes either True readable. So assert a quantity that
moves with the repair — a length, a line count, a match position — alongside any test
whose empty case is a pass, and reject an empty needle before comparing.

**A mutation is confirmed by reading the file it mutated, not by the exit status of the
command that wrote it.** A control breaks a checker's input and demands red; where the break
silently fails to land, the checker sees clean input, passes, and the control reports green —
testing nothing, and reading exactly like a control that worked. The tool fails more quietly than
the logic does, because a flag the installed binary rejects, or a GNU pattern under a BSD one,
leaves no mark on the control's own status. Both arms of a citation gate were driven with
`sed -i 's/…/…/' file`, where BSD `sed` takes the expression following `-i` as a backup suffix,
so neither mutation applied; both arms came back exit 0, and the conclusion drawn — the gate is silent on
both — was the inverse of the truth on one. Redone with a precondition asserting the file had
actually changed, the arms separate: a wrong path exits 2 naming the row, and only a wrong line
inside the gate's ten-line window is silent. Measured 2026-08-28. And a green arm is evidence for
whichever hypothesis predicted green, including the one you were already drafting.

**Assert the recovery property, not the mechanism believed to deliver it.** A test pinning a safety
or recovery property — the queue drains, the retry budget stays bounded, the gate cannot starve a
tenant — should assert that property as an observable outcome. Asserting instead the internal
transition *believed* to produce it is worse than under-testing: if the belief is wrong, the test
actively defends the defect, and its docstring argues the defect is the safety feature. Three
corollaries:

- Name the property in the test, then ask whether the assertion measures it or a proxy for it. A
  proxy stated as one invites re-examination; a proxy argued from forbids it.
- A docstring justifying an assertion with a consequence — "without this, X would happen" — is a
  claim. Where X was only ever reasoned about, mark it design intent rather than measured fact.
- When a live measurement falsifies a test's premise, the test is a casualty, not a defense.

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

**Probe the environment, never infer it.** A user id, an OS string, a platform constant are
proxies, and they are wrong in both directions. Attempt the operation and branch on the result.
Skip on the probe and say what it observed — a silent skip and a passing test look identical in
the log, which is how a gate rots into a no-op. The reviewer's tell: a test that names an
environment fact in a comment but never reads it.

**A skip is not a defense.** A spec gated on credentials reports the same colour whether it ran or
not, so the invariant stops being enforced the moment the credentials are absent. When a gated
spec is the only thing asserting something, find the code change that could break it and make
*that* the tripwire.

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

**A check with one binary outcome cannot report that you were right for the wrong reason.**
*Delete the mechanism* settles whether a mechanism is load-bearing; this is what to ask for when
somebody else runs the check. *Is this real?* comes back yes and stops, leaving whatever mechanism
was asserted beside the defect unread — and the mechanism is the half a fix gets written against.
Separate the existence of the problem from the explanation of it, so the run can disagree on
either axis independently. Measured 2026-08-25: a session delegated a claim as "re-derive
independently, and file nothing if it refutes", and the run came back confirming the defect and
refuting the stated mechanism. The real consequence was worse than either of the two sessions that
raised it had concluded, and worse in the direction that sounds safe. Ask for the mechanism to be
re-derived rather than confirmed, and give the run somewhere to put an answer that is neither yes
nor no.

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
*change* — an outcome identical to the one being diagnosed is the refutation, not a null. Measured
2026-09-10 in `actions-gateway/github-actions-gateway`: a gate reported `ok` where it should have
failed, the symptom matched that repo's postmortem describing a stale build artifact, and deleting
the artifact and re-running returned an identical `ok`. That was read as consistent with the
diagnosis and staleness went to the user as the cause. If staleness were the cause, removing the
artifact had to change the result. The real cause was elsewhere — a denied Bash call had discarded
the source edit silently — and the elimination clause above would have retired the hypothesis
before the probe ran, since the build script recompiled unconditionally and staleness had never
been possible.

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
ticking it feels like completing paperwork rather than saying anything. Both shapes measured
2026-08-18. `- [x] make check is green` went out on a PR whose entire subject was that
self-attested template boxes are unreliable, ticked without the run; the run passed when it was
finally taken, so the claim cost nothing and nothing in the process would have caught it either
way. And a release note's fold enumerating the release's new tests named three that do not
exist — plausible names written from the code diff rather than from the artifact, which one diff
of the test function names against the previous tag settled. So tick the box after the run, and
build an enumeration by reading the thing it describes rather than the change that produced it.
The document is where a claim gets consumed: a wrong belief held privately is corrected by the
next command, and the same belief in a PR body is what a reviewer approves on.

**Provenance is a claim, and one of the cheapest to settle.** *Vendored*, *forked*, *copied from*,
*based on* each assert a direction of derivation, and resemblance is symmetric — two trees holding
similar code look the same from either end, so the word arrives from whichever end you happened to
be standing at. What separates them is the commit history on each side, one `git log` per side,
and it can come back the other way. A repo's backlog tooling was called
vendored from a skill across three documentation sites, and the word was then used to justify
cutting those docs to deltas, on the grounds that the tooling carried the rules. Both logs
reversed it — that repo had authored its own linter, its id allocator, its merge drivers and a
commit-isolation gate, and the skill had no counterpart for most of them. The claim had already
shipped in a PR body, which is the usual ending: a provenance error turns nothing red, so it is
caught only when a reader happens to ask.

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
acted, with the service's own confirmation line beside it. Measured 2026-08-25 across
concurrent sessions sharing one `gh` credential: one read `convert_to_draft <human>` on its own PR's timeline and told him he had
deliberately drafted it, hours after another had made the same inference across four PRs and been
answered *"i havent personally drafted any prs today. it's all you, claude."* That second session
diagnosed the token trap correctly and then called the actor unresolvable — while its own
transcript held the `gh pr ready --undo` that answered it, seconds from the timeline event. The
session holding the mechanism is the one that reached for unknowable.

**A reading of a file you do not control is a snapshot, and it decays silently.** The audit was
right when it was taken; by the time it is acted on, someone has merged. Nothing prompts a
re-read, because there is no measurement to re-examine — only a reading whose subject moved, and
the report still looks exactly as it did when it was true. Measured the same day: an audit of two
repo docs against three installed skills was obsoleted 35 minutes later by an upstream merge, in
the one section the audit had deliberately kept. Record what each reading was taken from — a SHA,
a fetch time — and take it again when it is about to decide something, rather than when it is
written down.

**Context you did not read carries no read time, so a negative taken from it dates to nothing.**
The rule above is a reading you took and can stamp; this is text that arrived with no command in
front of it. A file opened with `cat` announces when it was opened, because the invocation sits in
the transcript above its output. Context the harness injects — a `CLAUDE.md`, a memory file, a
skill body — has no such line, and was loaded when the session started rather than at the moment
you quote it. Positives survive the gap, since a sentence you quote is one somebody can go and
find; negatives do not, because *the skill says nothing about X* and *the copy handed to me at
session start said nothing about X* read identically and only the second is supported. A session
reported a gap in the global `CLAUDE.md` as unfiled about three hours after the fix had been
committed. Re-invoking is not the repair, and it returns as though it were: an installed skill
resolves through a symlink into a working checkout, so the second call re-injects the identical
body and reports success. `git fetch origin && git show
origin/main:<path>` is the read that can come back different from the one you are holding.

**A figure lifted from ambient context was never read from an instrument.** A harness banner, a
status header, a neighbouring row: each carries numbers that are right for what they describe and
wrong for nearly everything else, and quoting one costs nothing and reads as a measurement. Time
is where it bites hardest, because an interval is derived rather than read — subtracting two
stamps you did not take yields a plausible number instead of an obvious error, and the more real
the stamps are, the more plausible the number. A session took the
`12h 3m since the previous turn` from its own harness banner, which measures from the session's
first prompt, and reported it as idle time after a handback — filing a finding that a pull request
had gone twelve hours unwatched. Its own background-task mtimes put the window at ten minutes. The
same session stamped a `git rev-parse` reading with that banner's opening time, twelve minutes
before the commit it named existed, and a peer reading the inversion diagnosed a clock offset
that was not there. Both went out in messages, which is where this escapes: nothing lints a
message. Read the clock when you take the reading, and where a receiver only needs the reading,
send it undated and let them stamp it.

**A figure you derived is not a figure you read.** The rule above quotes a number; this one you
computed, out of terms that *were* measured, so it carries their credibility and no instrument.
Measured 2026-09-03: eight per-rule timing deltas hand-summed as `8.93s` and sent as a benchmark's
largest term, against `9.719s` from the total minus the no-rule baseline — effectively the whole
run, not its largest term — and `32 MiB × 6.8 MiB/s ≈ 4.7s` in a code comment against a driven
`4.300s`. Derive it a second way, because **the claim you re-verify least is the one you produced
while verifying something else**: effort goes to the subject of the check; its by-products inherit
it unchecked.

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
platform's symlink layout, a hostname, a clock — then whether the text states them. Measured
2026-09-08 across three consecutive review rounds on one backlog row, where a table gave the
output of a command built from `../../../..` as an absolute path under a setup that fixed neither
the depth nor the root — and on macOS the wrong value was the realpath of the right one, so
reproducing it taught the reader nothing. So state the property, or **pick an exhibit whose value
the claim fixes rather than the setup**: a pair differing only in the construct under test
resolves identically from every reader's root, and the gap between its two verdicts is the defect
itself, which one command naming a correct-looking path could not isolate. All three rounds:
[`references/shell-traps.md`](references/shell-traps.md).

## The one-line test

Before the sentence goes out: *could this signal have shown me the opposite?* If not, you have not
measured the thing you are about to say.

## Sources

Distilled from the failure record of a production Kubernetes CI gateway — its diagnosis
conventions and the incident write-ups that justified them, where each rule was paid for by a
wrong verdict that reached a document, a pull request, or a release. Examples here are rewritten;
the originals are repo-specific.
