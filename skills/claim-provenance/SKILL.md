---
name: claim-provenance
description: >-
  Audit prose for claims the author never earned — a guess, a generalisation,
  or an invented specific delivered in the register of something checked — then
  repair them in a separate pass. Use when a draft asserts more than its author
  went and got, and on the challenges that ask for it: "are you sure", "did you
  check that", "how do you know", "where did that number come from", "do we
  have a source for that", "did we measure that", "is that actually true",
  "that reads like you made it up". Also as a pass over your own finished
  draft, or anything an LLM helped write. Covers tagging each assertion's
  provenance — checked, held, inherited, constructed, ornamental — reading the
  register that implies it, scoring the gap between the two, the
  fabricated-specificity trap, and four repairs: cut, downgrade, swap the law
  for the exhibit, go get it. Neighbours: semantic-remediation owns whether a
  sentence means anything, verify-claims owns instruments you can still go
  read, this one owns whether the author earned it.
---

# Claim Provenance

Every assertion has a provenance: where the author got it. Every assertion also has a register: what its delivery implies about that provenance. The defect is the gap. A guess written in the voice of a measurement is fluent, coherent, often true, and unearned.

This is not hallucination. A fabricated citation is falsifiable — you look it up, it isn't there, the error announces itself. An unearned claim is cheap to generate and expensive to audit, and that asymmetry is the whole harm. It costs a second to write "most teams get this wrong" and an afternoon to find out whether they do.

It shows up most in confident essayistic prose, in anything an LLM helped write, and in experts writing outside the exact thing they're expert in — because the register comes free with the topic.

Two phases. Never run them together.

## Modes

**Repair unless something says otherwise.** Audit, repair, then report both the findings and the changes. A mid-task pass over a PR body, a `SKILL.md`, a runbook, or a release note is a handover to be finished rather than judged, and the author reviews the output instead of the audit.

**Audit alone when the invocation is a question about the draft** — "are you sure", "did we measure that", "where did that number come from". A question wants an answer, not a diff. Report the findings and change nothing.

An explicit instruction beats both readings. "audit it", "just tell me what's wrong", `--audit` hold the repairs; "fix it", "clean it up", `--fix` run the full pass on a draft you would otherwise only have audited.

**One repair never runs unattended: go get it.** The other three spend nothing — a cut, a downgrade and an exhibit are each a rewrite of something the draft already holds. Going and checking spends time and tool calls against a claim the author may be perfectly happy to downgrade instead, and the choice between the cheap repair and the expensive one is theirs. Report it as work to authorize and leave the sentence as it stands until they do.

## Phase 1: Audit

Work sentence by sentence through every assertion. Skip nothing that makes a claim about the world.

Use semantic-remediation's exhibit test first: a span the text speaks *about* rather than *with* carries no provenance obligation. Bad writing on display is not the author claiming anything. Fiction, epigraphs, and quoted voice are out of scope entirely.

### Tag the provenance

Five classes, mutually exclusive. Ask of each assertion: where did this sentence come from?

| Class | Means |
|---|---|
| **Checked** | Someone went and got it — a source read, a command run, a file inspected, a number measured. Locatable. |
| **Held** | Firsthand: the author was there, made the decision, ran the team. Not checkable by the reader, but real. |
| **Inherited** | Read or absorbed somewhere, remembered without the source. Probably true, unlocatable. |
| **Constructed** | Assembled from adjacent knowledge. Plausible, never checked, and the sentence is the only evidence for itself. |
| **Ornamental** | Not a claim at all. Connective tissue that took declarative shape and got read as an assertion. |

The test that separates **inherited** from **constructed**: try to name where it came from. If the answer restates the claim, it's constructed.

### Read the register

What the delivery implies. These are the signals that assert high provenance:

- **Observational frame** — "what I see," "in practice," "every time," "I keep running into." Claims an ongoing encounter.
- **Mechanism** — "X happens because Y." The strongest signal of all: normally you only know why if you've been inside it.
- **Scope quantifier** — "most," "almost always," "nobody," "the majority of." Claims a count.
- **Unsourced specificity** — a number, a named incident, a case, an example failure. Claims presence.
- **Aphorism** — a compressed general law. Claims enough instances to have compressed them.
- **Bare confident declarative** — no epistemic marker at all, which reads as checked by default.

### The finding is the gap

Register above provenance. Record class and severity together — a finding is "constructed as checked, 5," never one or the other.

- **5** Constructed or ornamental, delivered as checked, and load-bearing. The argument rests on it.
- **4** Constructed delivered as checked, decorative. Nothing depends on it, which makes it a cut candidate rather than a research task.
- **3** Inherited delivered as checked. Probably true, unlocatable, stated harder than it can support.
- **2** Held delivered as general law. Real experience over-generalized: one case became "most teams."
- **1** Register slightly hot. Don't report it.

Score **undersell** separately and low: checked delivered as hedged. It wastes work that was actually done, and it trains the reader to discount everything.

### The fabricated-specificity trap

The worst findings hide in the concrete details, because concreteness is the strongest earned-knowledge signal there is. Under pressure to be specific, generation supplies a specific thing — a number, an incident, a snippet, a named example — and it reads exactly like something that happened.

Flag every specific detail and ask where it came from. A sourced specific closes this audit and not the reader's problem: a value the author genuinely measured can still be wrong for the setup the surrounding text describes, which is a gap between the claim and its venue rather than between the claim and its author — hand it to verify-claims. Two aggravators:

- A detail invented to *illustrate the value of concrete detail* is the failure performing itself. Check illustrations hardest.
- Invented details drift toward the reader's own domain, because that's what the surrounding context primes. A fabricated example that lands suspiciously well for this particular audience is a 5, not a 4.

### Questions the classes don't cover

- What would you expect to see if this were false? If nothing, it isn't doing work — that's a semantic-remediation finding, hand it over.
- Could you write the opposite this well? If yes, the fluency wasn't tracking the world.
- Would defending this sentence require going and getting something you don't have? Then say so in the sentence.

### Rules for auditing

- **A challenge is not evidence.** When this pass runs because someone said "are you sure?", the doubt is a reason to look and never a finding in itself. Preference training rewards agreement, so the pull is to retract whatever gets pushed on — which is the same defect inverted, with the register tracking the reader instead of the provenance.
- **Check that a disclaimer is about the claim you made.** Over-conceding needs no challenge to trigger it: unprompted, the pull is that deferring to someone else's instrument reads as rigor, so naming a limit on your own evidence looks like the care this pass asks for. Before disclaiming an instrument, ask which question the limit answers, and concede only if that is the question you were answering. A reviewer who had established a common cause from its own sweep — six sessions on one host, transcript gaps ending within eleven minutes of each other — volunteered that transcript silence cannot distinguish a dead process from an idle one, and handed the reading to a peer. True, and about a different question: silence is ambiguous for one session, while clustered resumes across twelve unrelated worktrees are positive evidence of a shared cause. The mechanism it gave away came from the sweep it had just disclaimed. Over-conceding removes a reading from the record, and it is harder to notice than over-claiming because it reads as good manners.
- **"Checked, still stands" is a first-class outcome.** State it as plainly and as briefly as a retraction. An audit that can only find fault isn't an audit.
- Don't manufacture findings. If a passage is clean, say it's clean.
- Flag your own writing hardest. Believing something is what stops you noticing you never checked it.
- Provenance is per-sentence. A well-researched piece still has unearned sentences in it, usually in the transitions and the conclusion.

### Output

Report the top scorers. One line each on what the gap is, not on what to do about it.

> **Constructed as checked, 5.** "Most bad technical writing is written at the author's past self." No source and no count; the scope word is carrying the paragraph. Load-bearing — the advice that follows rests on it.

Stop when the findings stop earning attention. If most of them cluster in one section, say so and stop listing.

Then stop. Repair nothing in this phase, and don't start because nobody objected.

## Phase 2: Repair

Runs on the finished audit — straight away in repair mode, and after the author agrees when the audit ran alone. Either way the input is the whole list, never one finding at a time.

Four repairs. Pick by provenance class, and try them in this order — the cheap ones are correct more often than they look.

**Cut it.** For ornamental findings, and for anything scored 4. These are usually not underevidenced claims at all; they're transitions and throat-clearing that became assertions by being written in declarative shape. They don't want proving. The paragraph is better without them.

**Downgrade it.** For constructed and inherited. Restate as the claim the author actually holds.

This is not hedging, and the difference is the whole move. Hedging keeps the claim and bolts on a shield — "arguably," "in many cases," "one could argue that most." Same assertion, now unrefusable in a second way. Downgrading *replaces* it with the true smaller one: scope words go first, the mechanism can stay if it's labeled as conjecture, and the result is shorter, weaker, and worth more, because a reader can now disagree with it.

**Swap the law for the exhibit.** For held-as-general-law, and for any aphorism. Ask which specific instance produced the belief, then print the instance instead. The law is frequently a compression of exactly one case, and the case is more useful and more honest than the compression. An exhibit can't be vacuous — it's there or it isn't.

**Go get it.** For checkable claims worth the cost. Hand off to verify-claims where that skill is available. This is the only repair that earns the original register, and it is the most expensive, which is why it's last on the list and not first — and the one repair the Modes section holds back for the author to authorize.

### Rules for repairing

- **Citations don't repair vacuity.** A source hung next to a claim it doesn't actually bear on is the same defect in better clothes — now the appearance of grounding does the work the grounding didn't. Sourcing fixes an assertion only when the source is about that assertion.
- Re-audit repairs. A downgrade that introduces a new mechanism claim is a finding now.
- When a repair would gut a section, that's a real result: the section was built on something nobody had. Hand it back rather than patching sentence by sentence.

## Sources

- `semantic-remediation`, for the exhibit test Phase 1 opens with, and for the shape the two skills share deliberately: the phase split, a category and a severity recorded as one finding, and the mode rule above. The two audit different properties of the same sentence — whether it means anything, and whether the author earned it.
- `verify-claims`, which owns the fourth repair once the author authorizes it.
