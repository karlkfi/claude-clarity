# Negatives and controls

`SKILL.md` sends you here before a zero, an empty result, a near-total, or an answer that never varies decides anything. An italicised rule name that is not in this file is
in `SKILL.md` or in a sibling file under `references/`.

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
  "correctly skipped" are the same row by construction. `gh run list --commit` fixes *which
  commit*, which is why it reads as the guarded form, and says nothing about *which job*.
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
measurements behind that: [`references/shell-traps.md`](shell-traps.md).

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
provider not listed: [`references/status-pages.md`](status-pages.md).
