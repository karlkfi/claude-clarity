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

Three moments land here, and each opens by reading its own file.

Before a command's exit status, its output, or its silence becomes a verdict — passed, failed,
clean, empty, done — read [`references/reading-a-result.md`](references/reading-a-result.md). You
leave it holding how a status is lost through a pipe, a background chain or a sequenced mutation,
the three causes of silence, why an empty filter value widens a query, and when a red result
belongs to your toolchain or to a mid-run write rather than to the code.

Before a zero, an empty result, a near-total, or an answer that never varies decides anything,
read [`references/negatives-and-controls.md`](references/negatives-and-controls.md). You leave it
holding the control that could have made the instrument say something else — drawn from outside
the list under test, fired at the needle itself, varying the cause you suspect, over an input that
is current — and the probe that separates two causes of one response. The rule the file builds on
binds before you open it:

**A negative needs a positive control.** This is the sharpest rule here. A wrong positive gets
argued with by the thing it names; a wrong negative simply agrees with whatever you already
suspected, so nothing pushes back. Before an absence decides anything, run the same probe
against a value you know is present. A misspelled config key, a build target matching no rule,
an alternation mangled by quoting — each returns the empty result that means "not there", and
each agreed with the defect being investigated and went on agreeing after it was fixed.

Before a count, a total, or a population goes into a sentence or justifies a change, read
[`references/counts.md`](references/counts.md). You leave it holding which population and scan
width the figure is true of, which side of your own diff it was taken on, and whether it sampled
your own work or a failure list that recovery had already filtered.

## 2. Trusting a check

Before a gate, a CI run, a sweep, or a probe is trusted to say something is clean, covered, or
gated, read [`references/trusting-a-check.md`](references/trusting-a-check.md). You leave it
holding the question the instrument actually answers, how to confirm your gate's job ran and over
which tree, what a clean sweep cannot see, and what a completeness claim inherits from its
inventory. The rule the file builds on binds before you open it:

**The probe is not the gate.** A hand-rolled stand-in answers a slightly different question and
its answer looks exactly like the real one: a raw `grep -c` where the gate excludes code spans,
a bare linter where the gate passes a flag that follows sourced files, a cached test result
where the change touched a file the cache cannot see, an anchored search for a check name that
misses `integration-test` because it matched on `^integration`. When a probe's answer is about
to decide something, run the gate. When the gate is too slow for the loop, keep the probe but
give it a case whose answer you already know, and disbelieve it when the two disagree.

## 3. Writing a check that can fail

Before you write or review a test, a gate, a fixture, or a control, read
[`references/writing-a-check.md`](references/writing-a-check.md). You leave it holding the ways a
check passes without testing anything — an escape hatch nobody falsified, a value the test
supplied itself, an empty run that clears a ceiling, a mutation that never landed — and how a flake
fix, a fake, and a bulk rewrite each prove themselves. Every one of them feeds the procedure that
stays here:

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

## 4. When the signal moves in time

Before re-running a flake, calling a race fixed, or trusting a figure taken under load, read
[`references/timing-and-concurrency.md`](references/timing-and-concurrency.md). You leave it
holding synchronization gaps between participants and between cached and direct readers, pinning a
process whose signal comes out of its memory, virtual clocks, and calibrating a throwaway load
harness.

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

Before you write a PR body, a release note, a status report, or any sentence a decision will rest
on, read [`references/stating-a-fact.md`](references/stating-a-fact.md). You leave it holding the
claims those documents carry without looking like claims: a ticked box, a list implying one
mechanism, an actor field, a stale snapshot, a figure from ambient context or a wall-clock time, a
rate read as a speedup, a claim inherited from the brief, and a value tied to the venue it was
measured in.

## Sources

Distilled from the failure record of a production Kubernetes CI gateway and a set of Claude Code
guard plugins, where each rule was paid for by a wrong verdict that reached a document, a pull
request, or a release. Examples naming a repository, commit, or pull request are quoted from it;
the rest are rewritten. The incidents in full, with their dates, repositories and counts, are in
[`references/exhibits.md`](references/exhibits.md), keyed by rule lead.
