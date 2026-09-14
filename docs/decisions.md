# Decisions

Why this repo is shaped the way it is. One entry per decision, each naming what
would reverse it — a decision nobody can retire is indistinguishable from a
rule, and the next maintainer should not have to re-derive the argument from
scratch.

Figures here were measured on 2026-09-13 against this tree unless the sentence
says otherwise. Two are inherited from the extraction record and say so; they
were taken over one person's local session transcripts and are not a general
result.

Settled elsewhere and not repeated here: why a body has a ceiling and why that
check fails rather than warns ([skill-body-ceilings.md](skill-body-ceilings.md)),
why the backlog has two ID blocks ([queue/README.md](queue/README.md)), why
`semantic-remediation` is shaped as it is
([semantic-remediation-decisions.md](semantic-remediation-decisions.md)), and why
gates live in the Makefile ([CLAUDE.md](../CLAUDE.md)). One explanation in one
place; a second copy is a thing that drifts.

## The repo is named for the output style, not for the skills

The name comes from the style the repo ships, which takes its own from the line
Anderton gives a dealer in *Minority Report*. [The style's
README](../output-styles/README.md) has that story; this entry is about the
choice.

An earlier name was the name of a skill *inside* the bundle, so "run
substantiate" was ambiguous about whether you meant the repo or the front door.
The criterion that replaced it was *survive the weighted reading*. Measured
2026-09-13 over the ten skills, their `references/` files and the output style:
`verify-claims` alone is 64% by lines and 57% by bytes, and the three evidence
skills — `verify-claims`, `claim-provenance`, `semantic-remediation` — are 73%
and 66%. By skill count they are 3 of 10, which is the reading that makes this
look like a prose collection. Both readings are honest and they point opposite
ways, so quote the method with the figure.

A name on the craft rung therefore misdescribes most of the artifact. `clarity`
names an **outcome** rather than an activity, and the evidence skills serve it:
a reader who cannot tell a measurement from a guess cannot see what they are
reading, however well-built the sentence.

**What would reverse it:** a reading under which verification stops serving
clarity and starts competing with it — an evidence half that grows into an audit
tool nobody invokes for a reader's sake. At that point the outcome the name
promises is no longer the one the majority of the artifact delivers.

## `verify-claims` ships here rather than standing alone

It is the largest thing in the repo and it is not a prose skill, so it looks
like a guest. Two alternatives were considered and both are worse. Vendoring a
copy into each consumer guarantees drift, and nothing on either side reports it.
Declaring a dependency on it needs it published somewhere first, which is the
problem restated. Putting it in the bundle that ships first satisfies both.

The cost is real and lands on someone else: a reader who wants one verification
skill installs a repo of prose passes to get it. `install-skills.sh` takes skill
names, so the single-skill install works, and the README says so under
[Installing](../README.md#installing).

**What would reverse it:** a second consumer needing `verify-claims` for reasons
unrelated to prose. At that point it is infrastructure shared by three parties
and belongs in a repo of its own.

## The repo starts at one commit and carries no history

The skills have years of argument behind them and none of it is in `git log`.
That was measured rather than chosen: of the 97 commits touching these paths in
the collection they came from, **96** had a private skill or repository name in
their *file contents* — 353 sightings of one withheld skill across 69 distinct
blobs — alongside 59 commit messages naming one.

Filtered history and *names nothing private* could not both hold. Rewriting the
blobs to satisfy the second would have made the log disagree with its own diffs:
the commit that says it inverted eight citations would show a diff that does
nothing. A log you cannot trust is worse than no log.

The dated claims inside each skill are their own provenance, and they say how
each number was taken, which is the part that transfers.

**What would reverse it:** the origin collection becoming public, after which a
filtered import costs nothing and can be grafted under the initial commit.

## Skills live under `skills/`

Not tidiness. It is the layout a Claude Code plugin needs, confirmed by reading
the plugins installed on this machine rather than assumed — each keeps its
skills at `<plugin>/<version>/skills/<name>/SKILL.md`. Moving after publishing
would cost the same rewrite plus everyone's links.

`install-skills.sh` prefers `skills/` and falls back to the repo root, so a
clone laid out the older way still installs. Both arms are asserted in
`scripts/test-install-skills.sh`; removing the preference fails them.

**What would reverse it:** deciding the repo will never ship as a plugin, at
which point the fallback makes moving back a rename.

## The voice slot is declared and never filled

Five skills hand voice to "a personal voice skill, if one is loaded" without
naming one — nine declarations between them, measured 2026-09-13 — and nothing
here ships a holder. That reads like an omission and is a constraint.

The skill that used to fill it models one identifiable person's voice closely
enough that publishing it would hand strangers a tool for impersonating them.
That is a reason to withhold permanently, not to defer, and no relabelling
changes what the artifact does. Repointing the citations at a replacement would
have made building that replacement a prerequisite of the whole bundle; naming
the role instead costs nothing and leaves the bundle citing no skill it cannot
ship.

So: a future skill reaching for a voice pointer **declares the slot** rather
than naming a holder.

**What would reverse it:** a skill that *derives* a style guide from a corpus
the user supplies — the generalisation of how the withheld one was built. Each
user would end up with their own voice layer and nobody with someone else's, and
the slot would have a default holder worth naming.

## Two passes have a linter; three were refused

`deslop` and `readability` ship one. `semantic-remediation`, `claim-provenance`
and `tech-docs-layers` were considered and refused, because each would emit
warnings a human has to adjudicate — a tier measured going unread in the
collection this came from, at three bodies sitting past their ceilings across
six commits and six gate runs with the number raised zero times.

The pair that makes a linter worth building is *certain* **and** *mechanically
repairable*. `readability`'s covers the one rule its own body calls checkable
and refuses the other two, which need to know what the reader already has.

A bundled script is also not a second way into the bundle. Taken from the
extraction record rather than re-run here: over 1,922 transcripts the `deslop`
linter ran 39 times outside its home repo, and 35 of those were sessions where
the skill had fired. It makes a pass that already fired better; it does not
reach past the naming problem.

**What would reverse it:** one of the three finding a rule that is certain and
has a mechanical repair. [Q1006](queue/Q1006.md) is the pass that goes looking,
and records a null result as a result.

## An exhibit may dangle; an instruction may not

The rule that decided several edits during the extraction, and it binds every
future one.

A **measurement** names its subject, and the subject is fixed. Re-pointing a
path inside a recorded run misreports what was run, so two paths in
`verify-claims` were deliberately left naming files this repo does not hold — a
`gh pr diff` pathspec and a 180-ref brace sweep. Provenance that dangles costs a
reader only a lookup they were never going to make.

An **instruction** is the opposite: a dangling path there costs them the
command. Those get fixed.

The split is not always obvious, and [Q1005](queue/Q1005.md) is the case that
sits on the line — a runnable fence whose prose frames it as the author's own
gate and whose next sentence tells the reader to run it.

One more distinction inside the first: a measurement of a *historical event*
cannot be re-run, so attribution is the only honest move. A measurement of a
*reproducible law* is pinned to nothing but its own conditions and should be
re-taken against something generic.

**What would reverse it:** nothing about the rule. What changes case by case is
which kind a given passage is, which is why each one is argued rather than
pattern-matched.
