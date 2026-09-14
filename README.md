# claude-clarity

Ten Claude Code skills and one output style, covering the path from having
evidence to putting it in front of a reader.

Two audiences, and neither is the primary one: a public artifact carrying a
byline, and a working artifact carrying none, down to the replies a session
gives its own user.

## What is here

| Skill | Owns |
|---|---|
| [`substantiate`](substantiate/SKILL.md) | The front door. Classifies the document, selects which passes apply, runs them in order, reports what it skipped. Makes no edits of its own. |
| [`verify-claims`](verify-claims/SKILL.md) | Whether the evidence behind a statement could have shown you the opposite. Exit status lost through pipes, empty output from a command that never matched, provenance read off resemblance. |
| [`claim-provenance`](claim-provenance/SKILL.md) | Whether the author earned the claim. Scores each assertion's delivery against how it was actually obtained, then repairs the gap. |
| [`semantic-remediation`](semantic-remediation/SKILL.md) | Whether a sentence means anything. Twelve categories of prose that reads fluently and falls apart on a literal read. |
| [`readability`](readability/SKILL.md) | Whether a reader who did not do the work can follow it. Main point first, descriptive headings, terms explained at first use. |
| [`brevity`](brevity/SKILL.md) | How much should exist. Cuts whole units rather than compressing sentences, and stops at the floor where the reader has to reconstruct what you deleted. |
| [`deslop`](deslop/SKILL.md) | Register and vocabulary. A writing system to draft inside, and a tell catalog to lint against afterwards. |
| [`tech-docs-layers`](tech-docs-layers/SKILL.md) | What a doc contains and where it lives. |
| [`code-restraint`](code-restraint/SKILL.md) | Comment density and code shape, matched to the host file. |
| [`rendered-page-review`](rendered-page-review/SKILL.md) | How a page reads rendered, at real viewport widths. |

`deslop` and `readability` each ship a linter for the machine-checkable part of
their rules. The other eight are judgement, and a linter for them would emit
warnings a human has to adjudicate, which is a tier that measurably goes unread.

[`output-styles/clarity.md`](output-styles/clarity.md) is the output style the
repo is named for. It reaches the one surface a skill cannot: an ordinary reply
names nothing, so nothing invokes a pass on it. See
[output-styles/README.md](output-styles/README.md).

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

The cheapest way to name these is to name one of them. `substantiate` routes to
the other nine, so a single line reaches the set:

```markdown
When a draft needs checking over as a whole — a doc, README, release note, PR
body, or post that is written and needs a review pass — use `substantiate`.
```

That covers review. It does not cover writing, and the difference matters:
`deslop` says to write *through* its system rather than run it afterwards as a
cleanup pass. Naming only the router leaves the drafting uncovered, so name
`deslop` separately for prose someone outside the work will read.

## Installing

Clone anywhere and link each skill into `~/.claude/skills/`:

```bash
scripts/install-skills.sh
```

Symlinks rather than copies, so `git pull` updates every installed skill at
once. `--dry-run` reports what would change. `--target` installs somewhere
other than `~/.claude/skills`. Naming skills as arguments installs only those.

To skip a skill on this machine, list its name in
`~/.claude/skills/.install-skills-ignore`, one per line, with an optional
reason after the name. That file lives beside the install target rather than in
the tree, because which skills a machine wants is that machine's business and a
clone should not inherit somebody else's answer.

The output style installs separately:

```bash
ln -s "$(git rev-parse --show-toplevel)/output-styles/clarity.md" ~/.claude/output-styles/clarity.md
```

Then set it in a settings file. Claude Code reads style files at startup, so
restart afterwards.

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

Open work is in [`docs/queue/`](docs/queue/README.md), one file per item with
priority in each item's `rank` key rather than in a table. `scripts/queue.py`
and `scripts/alloc-queue-id.sh` are vendored copies maintained upstream — change
them there, or the next copy reverts your edit.

Needs `bash`, `python3`, `shellcheck`, and `pipx`. No network.

Every file list comes from `git ls-files --cached --others --exclude-standard`,
so a script you have just written is gated before you `git add` it. A tracked
file deleted with a bare `rm` stays in the lists and the linter then fails on a
path it cannot open. Stage the deletion.

## License

MIT. See [LICENSE](LICENSE).
