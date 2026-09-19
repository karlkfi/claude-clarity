# Which parts of `verify-claims` get used

Q1003 asked where the worked cases in a 110 KB skill body should live, and said
the decision needed a reading of which sections are *consulted* versus
*applied* before it needed an edit. [decisions.md](decisions.md) settles it and
[Q1014](queue/Q1014.md) is the move.
[`scripts/rule-residency.py`](../scripts/rule-residency.py) is that instrument.
This file is the reading it produced and the bounds on it.

**The short answer: the body is used, and moving everything with no measurable
uptake recovers 20.6 kB of 110.9 kB.** A 24 KiB ceiling is not reachable by
relocating unused material, because there is not enough of it.

## What the instrument can see

A skill body loads whole, so nothing records which part of it a session read.
What is recorded is what the session then wrote and ran, under
`~/.claude/projects/`. The probe takes each rule — one bold-lead paragraph —
and counts where that rule's own vocabulary reappears afterwards, against the
same sessions before the body was loaded.

Two loci, because they answer different questions. `action` is a tool_use
input: the session ran a command carrying the rule's vocabulary, which for a
rule that ships a command is evidence of the rule being applied. `prose` is
assistant text and thinking, which is consistent with applying the rule and
equally with quoting it.

**It cannot see consultation.** A rule read and correctly judged not to apply
leaves what a rule never read leaves: nothing. So the row's consulted/applied
split is not measurable from transcripts, and this is a reading of *uptake* —
how often a rule reaches a session's output — standing in for it.

Sessions in `claude-clarity` and `claude-skills` are counted separately. A
session editing `SKILL.md` quotes every rule in it, which scales with how much
work went into the file rather than with anything about a reader.

## The reading

```bash
scripts/rule-residency.py skills/verify-claims/SKILL.md \
    --repo claude-clarity --repo claude-skills
```

**Both `--repo` flags are load-bearing.** `verify-claims` is maintained across
two checkouts, and the default names only the one holding this working tree —
so a bare run leaves 7 `claude-skills` authoring sessions in the reader corpus
and reports 26 rules and 26.0 kB where the table below says 21 and 20.6 kB. The
run prints the names it segregated on as its first line; read that before the
numbers.

Measured 2026-09-18 against `1858849`, over the 94 sessions under
`~/.claude/projects/` carrying a `Skill(verify-claims)` call: 85 reader
sessions and 9 authoring ones. 88 rules, 98.6 kB of the 110,854-byte file.

The corpus grows as sessions run, so re-run rather than quoting these counts
later. Re-taken at 11:32 PDT with the corpus two hours larger, the flagged run
returned this table byte for byte. **That reproduction did not survive the
next day and the paragraph below is the correction**: the `BLIND`/`FLAT`
boundary moves under the flagged run too, and only the union of the two is
stable. The bare run drifts in the same place, one rule between two readings an
hour apart, so it was never the distinguishing symptom it reads as here.

| verdict | rules | kB | what it means |
|---|---|---|---|
| `RAN` | 53 | 62.8 | fires in commands the session ran, at a higher rate than before the load |
| `SAID` | 14 | 15.2 | fires in prose only |
| `FLAT` | 7 | 8.0 | fires, but no more often after the load than before |
| `BLIND` | 14 | 12.6 | never fires anywhere in the corpus — a fact about the probe |

**Re-taken 2026-09-19 at `6b88023`: the candidate set holds and the split does
not.** The union of `BLIND` and `FLAT` came back byte-identical — the same 21
rules, 21,120 bytes, 19.05% — with a symmetric difference of zero against the
reading above. The split between the two moved inside one hour on that same base
tree: `BLIND` 14 / `FLAT` 7, then 10 / 11, then 8 / 13. The reader arm did not
move off 85.

**So quote the union and never the split — which means the `BLIND` and `FLAT`
rows of this table are not quotable on their own.** Their `rules` and `kB` cells
are exactly where the moving figures live; what survives is those two rows
added together, 21 rules and 21,120 bytes. The `RAN` and `SAID` rows held across
both readings, but two readings is not a stability claim and this file does not
make one for them.

**The `--repo` flags cannot protect that boundary, by construction.** The
instrument says so in two lines: `corpus = sum(c.values())` sums every arm, and
`if row["corpus"] == 0: return "BLIND"`. Its own docstring is explicit —
*"corpus: every firing anywhere, PRE and POST and authoring sessions alike"*. So
segregating the authoring sessions changes which arm a firing lands in and never
whether one happened. Measured over the six rules that
left `BLIND` between two readings of one base tree: every one has its entire
count in the authoring arm and **zero** in the reader arm (2, 1, 2, 6, 1, 7 and
13 authoring firings against 0 reader firings apiece). The flags protect `RAN`,
`SAID` and `FLAT` from authoring contamination and leave `BLIND` fully exposed.

**And it is a ratchet, not a fluctuation.** Transcripts accumulate and corpus
counts are cumulative, so on a fixed base tree a rule leaves `BLIND` and never
returns: 14/7 → 10/11 → 8/13 is one-way. Re-taking it will not average out, and
a later reading is not a better estimate of the same quantity.

This is the skill's own *a measurement of recent activity, taken while your own
work is changing that system, samples your own work*, and it is not abstract
here: of the fourteen rules originally `BLIND`, the six that stopped being so
include all four that this repo's own backlog rows cite by name — the rules a
review spent an hour quoting are the rules that left. The reading is in its own
data.

**The bare run on that same tree** reports 92 reader sessions and 26 rules at
26,639 bytes — 24.03%. The seven-session gap is the `claude-skills` authoring
sessions, exactly as the warning above predicts.

**A bare run was read as this table on 2026-09-19**, which is what the warning
above is for and the only instance recorded here. Its five extra low-uptake
rules — `FLAT` 7 against 12, `BLIND` 14 either way — were taken for a corpus
effect, and the control run against that reading passed `--repo claude-clarity`
explicitly against leaving it implicit. That is one repo either way, so it
varied the term and never the cause, which is the number of repos segregated.
Read the run's own first line before its numbers: a bare run names one repo
there.

**The two candidate sets are not nested, so neither stands in for the other.**
`Provenance is a claim, and one of the cheapest to settle` is `FLAT` under the
flags and `SAID` without them, so it is in the 21 and not in the 26. Clearing a
span against the bare reading does not clear it against this one.

Three things the table settles.

**Size does not track use, so cutting by size cuts the top of the ranking.**
The largest rule in the file — *A negative needs a positive control*, 4.8 kB —
is also the most used, reaching 70 of 85 reader sessions. The second largest
reaches 3.

**The candidate set is 20.6 kB.** `BLIND` and `FLAT` together are 21 rules and
19% of the file. That is the most a defensible move could take, and it leaves
about 90 kB against a 24 KiB ceiling — so relocation does not reach the tier
ceiling, which is a true reading of a question nobody needed answered. The gate
grandfathers this body at its merge-base size rather than at the ceiling, so
what an addition needs is room. Room is made and spent inside one branch: the
baseline is re-read per branch, so a shrink that merges makes main's smaller
size the new limit and banks nothing for later.
[decisions.md](decisions.md) has the argument and the measurement.

**Most rules reach few sessions, and that is the shape of a reference work.**
The median rule reaches 4 of 85; 25 rules reach 10 or more. A rule nobody needed
this quarter is not a rule nobody needs.

## The control, and what it caught

The first build keyed each rule on word sequences unique to it *within the
body*. It reported 43 rules unmeasurable, including *A negative needs a positive
control*, which the skill's own text calls the sharpest rule in it.

Firing the probe at a phrase known present in the corpus is what refuted that:
`positive control` appears 546 times across 73 of 85 reader sessions after the
load, against 45 times in 10 sessions before it. The uniqueness filter had
deleted exactly the vocabulary each rule is known by, because this body cites
its own rules constantly — so the phrase a reader reaches for was never a
marker. Re-keyed on each rule's lead, the same rule tops the table.

The lesson is the one the skill states: a control drawn from inside the
thing it is testing cannot fail. `--self-test` checks the matcher against the
file the markers came from, which is why it passed on the broken build and
says so in its own output.

Two further corrections, both from the skill's own rules. Comparing raw hit
counts made `POST` look busier than `PRE` because it is the longer window —
3.33× by action blocks — so the verdict compares rates, which moved ten of 88
verdicts one tier. And a bold span at the start of a wrapped line is not a rule
lead; requiring one to open a paragraph dropped five phantom rules.

## What would reverse this

A rule reaching zero sessions here has not been shown to be unused — the probe
cannot see a rule applied in the reader's own words. The reading is a ranking to
argue from, not a verdict, and the argument it currently supports is that the
ceiling is the wrong target for this file.

An instrument that could settle consulted-versus-applied would need a signal the
transcript does not carry: which part of a resident body a turn attended to.
Nothing in Claude Code reports it today. If that changes, re-take this reading
before quoting these numbers.
