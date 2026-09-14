# CLAUDE.md

Guidance for Claude Code when working in this repository.

## What this repo is

A bundle of ten skills and one output style, extracted from a larger private
collection. Each skill lives in its own top-level directory and contains a
`SKILL.md` that Claude Code loads whole on every invocation.

```
skills/<skill-name>/
  SKILL.md        # required: frontmatter plus the instructions Claude follows
  references/     # optional: read on demand, named by the body
  scripts/        # optional: bundled executables and their tests
```

Skills sit under `skills/` because that is the layout a Claude Code plugin
needs, and every plugin installed on this machine uses it. `install-skills.sh`
defaults to that directory and falls back to the repo root, so a clone laid out
the older way still installs.

`SKILL.md` frontmatter carries `name` (matching the directory) and
`description`. The description is the trigger signal surfaced in the
`available-skills` reminder, and it is capped at **1024 characters** — a longer
one is rejected and the skill never loads. `scripts/validate-skills.py`
enforces the cap and warns with the measured count once a description is within
20 characters of it. Ask for the number rather than refolding the block scalar
by hand:

```bash
scripts/validate-skills.py --report deslop
```

## What a `SKILL.md` carries, and what a companion doc carries

A skill is loaded whole on every invocation. A doc about it is read only when
someone changes it. So the split is by job.

**The skill carries what a reader needs in order to apply the rule, including
mechanism.** Why an instruction works, and why the obvious alternative silently
breaks, is what stops the next session tidying the rule away.

**The companion doc under `docs/` carries provenance** — the date, the counts,
what the project used to believe, and what would reverse the decision. A skill
with no such doc puts provenance in the commit message and the PR body.

The failure is quiet in both directions. Provenance in a skill costs tokens on
every invocation and goes stale invisibly. Mechanism stripped out of one leaves
a rule that reads as arbitrary and gets improved away by the next session to
touch it.

## Descriptions are matchers, not advertisements

A skill fires when something already in the context names it. The description
decides whether a skill fires *given* that its subject came up; it cannot make
the subject come up. Two things follow.

**Harvest trigger phrasings from real transcripts, never invent them.** Invented
phrasings read plausible and get typed by nobody. What people type is blunter
and shorter than what a description writer reaches for.

**A phrase common enough to appear everywhere carries no signal.** Score a
candidate in both directions: of the sessions offered the skill and containing
the phrase, how many fired it; and of the skill's calls, how many are
immediately preceded by a human turn containing it.

**Rewrite descriptions one skill at a time.** A script that substitutes text
across several `SKILL.md` files at once hits neighbours silently, because
skills here deliberately share phrasing about each other.

## Scripts that encode a skill's rules

When a bundled script mechanizes rules the `SKILL.md` also states in prose, the
same knowledge lives in two places and will drift. Test that the two agree, and
prefer a behavioral check over comparing the two lists as strings: a script
legitimately carries inflections and variants the prose does not spell out, and
a string diff flags all of that as drift and gets deleted for crying wolf.
[`skills/deslop/scripts/test-catalog-sync.sh`](skills/deslop/scripts/test-catalog-sync.sh)
turns each documented tell into a one-line input the linter must flag.

**Warn where a human has to settle it; fail only where the script is certain
and the repair is mechanical.** A warning whose repair is one mechanical edit is
a failure wearing the wrong tier — where the fix can be written into the
message, the actor applies it and nobody is interrupted. A warning that needs a
judgement made inside it is the right shape, and should still expect to go
unread.

**Validate a checker against a real document it was derived from, not only
fixtures.** Fixtures encode what the author already thought of. Run the finished
linter over the document its rules came from, keep a clean fixture as the
false-positive guard, and confirm the checker fails on something before trusting
it to pass on anything.

## Before stating a result, use `verify-claims`

Any sentence reporting an outcome is a claim, and the question to answer first
is whether the evidence behind it could have shown the opposite. The skill is in
this repo. Use it on this repo.

The shapes that recur here: a local read standing in for a remote one, a partial
namespace read as the whole, someone else's data read through your own schema, a
count that a change in the same commit invalidated, and source read in place of
a run.

## Running the gates

```bash
make check
```

`lint-sh`, `lint-py`, `validate`, `test`. CI calls the same targets, so adding a
gate is one edit to the Makefile. A command inlined into `.github/workflows/`
instead is a second copy `make check` will not run.

`validate` also lints the backlog store under `docs/queue/`. `scripts/queue.py`
and `scripts/alloc-queue-id.sh` are vendored copies: they are maintained in
another repository and updated here by copying the file again, so a fix written
here is silently reverted by the next copy.

The body-ceiling check inside `validate` grandfathers each skill at the size it
measured on the merge base, so a clone with no `origin/main` skips it loudly
rather than measuring against zero.

## Commits

- Commit after each task is complete and validated.
- Small, focused commits, following Conventional Commits.
- Amending an unpushed commit is fine. Once pushed, prefer a follow-up commit.
