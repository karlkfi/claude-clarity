# Stating a fact nobody measured

`SKILL.md` sends you here before a PR body, a release note, a status report, or any sentence a decision will rest on. An italicised rule name that is not in this file is
in `SKILL.md` or in a sibling file under `references/`.

**A pre-written form field hides the claim's role.** A checkbox in a PR template, a cell in a
status table, a bullet in a release note — each asserts something a reviewer then acts on, and
none of them reads as reporting a result, because the wording arrived with the template and
ticking it feels like completing paperwork rather than saying anything. `- [x] make check is
green` went out ticked without the run, on a PR whose entire subject was that self-attested boxes
are unreliable; a release note enumerating new tests named three that do not exist, written from
the code diff rather than from the artifact. So tick the box after the run, and
build an enumeration by reading the thing it describes rather than the change that produced it.
The document is where a claim gets consumed: a wrong belief held privately is corrected by the
next command, and the same belief in a PR body is what a reviewer approves on.

**A list asserts a symmetry its sentence never stated.** A sentence naming one mechanism and then
listing members lets a reader distribute the mechanism over every member. *Every handler returns
0 or 1 through `sys.exit(main())`, argparse contributes 2, and an uncaught exception contributes
1* is true, and its three members exit three ways: a return through `sys.exit(main())`, a
`sys.exit(2)` inside argparse with `main()` never returning, and CPython's top-level handler. A
later row compressed it into one cause and stated a false `because`. Checking each member does not
catch it — argparse genuinely calls `sys.exit`; what is false is the composed `sys.exit(main())`.
Check each member against the mechanism as written, at the granularity written, or move the
mechanism out of a sentence that covers several sources.

**An actor or author field names the credential, not the person.** Where someone and their agents
share one account, every action any of them takes is stamped with it — `actor.login` on a GitHub
timeline event, and the author of a commit, comment or review made through `gh`, report which token
was presented and nothing about who decided. `performed_via_github_app` is null for a CLI call, so
nothing in the API separates a human's click in the web UI from a session's. Reading the field as
the person yields a confident false statement about what they did, and one that turns load-bearing:
*the maintainer drafted it deliberately* is a reason to leave a wrong state alone. The correction
carries a second error, and it is the one that survives — the API cannot resolve the actor, which is
not the same as nobody can. The agent runtime's own transcripts are an instrument the service has no
access to; Claude Code writes each session's commands *and their results* under
`~/.claude/projects/**/*.jsonl`, so a walk for the object's id and the verb finds the session that
acted, with the service's own confirmation line beside it. A session that diagnosed the token trap
correctly then called the actor unresolvable while its own transcript held the `gh pr ready
--undo` that answered it.

**A reading of a file you do not control is a snapshot, and it decays silently.** The audit was
right when it was taken; by the time it is acted on, someone has merged. Nothing prompts a re-read,
because there is no measurement to re-examine — only a reading whose subject moved, and the report
still looks exactly as it did when it was true: an audit of two repo docs was obsoleted 35 minutes
later by an upstream merge, in the one section it had deliberately kept. Record what each reading
was taken from — a SHA, a fetch time — and take it again when it is about to decide something,
rather than when it is written down.

**Context you did not read carries no read time, so a negative taken from it dates to nothing.** *A
reading of a file you do not control* is a reading you took and can stamp; this is text that arrived
with no command in front of it. A file opened with `cat` announces when it was opened, because the
invocation sits in the transcript above its output. Context the harness injects — a `CLAUDE.md`, a
memory file, a skill body — has no such line, and was loaded when the session started rather than at
the moment you quote it. Positives survive the gap, since a sentence you quote is one somebody can
go and find; negatives do not, because *the skill says nothing about X* and *the copy handed to me
at session start said nothing about X* read identically and only the second is supported. A session
reported a gap in the global `CLAUDE.md` as unfiled about three hours after the fix had been
committed. Re-invoking is not the repair, and it returns as though it were: an installed skill
resolves through a symlink into a working checkout, so the second call re-injects the identical body
and reports success. `git fetch origin && git show origin/main:<path>` is the read that can come
back different from the one you are holding.

**A figure lifted from ambient context was never read from an instrument.** A harness banner, a
status header, a neighbouring row: each carries numbers that are right for what they describe and
wrong for nearly everything else, and quoting one costs nothing and reads as a measurement. Time
is where it bites hardest, because an interval is derived rather than read — subtracting two
stamps you did not take yields a plausible number instead of an obvious error, and the more real
the stamps are, the more plausible the number. A harness banner's `12h 3m since the previous turn`,
which measures from the session's first prompt, went out as twelve hours of idle time where the
real window was ten minutes. It went out in a message, which is where this escapes: nothing lints a
message. Read the clock when you take the reading, and where a receiver only needs the reading,
send it undated and let them stamp it.

**A figure committed to the tree is anchored to a revision or a date, never to a wall time.** A
message is read once; a backlog row, a PR body or a commit message outlives every session that
could re-derive it. `read at 8adb878` or `measured 2026-09-07` can be re-taken from the tree
whatever the producing clock was doing, while `14:32 PDT` is checkable against nothing once the
session has gone, and its timezone suffix makes a guess read as a reading. Grep what a branch adds
for a clock time: each hit cites a record carrying its own timestamp, or is a claim nobody can
re-take.

**A selectivity rate is not a throughput prediction.** A rejection rate says how often work is
skipped. Turning it into a speed needs the share of total cost the skipped work carries, and
without that measurement the rate licenses a claim about work avoided and none about wall-clock. A
filter passing 27 of 554 keyword hits to its second stage was framed as a speedup and measured
neutral, because the skipped work was not where the time went.

**A claim you inherited becomes yours the moment you repeat it.** An issue, a ticket, or a brief
arrives as the frame for the work rather than as a set of claims inside it, so its assertions get
read to plan against and never to check — and the ones about files the change does not touch are
exactly the ones the work will not incidentally verify. Repeating one in a PR description or a
summary republishes it under your name, with the original author's confidence and none of their
evidence. An issue proposing a hook fix argued its trade-off was free because
a second script validated its input the same way; the PR body repeated that as settled, and it went
unchecked until a reviewer asked, one turn after it had shipped. It was true — the ordinary
outcome, and the reason the habit survives long enough to be expensive once. The tell is a
sentence about a file outside your diff. Attribute it to the issue, or spend the one command
that settles it.

**A measured value is a function of the venue it was taken in, and the document names a different
one.** *A reading of a file you do not control is a snapshot, and it decays silently* is this
failure in time; this is it across setups. The author did go and measure, and the number
reproduces — which is why it survives, because the re-run restores the venue along with the value,
so the one check that would catch it cannot be another measurement. Read the surrounding text
instead: ask which properties the value turns on — a path depth, a file somebody created, a
platform's symlink layout, a hostname, a clock — then whether the text states them. So state the
property, or **pick an exhibit whose value the claim fixes rather than the setup**: a pair
differing only in the construct under test resolves identically from every reader's root, and the
gap between its two verdicts is the defect itself, which one command naming a correct-looking path
could not isolate. A worked case over three review rounds:
[`references/shell-traps.md`](shell-traps.md).

Also in `SKILL.md` §6, in [`further-rules.md`](further-rules.md): *Provenance
is a claim, and one of the cheapest to settle*; *A figure you derived is not a figure you read*.
