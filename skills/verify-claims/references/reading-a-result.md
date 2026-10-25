# Reading a result

`SKILL.md` sends you here before a command's exit status, its output, or its silence becomes a verdict. An italicised rule name that is not in this file is
in `SKILL.md` or in a sibling file under `references/`.

**Exit status is easy to lose.** A pipeline reports its last stage, so a gate piped into a
filter reports the filter's success. Backgrounded, the completion notification reports the
whole compound's last command, which is rarely the gate: a chain ending in `echo` always
ends 0, so the failing gate arrives as `completed (exit code 0)` — the most
authoritative-looking signal available and the only wrong one. A chain ending in a *grep for
failure lines* is worse, because it inverts rather than flattens. On `make check > log 2>&1; echo "EXIT=$?"; grep -E "FAILED|Error [0-9]|^make:" log`, a failing gate notified `completed (exit code 0)` and a clean one notified `failed with exit code 1`,
the grep having matched in the first case and not the second. Preserve the status explicitly
— `cmd > out.log 2>&1; rc=$?; exit $rc`, with the `exit` last so a trailing filter cannot
overwrite it — and reconcile it against the log, because a gate exiting 0 while its own
output carries a failure line is the other half of the same trap. And a check *sequenced*
before a mutation does not gate it: `lint; git commit` runs the commit whatever the linter
said.

**A process probe whose pattern sits in its own command line matches itself.** Asking whether a
job is still running with a pattern the asking command also carries as text answers "running" for
as long as you keep asking. That is worse than having no probe: the reading is stable, plausible,
and decoupled from whether the job is alive, so it survives every re-check. A background job's
verdict comes from its completion status and its output, never from a process probe. Where one is
genuinely needed, break the self-match and confirm it against a case whose answer you know.

**Silence has three causes and they look identical.** The thing is absent; the command never
ran; the command ran and asked after a name that does not exist. Only the first is a finding.
A tool that exits 0 having printed nothing may have checked nothing — when a verification's
whole value is that it ran, make it emit something assertable rather than trusting status.

**A legend emitted beside a command decides its reading before the output exists.**
`echo "(empty = all green)"` printed next to a check that has not run yet converts all three
causes above into a finding, in advance and for every later reader: the transcript then carries
an interpretation with nothing under it, in the register of a result, and the one form of
emptiness that would have been informative is the one it reads past. It is *A completion
predicate must key on what ends the run* (in `further-rules.md`) one step earlier — the verdict is fixed before the instrument reports — and it
is cheap to do repeatedly, because it looks like labelling rather than concluding. Print the command's own output; write what
it means after reading it.

**An empty value in a filter argument widens the query instead of narrowing it.** Empty *output*
has the three causes above; an empty *input* has one effect and it is the inverse of silence — the
command answers about a wider population than you asked about, in the shape of a successful
filtered read. The general form is any `--flag "$VAR"` fed from a read that can fail, where empty
means *no filter* rather than *no match*: under an API outage a SHA read came back empty, and
`gh run list --commit ""` then listed every run in the repository, exit 0, with a plausible green
row for the branch in question. So check the value's *form* before it filters anything, and check
it against what it should be rather than against emptiness — a 40-character test refuses the
truncated reads and error strings that `-n` accepts — then confirm it from a second source, here
`git ls-remote`. **Do it unconditionally**: a guard reached for on suspicion is absent wherever the
failure is quiet.

**The shell is an instrument too, and it fails in the same shapes.** Every rule in this file and in `negatives-and-controls.md` assumes the
command you wrote is the command that ran. Often it is not: a pipeline hands back its filter's
status, `PIPESTATUS` is empty in zsh and reads as success, a `$var:` followed by a colon expands
as a modifier and mangles the path, an unquoted glob dies before the search starts, `grep -c`
counts lines rather than matches, and BSD `sed` on macOS accepts a GNU pattern, matches nothing
and exits 0. Each returns a well-formed result that is about a different question. The mechanics,
with the invocation to use instead: [`references/shell-traps.md`](shell-traps.md).

**A failed read hands its error to whatever consumes the read.** *The shell is an instrument too* is
about a command answering the wrong question; this is one that answers nothing and has the refusal
recorded as data. `git show <commit>:<path> > f 2>&1` on a path absent from that commit writes
`fatal: path '<path>' does not exist in '<commit>'` into `f` and exits 128, so a reviewer
establishing whether a file is identical on two commits by extracting both and running `cmp`
compares an error message against real content. It reports *differ*, which is the expensive shape: a
plausible refutation of the claim under test rather than a check that stopped, so it changes a
verdict instead of raising one. Compare ids instead — `git rev-parse --verify <commit>:<path>`
returns the blob id, and a missing path is an error rather than a value, so there is nothing for the
comparison to make a verdict out of. Keep the `--verify`: the bare form echoes its own argument on
stdout, which compares unequal exactly as a difference does.

**A local gate disagreeing with CI indicts your toolchain first.** CI builds its tools fresh
from the pin; your build directory holds whatever it held last time. A stale binary takes no
flag it does not know, prints plausible output, and names real files — nothing about the run
looks wrong. Rebuild and re-run before reporting anything about the repository. And a repeated
claim gains authority without gaining evidence, so the second and third restatements are the
expensive ones.

**A suite result is only valid for the tree state that held for the whole run.** *A local gate
disagreeing with CI* and *A failure on your branch is not yours until the base fails too* hand a
red result to somebody else — your toolchain, or the base. This one hands it back,
and not through the change under test: a file written while the suite runs is read half-written
by whatever executes next. A gate started in the background and an edit made while it ran is the
ordinary shape, and neither step feels like it touches the other.

How far the corruption reaches is decided by how the suite loads the subject. An imported module
is read once at import, so an edit after that lands in the next process. A helper that spawns the
subject as a **subprocess** re-reads the file from disk on every call, so a mid-run write breaks
whichever case happens to run during it: comment edits made while `make check` ran in the
background failed one unrelated test with `SyntaxError: '(' was never closed` inside its assertion
text, and the settled tree passed.

It misleads in two directions at once. The result is red, so *could this have shown me the
opposite?* answers yes and the failure passes the check that catches most of these rules. And it
names an innocent test — whichever one ran during the write — so the obvious next move is to
debug code that was never wrong. The tell is a syntax or import error arriving inside a test
assertion rather than as a collection error: a subject the suite never imports cannot fail
collection, so its unparseable state has nowhere to surface but whatever case was running. So
before believing a failure, ask whether anything under test was written during the run; before
starting an edit, ask whether a suite is in flight. Where both already happened the run measured
nothing either way, and only a re-run over a settled tree replaces it.

Also in `SKILL.md` §1, in [`further-rules.md`](further-rules.md): *A completion
predicate must key on what ends the run, not on a string that appears in it*; *An approved
permission prompt leaves no trace in the result*; *A correct reading of the wrong field is a wrong
measurement with nothing defective in it*; *Re-reading an ambiguous output cannot disambiguate it*;
*A capability is a claim, and it is load-bearing before the design, not after*; *The tell is a
boundary that coincides with your own start*; *Two instruments pointed at one observable are one
instrument*; *One observation is not a steady state*; *A failure on your branch is not yours until
the base fails too*.
