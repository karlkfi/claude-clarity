# Counts

`SKILL.md` sends you here before a count, a total, or a population goes into a sentence or justifies a change.
An italicised rule name that is not in this file is in `SKILL.md` or in a sibling file under `references/`.

**A count asserts a population and a scan width.** Both go stale the moment the tree moves, and a scan you ran earlier in the session for another purpose does not transfer — re-derive the number as you write the sentence, and say what population it is true of.
Specifics:

- **A round total is a truncation until shown otherwise.** Paginated APIs answer with one page and still exit 0, so a query whose answer is a list quietly becomes a query about its first hundred entries.
  An exact 100, 30, or 1000 is the tell; an empty grep over that page is a correct search of the wrong population, which reads as a clean negative rather than an error.
- **An aggregate counter cannot count distinct participants.** `retries >= 3` is a claim about how many times, not how many actors — one actor in a loop satisfies it alone, and the looping actor is usually the fast path, so the threshold clears before the shape it names occurs.
  Give each actor its own counter and count the actors that moved.
- **A count grouped by symptom is not a measurement of cause.** A tool groups by whatever its normalizer could see, which is seldom what shares a mechanism.
  Re-derive along the axis the claim needs — time, construct, actor — and when the claim is causal, exercise the system that would produce the effect rather than counting records that correlate with it.
- **A total is bounded by what the instrument observes, and an event it never saw leaves no gap.** Establish the blind spots before quoting the number, because nothing in the output will.
  Quote a total with the shape it cannot see named beside it.

**The measurement that justifies a change is taken on the tree without the change in it.** *A count asserts a population and a scan width* has a number going stale because the tree moved; this is the case where your own branch is what moves it, so a census taken to argue for a diff is falsified by that same diff, and the two readings are a rebase apart.
Nothing marks the difference and nothing can go red: a gate reads the tree, while a number already written into a document is prose.
Seven figures went stale under one worker across five rebases with `make check` green through every one — a suite count, a store total that moved 54 → 53 → 54 → 55, an invisible-citation total, a documented highest ID — and one census was re-invalidated by its own thread three times before it landed.
Re-derive every figure against the head you are about to publish from, and where a figure counts a population your own diff edits, say which side of the change it is true of.

**A measurement of recent activity, taken while your own work is changing that system, samples your own work.** Everything else here has something wrong with the instrument.
This has nothing wrong with it — the scan is complete, the query is right, the figure reproduces — and the population it drew from is you.
That is why it survives the checks that catch the rest: a reviewer re-runs the query, gets the same number, and agrees, because the agreement is about the number while the defect is in what the number was *of*.
In one repository, of the 60 most recently merged pull requests, 7 still had their branch and 53 did not, splitting cleanly by recency.
Two sessions reproduced it independently and it shipped as evidence that merged branches are pruned eventually rather than at merge.
Nothing there prunes at all.
The 7 were the 7 that evening's own coordinator had merged, with a command that had stopped passing the delete flag.

**A ratio asserts two populations and two sampling rates, and nothing in the result marks a mismatch.** *A count asserts a population and a scan width* applies once per side, and a division hides whether it was done at all.
Where the two sides are not the same set, or are not emitted at the same rate, the quotient is fiction — and it fails in the interesting direction, so it reads as a finding rather than as a bug.
Two shapes, both from one afternoon.
Taking a complement over a tri-state category: counting everything that was not `healthy` as *blind* put eight of fifteen members blind, where a member can also report a real `degraded`, which is neither; counting the unassessable state by name gave three, matching a figure already recorded elsewhere, which should have been the tell.
Dividing counts emitted at different rates: one component logged a line per condition per cycle and another a line per cycle, so counting the first against a denominator of the second overstated by almost exactly the ratio of the two rates — forty-seven per cent against one point seven.
Before a ratio decides anything, write one line naming each side's population and emission rate, say which states are in the numerator rather than taking the complement of one, and reconcile against any independently derived figure that already exists.
A disagreement with a number already in the record is a bug in one of them, not a second finding.

**Filtering the population by the attribute the risk destroys drops the cases that already have it.** *A population read off the failure list is missing every case that recovered* reads the casualty list; this is its mirror, and the more comfortable mistake, because the filter sounds like precision.
A query for who is *at risk* that first restricts to members still exhibiting the thing at risk silently excludes whoever is furthest through the failure, which is the population the question was about.
Scoping a compatibility audit to hosts still advertising a working accelerator excluded the only host fleet-wide in the fatal combination — precisely because its accelerators were already gone — and returned *zero exposed*, which went into a report.
State the population before the filter, and ask of each filter term what it removes.
Run the risk query over everything reachable and carry health as a column rather than as a `WHERE` clause.
Unreachable is a third state and folding it into either arm is the same error again: an unprobed member reads as clean.

**A change delivered by a disruptive mechanism is confounded with that mechanism.** Everything above is about what a figure counts; this is about what a *comparison* attributes, where both sides are counted correctly and the difference belongs to the delivery rather than to the thing delivered.
Where entering the treatment arm requires a disruptive act — a restart, a drain, a migration, a cache flush — the arms differ by that act as well as by the change, and the act has its own transient.
Members returning to service run hot for a settling period and then converge, so a comparison that pools the settling period with the steady state measures the rollout.
One fleet-wide upgrade read as a three-fold regression pooled; split by time since each member's *own* transition, the entire excess sat in the first settling window and the settled rate was indistinguishable from baseline.
Four things make such a comparison mean what it says:

- Stratify on time-since-the-member-changed and report the settled stratum separately.
- Censor the settling window after a member joins or rejoins an arm.
- Measure exposure in *busy* units rather than wall-clock ones — a shrinking arm's stragglers are disproportionately idle or withdrawn, which hands that arm free safety.
- Match the exposure window to the event window exactly.
  A fourteen-day event list over a seven-day exposure series made the crude and stratified estimates point in *opposite* directions, which looks like Simpson's paradox and is a denominator bug.

When two aggregations of the same data disagree in direction, suspect the denominator before reaching for an interaction.

**A population read off the failure list is missing every case that recovered.** The bullets under *A count asserts a population and a scan width* are all about the instrument — what it never saw, what it grouped by, how far it scanned.
Here the instrument has no blind spot: it saw every case, and the count was taken from a view of its output that outcome had already filtered.
It is survivorship bias backwards — the survivors are absent because you are reading the casualty list, and every case on that list is real.
A finding about peers addressed by the title of the task chip that started them was derived from the listing of messages that never landed, which is filtered to the terminal failures, and found three.
Re-derived from the address-form classifier, which sees every send, the class had six members across five sessions.
The three that were missing had been retried under a real name and so never entered the casualty list — and they are what shows the failure is usually recoverable, which is the half that decides what the rule should say.

Two things make it expensive.
The finding survives a re-read, because it is true and merely smaller — three of those sends really were abandoned.
And it is invisible to review: the diff carries a clean finding rather than a missing half.
Neither a wider scan nor a second run of the same query reaches it, since both re-read the same filtered view.
What reaches it is re-deriving the population from a different starting point — the instrument's own unfiltered output, or a second instrument that sees the whole set — before the number decides anything.
