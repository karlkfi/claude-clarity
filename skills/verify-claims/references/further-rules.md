# Further rules

Rules moved out of `SKILL.md` because they reach the fewest sessions that load it. Each is
still a rule, kept whole: `SKILL.md` lists them by lead at the end of the section they came
from, so read the one whose lead matches your situation. An italicised rule name that is not
in this file is in `SKILL.md`.

## 1. Reading a result

**A completion predicate must key on what ends the run, not on a string that appears in it.** A
watcher armed on a marker fires early when the marker is also vocabulary the run emits while it
works, and the early fire looks exactly like the real one. Grep the marker against a full log of
an earlier run before arming anything on it, and prefer the process exiting, which cannot fire
early.

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
derived sentence with its inputs missing is unfalsifiable on the page. `SKILL.md` §1's `sort -u` case
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

**A capability is a claim, and it is load-bearing before the design, not after.** Whether the
platform can do the thing at all is upstream of every option built on it, so an unchecked
capability does not produce one wrong step — it deletes the alternatives from the menu, and the
work proceeds soundly toward something that cannot ship. Establish it before offering choices
that rest on it, and state it as an assumption where offered.

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

**One observation is not a steady state.** Before calling a condition permanent, take a second
reading far enough apart to tell churn from stasis, comparing identities not counts.

**A failure on your branch is not yours until the base fails too.** A red gate reads as caused
by the only thing you changed, and a plausible mechanism is always available. Check out the base
and run the same gate before naming a cause. The tell that you are a bystander: a failing test
whose identity moves between runs, or one in a file the diff never touches.

## 2. Trusting a check

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

**A measurement that reproduces a call is not a test of the code that makes it.** Issuing the
request yourself from a harness establishes what the *remote* does with it, and nothing about the
path that will issue it in production. Three axes differ, and each has hidden a shipped bug behind
a green response: where it went (the harness takes ambient config; the product reads a field that
may never be assigned), when it fired (the harness waits for a convenient state; the product fires
on its own schedule), and which client sent it. The flaw is rarely in the measurement — it is in
the sentence that carries it forward and lets a fact about the remote read as a fact about your
code. Write down what the measurement did not exercise, and say which of those a follow-up still
has to confirm.

**The checker is a fourth subject, and that check cannot count it.** A hook or guard failing
*before* its first instruction — no execute bit, a missing interpreter, an unreadable config — is
non-blocking by design, and a spec gated on absent credentials reports its usual colour the same
way, so *it did not object* means either *it passed* or *it was never there* with nothing to
separate them. Count its runs too, and refuse on zero: one guard's record over the two days it
was installed was 5,427 non-blocking errors at exit 126 and no run. Where it is the only thing
asserting something, make the tripwire a change you can watch it catch.

**Two causes that predict the same count are not distinguished by that count.** This is two
explanations competing for one number rather than one instrument read too widely, and it is harder
to catch because the number is correct and the reasoning from it is fluent.

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

## 3. Writing a check that can fail

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

**A payload chosen for being harmless is often exempt for the same reason.** *An assertion fed only
values the subject already validated cannot fail* has the subject approving the test's input; here
the test picks an input the subject was never going to act on. A probe needs something to fire at,
and the safe pick — `echo`, `true`, a write to a scratch file — is safe because the system treats it
as inert, which is frequently the very property the mechanism under test keys on. The probe then
measures the harness and reports on the subject. A hook probe used `echo` as its command because it
could do no damage; the guard classifies `echo` as harmless in every mode, so the probe showed a
mode running that does not run, which would have implied a hole in a guard set shipped an hour
earlier. Pick a payload the subject has to make a decision about, and confirm it sees one: the
cheapest evidence is that the probe's verdict *moves* when you change the setting it claims to be
measuring.

**A positive can be vacuous too.** "X happened" is satisfied by state that predated the test,
and it bites hardest where the chain is fast enough that a real pass and a leftover are
indistinguishable from the timings. Assert against the server's own ordered record of what it
was asked to do, rather than inferring from the client's side.

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

**Probe the environment, never infer it.** A user id, an OS string, a platform constant are
proxies, and they are wrong in both directions. Attempt the operation and branch on the result.
Skip on the probe and say what it observed — a silent skip and a passing test look identical in
the log, which is how a gate rots into a no-op. The reviewer's tell: a test that names an
environment fact in a comment but never reads it. The remedy for a silent skip is §2's *The
checker is a fourth subject*.

## 6. Stating a fact nobody measured

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

**A figure you derived is not a figure you read.** *A figure lifted from ambient context was never
read from an instrument* quotes a number; this one you computed, out of terms that *were* measured,
so it carries their credibility and no instrument. Measured 2026-09-03: eight per-rule timing deltas
hand-summed as `8.93s` and sent as a benchmark's largest term, against `9.719s` from the total minus
the no-rule baseline — effectively the whole run, not its largest term — and `32 MiB × 6.8 MiB/s ≈
4.7s` in a code comment against a driven `4.300s`. Derive it a second way, because **the claim you
re-verify least is the one you produced while verifying something else**: effort goes to the subject
of the check; its by-products inherit it unchecked.
