# Counts

`SKILL.md` sends you here before a count, a total, or a population goes into a sentence or justifies a change. An italicised rule name that is not in this file is
in `SKILL.md` or in a sibling file under `references/`.

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
