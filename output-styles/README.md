# Output styles

An output style changes the instructions Claude Code sends with **every** request. That is the one thing a skill cannot do: a skill fires when something in the context names it, and an ordinary reply names nothing.

Everything after a style file's frontmatter reaches the model as instructions, so notes about the file go here rather than in it.

## Clarity

> In the country of the blind, the one-eyed man is king.

`readability` Mode 5 is written for "escalations, questions to the user, impact summaries, and any explanation for someone who will not open the code" — the replies a session gives its own user. Nothing invokes a pass on those. You do not hand your own chat message to a linter before sending it, so the rules never reach the surface they were written for.

`clarity.md` is that surface. Two halves:

- **How much to write** — open with the answer, report outcomes rather than the route you took, and keep structure out of prose that has none. Error output, security findings and destructive-action confirmations are exempt and go out whole.
- **Writing to the reader** — give the observable rather than the mechanism, put consequence before identifiers, explain a term the first time it appears, keep every number and stated condition at full strength, and say how you know a thing when the reader might act on it.

The second half is `readability` Mode 5 and one rule from `claim-provenance`, reworded to stand alone. The first half covers the same ground as Claude Code's built-in **Concise** style and is not a copy of it — the rules are ours, so this will not inherit Anthropic's revisions to theirs, and it is deliberately not named after it.

### Installing it

Save the file at one of three levels, then name it in a settings file. The filename is the style name unless the frontmatter sets `name`, and this one does.

```bash
ln -s "$(git rev-parse --show-toplevel)/output-styles/clarity.md" ~/.claude/output-styles/clarity.md
```

```json
{ "outputStyle": "Clarity" }
```

`~/.claude/output-styles/` is the user level and `.claude/output-styles/` the project level. In the terminal, `/config` offers a picker under **Output style**; the desktop app has no picker, so set `outputStyle` directly. The standalone `/output-style` command was removed in v2.1.91.

Claude Code reads style files at startup, so restart after creating or editing one.

### Three things worth knowing before you switch

**`keep-coding-instructions: true` is load-bearing.** It defaults to false, and without it a custom style drops Claude Code's built-in software-engineering instructions — how to scope a change, write comments, and verify work. This style sets it.

**Only one style is active at a time, and a style replaces the defaults rather than layering on them.** So this is a trade against whichever style you run now, not an addition to it. Use `CLAUDE.md` for anything that should layer instead.

**Subagents never see it.** A style applies to the main conversation and to a fork, which inherits the parent's system prompt. Other subagents run their own, so a dispatched session gets whatever its own settings say.

A style's instructions are sent on every request, which prompt caching makes cheap after the first. The budget pressure is the same one the skill bodies are under, one level up: what goes here is paid every turn, so it has to be worth that on a turn where it does not apply.

## Why it is called that

The proverb is Erasmus. *Minority Report* borrows it for a dealer in an alley, and hands over both the name and the pitch on the way there:

> **Lycon:** What's the matter, can't sleep?
> **Anderton:** I just need a little clarity.
> **Lycon:** True that. You want the customary, or the new and improved?
> **Anderton:** I'll try the new stuff.

Concise is the customary. This is the new and improved — the same brevity, plus the half that makes what survives readable.

Lycon hands over the inhalers, then leans in with "in the land of the blind, the one-eyed man is king" and lifts his shades to show the sockets. He sold his eyes. Anderton buys a replacement pair off the same market later, because the scanners only know him by the ones he was born with. Sight is a thing you can trade away and a thing you can buy back, and what the buyer asks for is clarity.

Anyone running several agents is somewhere on that market. The output goes past faster than anyone reads it — a stream per session, every one of them narrating its own work — so watching quietly stops being the same thing as seeing. Nobody decides to stop reading. It costs more than sending the next prompt does, every time, and the gap compounds.

One eye is the whole advantage. A session whose replies can be read at the speed they arrive is one you are still supervising.
