# claude-clarity

Ten Claude Code skills and one output style for the last mile of agent work:
checking that what you are about to say is true, and writing it so somebody
else can act on it.

A skill is a folder of instructions Claude Code loads when the conversation
matches its description. An output style is instructions it sends with every
request, whether or not anyone asked.

Not a linter for your codebase and not a prompt library. These are review and
drafting passes Claude runs on prose: the docs, READMEs, release notes, issues,
PR bodies and commit messages an agent writes, plus the replies it gives you in
the terminal.

## Why you need it

Three things go wrong with prose an agent writes, and only the last one looks
like a writing problem.

**It tells you things it never checked.** A gate "passed" because its exit
status went through a pipe and the pipe reported `tail`. A grep returned nothing
because the flag was rejected, and the empty result read as a clean one. A
count quoted from recall. A file read in one checkout and reported as
another. The sentence
is fluent and the delivery is confident, and the evidence behind it could never
have shown you the opposite.

**It writes sentences that fall apart on a literal read.** Prose shaped like an
argument that holds no claim. Significance nobody measured. A range that sounds
like a spectrum and specifies nothing. You can tell something is off and not
what, because the register is doing the work the content is not.

**It pads.** Restating the question, narrating the route, three bullets holding
one idea each. Then a closing paragraph summarizing the paragraph above it.

`verify-claims` is the largest thing here by a wide margin: 63% of the skill
text by lines, measured 2026-09-14 over the ten bodies, their `references/`
files and the output style. A reader who cannot tell a measurement from a guess
cannot see what they are reading, however well-built the sentence.

Worth installing if you ship prose an agent helped write, or if you run more
than one session at once and reading the output is what limits you.

## The skills

[`substantiate`](skills/substantiate/SKILL.md) is the front door. It classifies
the document and its reader, runs only the passes that type needs, in the order
the passes themselves
declare, and reports what it skipped. It makes no edits of its own. It is also
the only one that routes to the others: the remaining nine cite their neighbours
but do not need them installed, so any one of them runs alone.

### Is it true?

| Skill | Owns | Fires on |
|---|---|---|
| [`verify-claims`](skills/verify-claims/SKILL.md) | Whether the evidence behind a statement could have shown you the opposite. Exit status lost through pipes and background chains, empty output from a command that never matched, a probe standing in for a gate, provenance read off resemblance. | A gate result about to be reported or trusted, a flake being chased, a grep or count about to justify a decision |
| [`claim-provenance`](skills/claim-provenance/SKILL.md) | Whether the author earned the claim. Scores each assertion's delivery against how it was actually obtained, then repairs the gap by cutting, downgrading, or going and getting it. | "are you sure", "how do you know", "where did that number come from", "that reads like you made it up" |
| [`semantic-remediation`](skills/semantic-remediation/SKILL.md) | Whether a sentence means anything. Twelve categories of prose that reads fluently and falls apart on a literal read. | "does this actually make sense", "this sounds smart but I can't tell if it's saying anything", "that sounds like an oversell" |

### Can anyone read it?

| Skill | Owns | Fires on |
|---|---|---|
| [`readability`](skills/readability/SKILL.md) | Whether a reader who did not do the work can follow it. Main point first, descriptive headings, one idea per paragraph, terms explained at first use, every number kept at full precision. | "this is confusing", "hard to follow", "my eyes glide right over it", "explain it simply" |
| [`brevity`](skills/brevity/SKILL.md) | How much should exist. Cuts whole units rather than compressing sentences, and stops at the floor where the reader has to reconstruct what you deleted. | "too long, shorten it", "feels verbose and defensive", "eating up the context window" |
| [`deslop`](skills/deslop/SKILL.md) | Register and vocabulary. A writing system to draft inside, and a tell catalog to lint against afterwards. | "deslop", "sounds like AI", "sounds like ChatGPT" |

### Where does it land?

| Skill | Owns | Fires on |
|---|---|---|
| [`tech-docs-layers`](skills/tech-docs-layers/SKILL.md) | What a doc contains and where it lives, across six layers of a repo's documentation. | A docs page that "is a giant wall of text", "keeps getting stale", or "doesn't link to docs pages enough" |
| [`code-restraint`](skills/code-restraint/SKILL.md) | Comment density, altitude and code shape, matched to the host file rather than to a house style. | "this reads as AI generated", "too many comments", "why all the try/catch", "match the existing style" |
| [`rendered-page-review`](skills/rendered-page-review/SKILL.md) | How a page reads rendered, at real viewport widths, skimmed rather than read. | "review the landing page", "how does this render", "it breaks on mobile", "the page feels dense" |

`deslop` and `readability` each ship a linter for the machine-checkable part of
their rules. The other eight are judgement, and a linter for them would emit
warnings a human has to adjudicate, which is a tier that measurably goes unread.

Each quoted phrase comes verbatim from that skill's `description`, the field
Claude Code matches against to decide whether to offer a skill. That matching is
the whole mechanism by which any of this runs.

## A skill only fires when something already in the context names it

Read this before installing, because it decides whether any of this runs.

Claude Code offers a skill by matching its `description` against what is
already in the conversation. The description is a matcher, not an
advertisement: it decides whether a skill fires *given* that its subject came
up, and it cannot make the subject come up. So a skill that should run on every
applicable occasion needs a line in a `CLAUDE.md` naming it. Writing the
description more sweepingly is the failure mode rather than the fix.

A bundle that ships without saying this ships a pile of files that will never
run, and its users conclude the skills do not work rather than that they were
never triggered.

**Name a moment, not a condition.** A line stating a standing property of the
repo fires on nothing, however true it is: every page under `docs/` is live,
this project's prose is public. Nothing re-reads a `CLAUDE.md` at the instant
its condition becomes true, so what fires a line is a reader reaching the
occasion it names and recognising it.

Measured 2026-09-14 over 2,117 session transcripts on one workstation: in a
repo whose `CLAUDE.md` names `rendered-page-review` for any change under
`docs/`, 162 sessions edited a published page and none invoked it, while all 11
of that skill's calls came from sessions somebody opened in order to review a
page. [`docs/decisions.md`](docs/decisions.md) has the counts and what weakens
them.

The cheapest way to name these is to name one of them. `substantiate` routes to
the other nine, so a single line reaches the set:

```markdown
When you have finished a draft someone outside the work will read — a doc,
README, release note, PR body, or post — and are about to hand it over, use
`substantiate`.
```

That is one such line and not the line. It names the moment those documents
change hands. A repo whose prose arrives some other way, at a release being cut
or a page about to be published, should name that occasion instead.

That covers review. It does not cover writing, and the difference matters:
`deslop` says to write *through* its system rather than run it afterwards as a
cleanup pass. Naming only the router leaves the drafting uncovered, so name
`deslop` separately for prose someone outside the work will read.

## The output style

[`output-styles/clarity.md`](output-styles/clarity.md) is what the repo is named
for, and it reaches the one surface that matching cannot. An ordinary reply
names nothing, so nothing invokes a pass on it, and you do not hand your own
chat message to a linter before sending it.

Two halves:

- **How much to write.** Open with the answer. Report outcomes, not the route.
  A short question takes a short answer. Error output, security findings and
  destructive-action confirmations are exempt and go out whole. So are the four
  things a short reply drops quietly: a step you skipped, a check you did not
  run, a number you did not verify, a result that came back partial.
- **Writing to the reader.** Give the observable rather than the mechanism, put
  consequence before identifiers, explain a term the first time it appears, keep
  every number and stated condition at full strength, and say how you know a
  thing when the reader might act on it.

The second half is `readability` Mode 5 and one rule from `claim-provenance`,
reworded to stand alone. The first half covers the same ground as Claude Code's
built-in **Concise** style without copying it, so it will not inherit
Anthropic's revisions to theirs. It sets `keep-coding-instructions: true`, which
is load-bearing: without it a custom style drops Claude Code's built-in
software-engineering instructions.

Only one style is active at a time and a style replaces the defaults rather than
layering on them, so this is a trade against whichever style you run now.
[output-styles/README.md](output-styles/README.md) has the rest, including why
subagents never see it.

## Installing

Clone anywhere and run:

```bash
scripts/install.sh
```

It links every skill into `~/.claude/skills/` and every output style into
`~/.claude/output-styles/`. Symlinks rather than copies, so `git pull` updates
everything installed at once. `--dry-run` reports what would change.
`--skills-target` and `--styles-target` install somewhere else.

It refuses to overwrite anything that is not one of its own links, because that
file is probably yours and probably the only copy; `--force` replaces it. A link
whose target is gone is the exception and is repaired on sight — there is no
copy there to protect.

It writes no settings file. Selecting an output style replaces whichever style
the machine runs today, so that stays your decision — the run prints the line
to add.

`scripts/install-skills.sh` is the skills half on its own, for a machine that
wants the skills and not the style. It spells the target `--target`.

**You do not have to take the set.** Naming skills as arguments installs only
those:

```bash
scripts/install-skills.sh verify-claims
```

That case is worth stating because `verify-claims` is not a prose skill. It
ships here because the bundle that ships first should hold it rather than every
consumer vendoring a copy and guaranteeing drift, and somebody who wants one
verification skill should not have to discover the shape of the bundle at
install time.

To skip a skill on this machine, list its name in
`~/.claude/skills/.install-skills-ignore`, one per line, with an optional
reason after the name. That file lives beside the install target rather than in
the tree, because which skills a machine wants is that machine's business and a
clone should not inherit somebody else's answer.

The style is linked but not active until a settings file names it. Claude Code
reads style files at startup, so restart afterwards.

```json
{ "outputStyle": "Clarity" }
```

## Where the content came from, and what it is true of

Every skill here was distilled from work that already happened: a production
system's failure record, a repo's own conventions, or a corpus of local session
transcripts. That is what makes the rules specific enough to be worth invoking,
and it is also the limit on them.

**The instruments are general. The findings are one workstation.** A figure
quoted inside a skill — a hit rate, a fire count, a number of transcripts — was
measured on one person's machine against one set of repositories. Re-run the
probe before treating any of it as a general result. The skills say how each
number was taken, which is the part that transfers.

Dates in a skill body are load-bearing where they mark a measurement and
decorative where they do not; `verify-claims` and `claim-provenance` both turn
that distinction on their own prose.

## Working on this repo

```bash
make check
```

That is `lint-sh` (shellcheck), `lint-py` (ruff, rules pinned to match CI),
`validate` (skill frontmatter, description length, script modes, and the
backlog store) and `test` (every `test-*.sh`). Each runs on its own too.
`make help` lists them.

[`docs/decisions.md`](docs/decisions.md) is why the repo is shaped the way it
is — one entry per decision, each naming what would reverse it. Read it before
undoing something that looks arbitrary.

Open work is in [`docs/queue/`](docs/queue/README.md), one file per item with
priority in each item's `rank` key rather than in a table. `scripts/queue.py`
and `scripts/alloc-queue-id.sh` are vendored copies maintained upstream — change
them there, or the next copy reverts your edit.

Needs `bash`, `python3`, `shellcheck`, and `pipx`. No network.

Every file list comes from `git ls-files --cached --others --exclude-standard`,
so a script you have just written is gated before you `git add` it. A tracked
file deleted with a bare `rm` stays in the lists and the linter then fails on a
path it cannot open. Stage the deletion.

## Why it is called that

> In the country of the blind, the one-eyed man is king.

The proverb is Erasmus. *Minority Report* borrows it for a dealer in an alley,
and hands over both the name and the pitch on the way there:

> **Lycon:** What's the matter, can't sleep?<br>
> **Anderton:** I just need a little clarity.<br>
> **Lycon:** True that. You want the customary, or the new and improved?<br>
> **Anderton:** I'll try the new stuff.

Lycon hands over the inhalers, then leans in with "in the land of the blind,
the one-eyed man is king" and lifts his shades to show the sockets. He sold his
eyes. Anderton buys a replacement pair off the same market later, because the
scanners only know him by the ones he was born with. Sight is a thing you can
trade away and a thing you can buy back, and what the buyer asks for is
clarity.

Anyone running several agents is somewhere on that market. The output goes past
faster than anyone reads it — a stream per session, every one of them narrating
its own work — so watching quietly stops being the same thing as seeing. Nobody
decides to stop reading. It costs more than sending the next prompt does, every
time, and the gap compounds.

One eye is the whole advantage. A session whose replies can be read at the
speed they arrive is one you are still supervising.

## License

MIT. See [LICENSE](LICENSE).
