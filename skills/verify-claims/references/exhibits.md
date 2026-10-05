# Exhibits

The incidents behind rules in `SKILL.md` and `further-rules.md`, moved out so the body carries each rule's instruction
and mechanism once and the full record lives here. Keyed by the rule's bold lead, under the
section that holds it. Read one when a rule's mechanism is not clear from the body, or before
changing a rule — the incident is usually what the wording is defending against.

These are measurements of historical events. A path, a repository, or a count in one names the
subject as it was when measured, and is not re-pointed when that subject moves.

## 1. Reading a result

### An empty value in a filter argument widens the query instead of narrowing it

Under HTTP 503 `gh pr view --json headRefOid --jq .headRefOid` returned empty, and
`gh run list --commit ""` then listed every run in the repository — exit 0, well formed, and
carrying a plausible green row for the branch in question. Commit-scoped was the entire point of
the flag, and branch-scoped is how a stale run reads as a pass. Re-measured against a healthy API
with a control in both directions: `--commit ""` returns what no filter returns, the 40-character
SHA only that commit's runs.

The session that hit this had been warned about the window it was in, ran the pattern across
eight PRs, and guarded one of them by reflex.

### Some instruments could not have gone positive at all, and care does not recover the difference

Measured 2026-08-28 across two sessions on `actions-gateway/github-actions-gateway`. Each of the
three was run by a session holding these rules.

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
  reporting, and no `security-scan` job run at all.
- **A probe fired where the code path had already emptied its subject.** A reviewer searched a
  captured-manifests file for a string and got 0 hits, seconds from reporting it. The probe sat
  after a loop exercising an abort path, where the script exits before writing any manifest — so
  the file was empty by construction and would have been empty for any string.

### An empty result from a filtered query is a fact about the filter's subject before it is a fact about the query

`gh pr list --search "Q1009" --state open` came back empty for a pull request whose body cites
Q1009, and the session concluded that GitHub had not yet indexed a PR opened fifteen minutes
earlier — a conclusion that went into a code comment as design rationale. The PR had merged six
minutes before the probe, so `--state open` was excluding it correctly; re-run as `--state all` it
returns for two different body-only IDs, which is the opposite of what was concluded. What settled
it was one command against the object rather than the query, `gh pr view 1759 --json
state,mergedAt`. Measured on `actions-gateway/github-actions-gateway`, 2026-08-27.

### A control must exercise the needle itself, somewhere it is known present

Measured 2026-09-01 on `karlkfi/claude-spill-guard`: a clause in `docs/queue/Q107.md` wrapped
between "a" and "finding" returned empty from a single-line grep at three commits, two of which
carried the text. One session read that empty as "(empty = gone)". A second ran a control first —
the neighbouring `No allowing arm meets that`, count 1 at all three heads — and still nearly drew
the same conclusion, because the anchor does not cross the break the claim does. The
interpretable form carries known-present cases for the same pattern:

```
head       anchor   line-grep   unwrapped
77e59d4    True     False       True
34e1038    True     False       True
2fe79a9    True     False       False
```

The two rows where `line-grep` is False over text that exists are what convict the probe rather
than the file; without them there is nothing to read the third against.

### A control tests the probe's logic and says nothing about whether its input is current

Measured 2026-09-03 on `karlkfi/claude-spill-guard`, a ref sweep fired at a known positive and the
control fired, while `git branch -r` reported 19 refs against 4 real remote heads and none for two
that had merged.

### A step that narrows a population reports both sizes, or its result is unreadable

Measured 2026-09-04, a transcript scan reported `inbound peer messages scanned: 0` beside its
`hits: NONE` with three such messages known to exist: user records store `message.content` as a
plain string rather than a list of blocks, so an `isinstance(content, list)` filter had skipped
every one.

Three instances of the correct narrowing came from one parallel-dispatch run on `actions-gateway/github-actions-gateway`, 2026-09-16.

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
verdict, so long as one definition is applied to both sides.

The third instance from that run is the one *Where it stops: a reference that moved is not a
population that shrank* carries in `SKILL.md`. That clone carried 264 worktrees under roughly 28
concurrent sessions.

### A probe's setup step can silently define what its teardown restores to

The benchmark clause comes from Q300. Measured 2026-09-08 on `karlkfi/claude-spill-guard`: the
Q164 lane's first `BenchmarkRuleset` reading was two separate runs and read as a **2×
regression**. The control — every `Anchor` cleared — had gone 7.12–7.40 → 3.31–3.42 MB/s across
the two, and an untouched rule's fixed cost 1.85×. The machine was loaded, so nothing in that run
was attributable. The control caught it in the same turn, and the lane re-measured both rulesets in
one process. The control was in one orchestrator's spawn prompt rather than in any skill. The
orchestrator's later re-measurement, which reached the v0.4.0 release notes, put the control at
7.24–7.39 and 7.37–7.40 MB/s across two runs hours apart, *which is what licenses comparing their
first rows at all*. The figures are the run's, carried from the row and not re-derived here.

### A failed read hands its error to whatever consumes the read

Measured during a six-PR run on `karlkfi/claude-spill-guard`, 2026-08-27.

### A suite result is only valid for the tree state that held for the whole run

Measured 2026-09-09 on karlkfi/claude-bouncer #126: comment edits applied to
`bash-workspace-guard.py` while `make check` ran in the background returned `FAILED
(failures=1)` in a test about remote interpreter scripts, carrying `SyntaxError: '(' was never
closed` inside the assertion text. Re-run over the settled tree: 1,556 tests, OK.

## 2. Trusting a check

### A sound instrument still answers only its own question

The narrower shape: a worker grepped a merged script for a message its change had added, got
**0**, and was seconds from reporting the merge had dropped it.

Four adjacency instances turned up in one pull request, from four authors, none erroring or
returning empty. Two were git: `git merge-tree --write-tree` consults `.gitattributes` and returns
the **merge driver's** answer, so on a repo configuring one it answers the local driver's
question; and a two-dot `git diff origin/main..HEAD` against a moved base reported 23 changed
paths to three-dot's 15, the extra 8 being the base's own commits rendered as the branch changing
them — one a file the branch never touched, reported as an add. A third reused a sweep showing
CPU-seconds flat across every fan-out width, sound for *oversubscription wastes no CPU*, to doubt a
**wall-time** effect on a machine with a quarter of the cores at four times the ratio, where the
cost is scheduler and memory contention that box cannot observe. The fourth sourced a runner's CPU
guarantee to a cluster-scoped template the tenant references nowhere, its `templateRef` resolving
to a namespaced one of the same shape and twice the request — the *over-sourced* citation the body
warns about.

Both git instruments and both correct re-runs returned the same verdict, and nothing in the
agreement marked either instrument; that is the case *Being right by luck is indistinguishable
from being right by construction* is drawn from.

### A two-tree comparison is controlled only where both trees carry the mechanism

A leak table compared a fixed binary against the trunk across seven shapes and reported the trunk
leaking on one and clean on six. The package implementing those six did not exist on the trunk, so
no code path could have fired: six of the seven "before" cells were blank, and the single real row
was carrying the whole finding. `git ls-tree -r origin/main -- internal/readers` returned nothing
and the same command against the fixed head returned three files — same command, same path, so
the probe demonstrably could come back non-empty. Measured on `karlkfi/claude-spill-guard`,
2026-08-27.

### Ask what a check would still pass on

The habit clause comes from Q1018, filed 2026-09-21. The rebase that falsified a PR body's count
of a stacked branch's parent commits (two, where it carried three) could also have moved a
test-failure line quoted in the same body, `scan_test.go` line 191. That one was re-checked and had
not moved. The session attributes its re-check to that repo's citation linter; the attribution is
its own account of its behaviour and is not independently checkable, while the two states it
separates are. A second session reached the same shape from the other side: a citation moved
into a table cell to clear a `queue.py` false positive left the linter's sight, and the line
numbers in that table were wrong within the day, read from that pull request's body on 2026-09-21.

### To learn what CI actually checked out, reproduce the merge ref's tree; do not read a run log

Measured on `karlkfi/claude-spill-guard` PR #42, 2026-08-27: base `22378bf1` and head `a14b3ed9`
gave `34a960849a998fbf6e0a4a510fc54b9087340bfa`, byte-identical to the merge ref's own tree.

### A merge ref recomputes on a push to the PR branch, not when the base moves

Measured both directions in that run. The trunk moved twice in about an hour there, and one PR's
CI finished 48 seconds before the next merge landed.

### A count is the wrong instrument for "did every check run"

Measured on `karlkfi/claude-bouncer` PR #110: 38 check runs at one head and 37 at the next, all
`SUCCESS` on both, the drop a duplicate `release-note` from a PR body edit with no family lost —
and the count cost an investigation each time it moved.

On `actions-gateway/github-actions-gateway` #1946 a mid-run difference lost `doc-links-gate` and
`unit-test-gate` between byte-identical trees; both were waiting on the two jobs still running,
and settled, the sets matched at 65 families.

### A coverage claim searched for as a mechanism finds one implementation and reports on every route

Measured 2026-09-09 on `karlkfi/claude-bouncer`, where this was one of seven probes built unable to
return the answer they were trusted for, and the one that names what the other six shared.

## 3. Writing a check that can fail

### An assertion fed only values the subject already validated cannot fail

On a sort-key allocator, a suite asserted that every generated key satisfies the key checker. The
only keys it read were ones it had handed back to the allocator as neighbours, and the allocator
checks its neighbours, so a planted defect that makes the generator emit an illegal key aborted
the run at the first allocation, long before the assertion. Routing the same illegal key down a
path the assertion did not read left the suite green instead — exit 0, that assertion's own pass
line printed, while the generator emitted the illegal key. The repair was the bulk-import series,
generated, never fed back, and written into the store as it stands, which made it both the
failable input and the one nothing was checking.

### A containment test is satisfied by the needle your own change emptied

Measured 2026-09-11 over one PR's three states, the containment answer read True, False, True
while the quote's line count read 3, 3, 2 — only the pair says a sentence was trimmed rather than
the block dropped, and only the middle False makes either True readable.

### A mutation is confirmed by reading the file it mutated, not by the exit status of the command that wrote it

Measured 2026-08-28. Both arms of a citation gate were driven with `sed -i 's/…/…/' file`, where
BSD `sed` takes the expression following `-i` as a backup suffix, so neither mutation applied; both
arms came back exit 0, and the conclusion drawn — the gate is silent on both — was the inverse of
the truth on one. Redone with a precondition asserting the file had actually changed, the arms
separate: a wrong path exits 2 naming the row, and only a wrong line inside the gate's ten-line
window is silent.

### A check with one binary outcome cannot report that you were right for the wrong reason

Measured 2026-08-25: a session delegated a claim as "re-derive independently, and file nothing if
it refutes", and the run came back confirming the defect and refuting the stated mechanism. The
real consequence was worse than either of the two sessions that raised it had concluded, and worse
in the direction that sounds safe.

## 5. Explaining behaviour

### Name what the probe would show if the hypothesis were false, before running it

Measured 2026-09-10 in `actions-gateway/github-actions-gateway`: a gate reported `ok` where it
should have failed, the symptom matched that repo's postmortem describing a stale build artifact,
and deleting the artifact and re-running returned an identical `ok`. That was read as consistent
with the diagnosis and staleness went to the user as the cause. If staleness were the cause,
removing the artifact had to change the result. The real cause was elsewhere — a denied Bash call
had discarded the source edit silently — and the elimination clause of *Source reading tells you
what should happen, not what does* would have retired the hypothesis before the probe ran, since
the build script recompiled unconditionally and staleness had never been possible.

## 6. Stating a fact nobody measured

### A pre-written form field hides the claim's role

Both shapes measured 2026-08-18. `- [x] make check is green` went out on a PR whose entire subject
was that self-attested template boxes are unreliable, ticked without the run; the run passed when
it was finally taken, so the claim cost nothing and nothing in the process would have caught it
either way. And a release note's fold enumerating the release's new tests named three that do not
exist — plausible names written from the code diff rather than from the artifact, which one diff
of the test function names against the previous tag settled.

### An actor or author field names the credential, not the person

Measured 2026-08-25 across concurrent sessions sharing one `gh` credential: one read
`convert_to_draft <human>` on its own PR's timeline and told the human they had deliberately
drafted it, hours after another had made the same inference across four PRs and been answered
*"i havent personally drafted any prs today. it's all you, claude."* That second session diagnosed
the token trap correctly and then called the actor unresolvable — while its own transcript held the
`gh pr ready --undo` that answered it, seconds from the timeline event. The session holding the
mechanism is the one that reached for unknowable.

### A reading of a file you do not control is a snapshot, and it decays silently

Measured 2026-08-25: an audit of two repo docs against three installed skills was obsoleted 35
minutes later by an upstream merge, in the one section the audit had deliberately kept.

### A figure lifted from ambient context was never read from an instrument

A session took the `12h 3m since the previous turn` from its own harness banner, which measures
from the session's first prompt, and reported it as idle time after a handback — filing a finding
that a pull request had gone twelve hours unwatched. Its own background-task mtimes put the window
at ten minutes. The same session stamped a `git rev-parse` reading with that banner's opening
time, twelve minutes before the commit it named existed, and a peer reading the inversion
diagnosed a clock offset that was not there. Both went out in messages.

### A figure committed to the tree is anchored to a revision or a date, never to a wall time

From Q298. Reported by a `karlkfi/claude-spill-guard` run on 2026-09-07: its orchestrator
fabricated timestamps in peer messages, extrapolating rather than running `date`, drifting up to 80
minutes, with timezones attached. The drift figure is the run's own account and was not re-derived.
The durable half was: a worker audited what it had committed — its four filed rows, its merged
diff's added lines, and both PR bodies — for `HH:MM`, `PDT` and `PST`, and found zero hits, because
every claim it committed was anchored to a SHA or a calendar day. That audit is the grep the rule
names.

This is distinct from a repository convention that fixes the *timezone* of a date going into the
tree: that one takes for granted that a date is what is written, and this one is about choosing the
anchor at all.

### A selectivity rate is not a throughput prediction

From Q301. Measured 2026-09-08 on `karlkfi/claude-spill-guard`, by the Q164 lane and the brief
that dispatched it. The row and the brief carried a two-segment head's selectivity over 0.46 GB —
554 bare `eyJ` keyword hits, 27 reaching a second segment past a dot — and framed the
detection/extent split as therefore *faster*. Both rulesets measured in one process went 37.93–39.04
→ 37.55–39.58 MB/s: neutral, because `jwt` was already anchored and the other nine rules are where
the time goes. What moved is the adversarial case — 1 MiB of back-to-back JWTs 13.8 → 56.9 MB/s at
the same 6,721 findings, and 1 MiB of `-eyJ` 16,733 ms → 2.4. The lane refused the speed claim, and
the shipped framing was recall at no cost.

The brief had already warned the lane in the same document — *That is a rejection rate, **not a
benchmark*** — two paragraphs before framing the split as a speedup. A warning about a class does
not stop the author committing it.

The figures are the run's, carried from the row and not re-derived here.

### A measured value is a function of the venue it was taken in, and the document names a different one

Measured 2026-09-08 across three consecutive review rounds on one backlog row, where a table gave
the output of a command built from `../../../..` as an absolute path under a setup that fixed
neither the depth nor the root — and on macOS the wrong value was the realpath of the right one,
so reproducing it taught the reader nothing. The rounds in full are in `shell-traps.md`.

## Further rules

### Two causes that predict the same count are not distinguished by that count

The agreeing-figure clause comes from Q292. Measured 2026-09-05 during an eight-PR
`karlkfi/claude-spill-guard` run under agent review: a reviewer measured a corpus at ~3,502 MiB
against a stated ~3,540 MiB and read the agreement as corroboration, having capped reads at 1 MiB
per file. This is the reviewer's run as reported back and was not re-derived; the row asked for a
recurrence scan to tell a recurring shape from n=1, and that scan has not been run.
