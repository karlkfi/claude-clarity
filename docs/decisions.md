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
which parts of `verify-claims` sessions actually use
([verify-claims-residency.md](verify-claims-residency.md)),
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

The entry above settles why the evidence half is the largest half: the name is
an outcome and verification serves it. This entry is the narrower question of
why the skill lives in *this* repo rather than one of its own, and the answer is
packaging, not theme.

Two alternatives were considered and both are worse. Vendoring a copy into each
consumer guarantees drift, and nothing on either side reports it. Declaring a
dependency on it needs it published somewhere first, which is the problem
restated. Putting it in the bundle that ships first satisfies both.

The cost is real and lands on someone else: a reader who wants one verification
skill installs the whole bundle to get it. `install-skills.sh` takes skill
names, so the single-skill install works, and the README says so under
[Installing](../README.md#installing).

**What would reverse it:** a second consumer needing `verify-claims` for reasons
unrelated to a draft anyone reads. At that point it is infrastructure shared by
three parties and belongs in a repo of its own.

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

## Naming a skill is what moves its trigger count

Two of the ten were measured dead in the collection this came from. On
2026-08-17, over 678 local transcripts, `readability` had one lifetime
invocation and none since its description was rewritten from transcript
vocabulary the day before; `rendered-page-review` had none ever. Both are live
now. Re-counted 2026-09-14 over 2,117 transcripts — one workstation's
`~/.claude/projects/`, not this tree — `readability` has 12 lifetime and 11
since 2026-08-16, and `rendered-page-review` has 11, all since 2026-08-18.
Sessions in this repo and in the collection account for one call each, so
neither count is a skill being exercised by the people building it.

The second skill is the readable case, because its two levers were never
confounded. Broadening its description on 2026-08-16 produced nothing for two
days. Ten of its eleven calls then came from `github-actions-gateway`
worktrees, and that repo's `CLAUDE.md` names the skill at a moment: a change
under `docs/` is a change to a live web page, so review it with
`rendered-page-review`. The global `CLAUDE.md` still mentions the skill exactly
once, as the subject of the original measurement, which is a citation and fires
nothing.

So the README's claim survives its cleanest available test, though not by the
mechanism that line states. A description decides whether a skill fires once
its subject is in the context; naming it in a loaded `CLAUDE.md` is what puts
the subject there. What the naming did was put the skill's name within reach
of a session whose purpose was already a review — see the occasion counts
below, where the stated condition fires nothing. Broadening a description is
still not the fix.

The count above is of invocations. Counting the *occasions* instead, the same
day and corpus, says the shape of the naming line is what carries it. In
`github-actions-gateway`, 162 sessions edited a page that repo publishes and
none fired `rendered-page-review`, though its `CLAUDE.md` names the skill for
exactly that condition; all 11 of the skill's calls come from sessions that
edited no Markdown at all. `tech-docs-layers`, named in no `CLAUDE.md` on that
machine, fired in 2 of the 65 sessions that rewrote eight or more
documentation pages. So a line naming a skill at a moment somebody notices
fires, and a line naming it as a standing property of a file path does not —
nothing re-reads a `CLAUDE.md` when its condition becomes true.
The README's install guidance says so, and its sample line was rewritten into
the first shape (Q1007).

The join there is session-level, so an occasion is "edited a published page"
rather than "needed a viewport review", and a typo fix counts. Only
`Edit`/`Write`/`MultiEdit` were counted, so a page changed through `sed` is
invisible and the denominators understate, which puts the true rates below the
ones quoted.

**What would reverse it:** a re-count in which a skill named at a moment in a
loaded `CLAUDE.md` stays at zero, or one in which a skill named nowhere climbs
on a description rewrite alone.

## The hook ships from here, not from the guard repo

`clarity-reminder` is a `PreToolUse` hook and so is every guard in
`claude-bouncer`, which makes the mechanism a bad way to route it. The goals
differ: a guard denies an action that is wrong on its own terms, and this one
raises how often a pass runs when it applies. It ships with the skills it
serves.

The naming entry above says the lever saturates; the occasion counts say where.
`code-restraint` ran in 13 of the 531 sessions that edited a source file and
committed, and in 2 of the 138 that edited five or more — the rate falls as the
diff grows, which inverts what you would want. A `CLAUDE.md` reaches a session
at startup and nothing re-reads it when its subject arrives, so the hook is the
rung that fires on the occasion rather than on recall.

**It denies rather than asks**, per `hook-verdict`'s routing test: the fix can
be written into the reason, and the model is the actor who has to run the pass.
A deny's reason arrives as the tool error, so it reaches the model; an approved
ask returns as an ordinary tool result and teaches the session nothing. The
`supervise` posture turns denies into prompts for anyone who wants to watch, and
it is opt-in because the default spends model tokens where the alternative
spends a person's attention.

**The plugin manifest sits beside `install.sh` rather than replacing it.** A
hook cannot reach a machine any other way without hand-editing a settings file,
and the entry below on the installer writing no settings survives intact because
nothing about that path changes. A directory serves as a marketplace — measured
2026-09-14 by adding one with no remote, installing a plugin whose source was a
relative path, and removing both — so neither the hook nor the skills wait on a
publishing decision (Q1001, Q1008).

**What would reverse it:** a repo where the hook fires on occasions that did not
want the pass, often enough that the deny reads as a tax rather than a
reminder. The per-repo rule file is the first response to that and a retirement
is the second.

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

## The install is one entry point, and it does not write settings

`scripts/install.sh` links the skills and the output styles;
`scripts/install-skills.sh` is still the skills half on its own, and is what the
umbrella calls.

The alternative was leaving the style to a documented `ln -s`. That is one file
and no conflict cases, so a script for it looked like ceremony — and the
one-liner in the README assumed `~/.claude/output-styles/` already existed,
which on a machine that has never set a style it does not. The argument that
settled it is the other direction: with two published commands, anybody who
already knows `install-skills.sh` installs half the repo and gets a success
message for it. The umbrella suppresses that script's pointer back to itself
when it is the caller, because the note is addressed to someone who ran it
directly.

It writes no settings file. Linking a style makes it available, not active, and
the line that activates it — `{"outputStyle": "Clarity"}` — replaces whichever
style the machine runs today, since only one is ever active and a style replaces
the defaults rather than layering on them. That is the machine's call, not a
clone's, so the run prints the line and stops.

It also refuses skill names, so `install.sh verify-claims` is an error naming
`install-skills.sh`. The passthrough worked, and it meant a command asking for
one skill also installed a style, which is a second spelling of a partial
install.

One case is exempt from `--force`: a link whose target no longer exists. That
guard is there to stop the install destroying somebody's only copy of a skill or
a style, and a dangling link is not one. Found by running the installer for real
— `~/.claude/output-styles/clarity.md` pointed into a repo that had been renamed,
and `settings.json` had selected `Clarity` all along, so the style was both
active and unreadable. Refusing there would have spent a decision on a file that
could not be read either way.

**What would reverse it:** a second output style arriving with a real reason to
install one and not the other, or Claude Code growing a way to activate a style
that is not a mutually exclusive settings key.
