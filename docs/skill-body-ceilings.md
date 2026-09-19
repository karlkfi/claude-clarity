# Skill body ceilings

`scripts/validate-skills.py` fails a skill whose `SKILL.md` body grew past its
ceiling. This file records why the ceiling is shaped the way it is and what
would reverse each choice. The rule itself, and the mechanism a reader needs in
order to apply it, stay in the script.

## Why a body has a ceiling at all

A skill body is loaded whole on invocation and then stays resident for the rest
of the session, so it is charged its size times the number of calls that follow
it. A kilobyte added to a body that fires early is paid about a hundred times in
that session, not once. Nothing in Claude Code reports this, which is why it
needs a gate.

## A tier, not a per-skill number

The ceiling comes from a residency tier rather than a number per skill:

| Tier | Resident calls per invocation | Ceiling |
|---|---|---|
| hot | over 100 | 24 KiB |
| warm | 50 to 100 | 16 KiB |
| cold | under 50, or never fired | 12 KiB |

A skill absent from `SKILL_TIER` is cold, which is the right default for one
with no residency reading behind it.

The alternative — a dict of byte budgets, one entry per skill — was tried first
and failed in a specific way. Growing a body past its entry meant editing one
line of that dict. Every raise was reviewed and the aggregate never was, because
no reviewer sees an aggregate. The gate asked *is this addition justified*, got
yes every time, and never asked what the addition displaced. A number is
negotiable in one line; a tier asserts a residency figure somebody can go and
re-measure.

**What would reverse it:** a measurement showing residency does not track
invocation frequency the way the tiers assume, at which point the bands are
measuring the wrong thing and the numbers behind them have to move together.

## Grandfathering, and why it only shrinks

The limit a body is held to is the looser of its tier ceiling and the size it
measured at the merge base. So the gate asserts one thing: no body grew past its
ceiling **on this branch**.

A body already over its tier ceiling is therefore frozen at what it measured on
`main` and may only shrink from there. There is no budget to raise. That is the
whole point of the shape: the per-skill dict it replaced was an escape hatch
with a review attached, and the review always passed.

`verify-claims` is the case that makes this visible. Its body is 110,854 bytes
against a 24 KiB hot ceiling, measured 2026-09-18 — it carries far more worked
cases than any other skill here, and the three files under
`skills/verify-claims/references/` are the split already in progress. It is
grandfathered shrink-only, so an addition to it has to name what it displaces.

Its residency is now measured rather than assumed, and the reading argues
against shrinking it to the band: of 88 rules, everything with no observable
uptake is 19% of the file, and the largest rule in it is the most used —
[verify-claims-residency.md](verify-claims-residency.md), and
`scripts/rule-residency.py` to re-take it.

**What would reverse it:** a body whose growth is genuinely a new tier rather
than an overrun, which is a tier reassignment rather than a raise.

## Why it fails rather than warns

The check names the exact number of bytes to take back out of the diff, so the
repair is mechanical and the actor can apply it without interrupting anybody.
Before this class moved off advisory, three bodies sat past their ceilings
across six commits and six gate runs, and the number was raised zero times — the
warning was correct, specific, and read by nobody.

The two warnings that remain in that script each leave a judgement inside the
fix. A description close to the 1024-character cap may be the right length for
what the skill still has to say. A dated claim in a body may be load-bearing
inside a worked example. Neither is something a script can settle.

**What would reverse it:** a repair that stops being mechanical, which would
mean the failure is asking the reader to decide something and belongs one tier
down.
