# Writing a check that can fail

`SKILL.md` sends you here before you write or review a test, a gate, a fixture, or a control. An italicised rule name that is not in this file is
in `SKILL.md` or in a sibling file under `references/`.

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

Both arms need a control, for the reason *size the fixture to the threshold* gives in `SKILL.md`. Against
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

**When the producer is a third-party API there is nothing to generate from — read the live one,
once per value you branch on.** The same belief-shaped error without that remedy: the stub returns
what the author thinks the service says, the consumer reads it the same way, and the suite pins the
belief rather than the contract. The axis here is semantic rather than syntactic — not escaping or
field order but what a field's values *mean*, and which way round they are. GitHub's
`compare/BASE...HEAD` reports `.status` as the head's position relative to the base, so "has my
commit landed" is `ahead`; a stub written around `behind` carried a 19-assertion suite green while
the code treated the not-yet-deployed state as deployed. Call the endpoint for each value the code
switches on and pin what actually comes back.

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

Also in `SKILL.md` §3, in [`further-rules.md`](further-rules.md): *A mutation
aimed at a constant tests the constant*; *A payload chosen for being harmless is often exempt for
the same reason*; *A positive can be vacuous too*; *Assert the recovery property, not the mechanism
believed to deliver it*; *Probe the environment, never infer it*.
