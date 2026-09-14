# Timing, concurrency, and stress runs

The long tail of `verify-claims`, for when the claim is about a test that races, a flake, or a
measurement taken under load. Same move as the main skill — name the signal, ask what it would
read if the opposite were true — aimed at the cases where the signal moves in time.

## Synchronize on the signal you assert on

"Wait on the condition, not the clock" has a sharper form: wait on **the same signal you are
about to assert on**. Two observable effects of one operation almost never land together, and a
test that blocks on the earlier one and then reads the later one races the gap between them.
That is a real race, not a slow machine, so no amount of extra timeout closes it.

A test double is the usual trap, because it is the most convenient thing to wait on and it
typically fires first. A stub that records a call on *entry* while the code under test increments
its own counter after the call *returns* leaves a window the size of a deschedule.

The gap can also sit **inside a single handler**, which is harder to see because one request looks
atomic from the outside: a handler that increments its observable counter on entry and commits the
state it actually recorded several statements later gates nothing.

Two rules fall out:

- **Writing a double: publish the observable counter last**, after every piece of state the handler
  records, so waiting on the counter is a valid happens-before gate for everything it wrote.
- **Writing the test: wait on the state, not the call count.** A count says a call was *served*, not
  that it *resolved* anything — a request whose body never arrives is still served and still
  counted.

**Publishing last is not enough when the effect is deliberately deferred to a later cycle.** When
an operation marks a decision in memory and the durable half is issued by the next cycle by design,
the counter marks the *decision*, not the *effect*. Wait on the effect.

**And the signal can come from a component that is not the system under test.** Ask *which component
has to observe the state* for the assertion to mean what it claims, and wait on something that
component emits. A wait satisfied by the test's own helper is satisfied a round trip before the
subject knows anything.

### Two effects, two participants

The gap need not be two effects of one operation. It can be one effect each from two participants,
where the test waits on the one that is cheap to reach and asserts on the one that is not.

If only the *losing* actors increment the counter you wait on, and the *winning* actor has more work
to clear before it reaches the code your assertion reads, the losers satisfy the wait entirely on
their own progress and the assertion reads zero. A counter fed by the actors you are *not* asserting
about gates nothing about the one you are.

### Two effects, one object, two clients

There need not be a double involved at all. Where a framework serves reads from a cache while your
test reads the backing store directly, one piece of state has two observers that never update
together — the store first, the cache a delivery later. A test that waits on the direct read and
then does something the *cached* reader must judge has synchronized on the earlier of the two.

- **Wait on the client the code under test reads**, not the one that is convenient. Where an object
  has both, the cached one is the later observer.
- **A one-shot stimulus needs the stronger barrier.** A polled assertion that re-reads every cycle
  self-corrects on a stale read; a single delivered event has no such recovery.

Such a gap can be a millisecond wide and still be the whole bug. It also reads far narrower than it
is if you sample it right after a wait that polls every hundred milliseconds — the poll interval,
not the gap, is what hides it.

### Prove the window rather than guessing at it

Widen it: inject a delay between the two effects and confirm the test fails **every** time. Then
re-run against the fix with the delay still in place and require green. That pair is the negative
control that shows the ordering, not luck, is what closed it. A flake unreproducible in hundreds of
local runs becomes deterministic this way.

## Pin the process when the signal comes out of its memory

Synchronizing on the right signal is not enough when the subject produces that signal from state it
holds **in memory**, downstream of something durable it already wrote.

The outcome then depends on one process surviving a window. A process replaced inside that window
forecloses the outcome permanently — so the wait expires on a decision already made, no timeout
reaches it, and the failure reads as exactly the defect the test was written to catch.

This is the shape whenever a claim is at-most-once and durable, while the follow-through is neither.
The durable half stops any successor from retrying; the in-memory half dies with the process.

**Name the process the assertion depends on, pin its identity before the window, and re-read that
pin before believing a negative.** An unchanged pin turns "it never happened" into a real failure
worth reporting; a changed one says the attempt measured nothing, and the test should re-stage
rather than assert on it.

## A flake's two attempts are a controlled experiment already run for you

A rerun that passes is not the flake's dismissal, it is **half the evidence**. Where the CI system
keeps attempts separately, one run yields both a failing and a passing log over the same test on the
same commit — same everything, one bit different.

Diff the two across the failing test's window instead of reading the failing one alone. What the
failing side contains **and the passing side does not** is the defect, and it is usually one line.

This reclassifies a fix before any code is read. A row reading "the gate never rejected the delivery"
sounds like a slow wait and invites raising a timeout; the failing attempt carrying an acquisition
line at the instant of the enqueue, where the passing attempt carries none, says the work was
*admitted* rather than slowly rejected — a different fix entirely.

Note the retrieval trap: log tooling usually serves the *latest* attempt by default, which is the one
that passed, so the failing log is easy to miss entirely.

## Stress runs measure the host as well as the code

Stress-running is the first move when chasing a flake, so these traps are reached early and misread
as a second bug.

**A long single-process repetition loop exhausts host resources.** Ephemeral ports, file descriptors,
temp files, connection pool slots. The failure the test *reports* is nowhere near the real cause: the
resource error lands on some background operation and what surfaces is an unrelated wait giving up on
an assertion with nothing to do with the race you are hunting.

Two things tell it apart from a real flake:

- **Grep the run for the resource error before reading the failure line.** Its presence means the run
  is measuring the host.
- **Run the identical loop against the unmodified tree.** If the baseline fails at the same rate with
  the same cause, it is environmental. This is worth the minutes — it is the difference between a
  second bug and a saturated laptop.

Avoid it by pacing: many short runs rather than one long one, so resources drain between processes.

**Repetition shares process-global state.** A test asserting an *absolute* value on a global counter,
registry, or singleton passes on the first repetition and fails deterministically from the second on,
because the previous run already moved the same series.

The tell is the inverse of a real flake's: it reproduces at any load and any parallelism, always at
repetition ≥ 2, with `actual = expected × count`. Prefer building fresh unshared state per test so no
series is shared in the first place. Where a test genuinely needs the registered global, assert the
*delta* around the action rather than an absolute.

**Time the unit alone before believing "under load".** Contention is a claim about the *other* work on
the host, so it predicts the unit is fast by itself. Slow under the full gate and fast standalone is
the load story; slow both ways is not.

**A pre-existing test can hang on new code.** The test being older than the change is not evidence.
What matters is whether its fixture reaches the new path — and where the runtime prints what was still
running when a timeout fired, that dump *is* the diagnosis: does that test exercise what this change
touched? A known flake row describing the same symptom is a ready-made explanation, which is exactly
why a genuine regression arrives pre-explained.

**A timer-triggered diagnostic names whichever unit was running when it fired.** Some libraries emit a
warning — often with a full stack trace, on a passing run — when something has not happened within N
seconds of process start. Which test it names is decided by how far the process got in that window,
which is decided by host load. That is why the artifact "does not reproduce" on an idle machine. Read
the verdict line and the exit code before attributing a stack trace to the test it appears under, and
close it off by installing the missing thing before any test runs.

## Clocks

**Never assert on wall-clock time you actually spent.** A bound on real elapsed seconds is least
reliable exactly where it is cheapest to write — in the most load-contended tier, inside a run that is
already saturating the machine.

Stub the sleep and assert on what the stub recorded. Two shapes:

- **Count the sleeps** when the property is "the loop paced itself rather than spinning". No notion of
  elapsed time is needed at all.
- **Shadow the clock too** when the assertion is genuinely about a budget. Have the stubbed sleep
  advance a counter and have the subject read that counter instead of the real clock. Elapsed time
  becomes the subject's own accounting: independent of load, and **exact**, so the bound can be the
  real budget rather than a slack value padded for jitter.

The second shape needs a seam: **read the clock through a named function**, never an inline call in
the middle of a code path, which is untestable by construction.

**A deadline around a process bounds the scheduler, not the guard.** A watcher that exits in
milliseconds, killed on a ten-second deadline, has a ~2000× margin on an idle machine and none at all
on a busy one — process startup alone runs to hundreds of milliseconds at p99, with a fraction of a
percent still starting at ten seconds. The suite reports its own kill, indistinguishable from the hang
the deadline exists to catch. Bound the subject's loop instead, so both outcomes terminate through the
program's own control flow and neither end needs a deadline.

**Two clocks in one assertion is a bug no margin closes.** Waiting on one clock and asserting about
another lets the two move apart by any amount: a budget spent against wall clock (which can step) and
a window spent against a timer (which cannot) means any forward step retires the whole budget inside
the window. **The margin is the tell, not the reassurance** — a budget that cannot plausibly elapse,
elapsing anyway, means the assertion is not measuring the quantity it names.

Leave the suite with **one clock, and let the subject drive it**. Stub both the clock read and the
sleep so time advances by exactly the interval the subject asked for and at no other time. "Still
waiting" becomes a count of the subject's own polls; a transition lands on a poll, which is
synchronization rather than a guess.

**A frozen clock needs a positive control, or the freeze hides the assertions it was meant to
protect.** With time stopped, every "stays waiting" case passes whatever the subject does, including
nothing at all. One case must spend the budget and reach the timeout — that is what proves the stub is
wired to the thing the other cases depend on.

**Derive a backstop from the subject's own waits.** A round number picked beside a configured budget
can expire inside it. Sum the subject's real waits, leave the multiplier as the only guess, and bind
the two to one variable so they cannot drift. Say in the failure text which of "wedged" and "slow" the
reader is looking at.

The same reasoning retires an iteration cap. Where a blocking primitive exists, use it — the subject's
own exit ends the wait with no clock in it at all. Where none does, keep polling the signal, add the
other real outcome as its own exit, and push the cap far enough out that reaching it means broken
rather than busy.

## Calibrate a throwaway load harness

A scratch harness that generates load and samples a suite is a measuring instrument, and it is
throwaway code, which is exactly why it gets written without the checks the suite itself would get.
Every failure mode below produces a confident, wrong verdict:

- **The load never started.** Generators that died instantly leave every sample passing against an idle
  machine, and the run looks like strong evidence of no flake. Assert the load is running before
  drawing any conclusion from a green sample, and print the figure measured.
- **The cleanup killed the subject.** A broad process-pattern kill matches the real gate running in the
  same tree. The gate dies mid-run and reports non-zero; a sampled suite that printed success is
  recorded as a failure. Scope cleanup to the harness's own processes.
- **The oracle was wrong.** The worse kind, because the samples are real and only the classification is
  broken. A 100% failure rate is as suspect as a 0% one — include a case whose answer you already know
  and disbelieve the harness when they disagree.
- **The subject changed under the harness.** It runs for minutes while you keep working, so an in-flight
  edit gets sampled and reads as a reproduction, carrying the flake's own signature. Freeze the tree for
  the duration and discard any round that overlapped an edit — including docs and comments, since gates
  read those too.

## Two structural traps in script and entry-point tests

**A path assembled at runtime is only checked by running the code.** Static analysis resolves nothing:
a path built from a variable is a string to a linter, correct or not. A suite that asserts only the
*pure* half — a regex, a parser, a mapping — leaves the runtime paths uncovered by every gate, and a
refactor that moves a helper breaks it silently until something downstream happens to run it.

Execute it, even when its real work needs the network. Stub the one command that reaches out and assert
on a message only the far side of the path can emit — reaching a *failure* that only the helper reports
proves the helper resolved and ran, where a missing helper produces a different error entirely.

**A library defaulting to a live shared path is captured at import.** Where a module defaults an output
path to something a real process is actively writing, any suite that loads a script reaching that module
inherits it — and *loading* is the whole trigger, so an assignment after the import line is too late for
anything that line already ran. Scope it before the import.

Then assert the positive, and **name the literal path rather than the variable**. An assertion reading
the variable passes exactly as well once the scoping is gone and the output went to the live stream, so
it guards nothing.
