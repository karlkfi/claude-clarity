# Which parts of `verify-claims` get used

[Q1003](queue/Q1003.md) asks where the worked cases in a 110 KB skill body
should live, and says the decision needs a reading of which sections are
*consulted* versus *applied* before it needs an edit.
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
returns this table byte for byte, because the sessions added in between were
the ones working on this repo and the flags exclude them. The bare run is what
drifts: its `RAN`/`FLAT` boundary moved by one rule between two readings an hour
apart.

| verdict | rules | kB | what it means |
|---|---|---|---|
| `RAN` | 53 | 62.8 | fires in commands the session ran, at a higher rate than before the load |
| `SAID` | 14 | 15.2 | fires in prose only |
| `FLAT` | 7 | 8.0 | fires, but no more often after the load than before |
| `BLIND` | 14 | 12.6 | never fires anywhere in the corpus — a fact about the probe |

Three things the table settles.

**Size does not track use, so cutting by size cuts the top of the ranking.**
The largest rule in the file — *A negative needs a positive control*, 4.8 kB —
is also the most used, reaching 70 of 85 reader sessions. The second largest
reaches 3.

**The candidate set is 20.6 kB.** `BLIND` and `FLAT` together are 21 rules and
19% of the file. That is the most a defensible move could take, and it leaves
about 90 kB against a 24 KiB ceiling. Whatever settles Q1003, it is not this.

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
