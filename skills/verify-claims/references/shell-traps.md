# Shell and tool traps that fake a clean result

The concrete mechanics behind `verify-claims` §1. Each entry is a way a command
reports success, or reports nothing, while having measured something other than
what you asked — the shell-level instances of "the instrument did not run and
said so quietly".

Read this when a gate, search, or count is about to justify a decision and the
command that produced it is more than a single unpiped invocation.

## Exit status

**A pipeline reports its last stage.** `make check | tail -30` returns `tail`'s
status. This is the same trap in the foreground and the background, and it is
worse with a filter that matches on failure: `grep` exits 1 when it matches
nothing, so a gate piped into a failure-line grep reports failure exactly when
the run was clean.

**`PIPESTATUS` does not exist in zsh.** It expands to empty, which reads as
success. zsh spells it `$pipestatus` — lowercase, and 1-indexed rather than
0-indexed. Rather than reaching for either, redirect and keep the status:

```
cmd > out.log 2>&1; rc=$?; echo "EXIT=$rc" >> out.log; exit $rc
```

The trailing `exit $rc` is what makes a backgrounded run's completion
notification carry the real status. A log with no `EXIT=` line at the end is not
a completed run.

**The redirect splits the same way, and empties the harness's own capture.** A
backgrounded `cmd > run.log 2>&1` sends every byte to `run.log`, so the task
output the harness reports back is empty — and an empty task output at exit 0 is
exactly what "the watcher fired and saw nothing" looks like. Read the log you
named. An empty capture is a fact about the redirect before it is a fact about
the run.

**A loop's exit status is its last iteration's, so a sweep that finds nothing
can exit 1.** A body ending in `[ -n "$f" ] && echo "<hit>"` leaves the loop
carrying that test's status, so a clean sweep — every iteration falling through
the `&&` — reports failure. Joined to a mutation with `&&`, the mutation is
withheld for a check that never failed: measured 2026-09-04, a `git push` held
back by a sweep whose only finding was that there was nothing to find.

This is the one entry in this section that runs the other way, and the reflex the
rest of them build is what makes it stick. `; rc=$?` faithfully captures a status
that was already meaningless. Separate the sweep from the thing it gates —
accumulate hits into a variable and test the variable — rather than repairing the
status the loop left behind.

**A check sequenced before a mutation does not gate it.** `lint; git commit`
runs the commit whatever the linter said. `&&` gates; `;` does not.

**Never send stderr to `/dev/null` on a state-changing command.** `git add` is
atomic — one bad path stages nothing, and the redirect discards the reason the
whole operation did nothing.

**Two suppressions compose into a reading neither produces alone, and the wrong
conclusion lands on the tool rather than on the query.** `2>/dev/null` deletes
the message; the pipe replaces the failing command's status with the filter's.
What survives is indistinguishable from a command that ran and matched nothing.
Measured 2026-09-13 on `gh` 2.100.0, which takes no pathspec on `pr diff`:

```
gh pr diff 521 -- readability/scripts/readability-lint.py   accepts at most 1 arg(s), received 2   exit 1
  ... 2>/dev/null | grep -E '^@@'                           (empty)                                exit 1
gh pr diff 521 2>/dev/null | grep -E '^ZZZ'                 (empty)                                exit 1
```

The last two rows are the same reading, byte for byte, from a command that
refused to run and one that ran correctly. The status is not even zero — it is
`grep`'s no-match 1, which reads as *found nothing* and is the same integer the
suppressed failure would have carried, so a non-zero status prompts no look. The
rejection here is cobra's, before any network call: the same two-argument form
against a nonexistent PR gives the identical 37-byte message, where the one-
argument form reaches GraphQL and says so.

**What makes it durable is where the conclusion goes.** A muted query normally
yields *my search found nothing*, which is wrong once and discarded. This yields
*this tool behaves this way* — portable, plausible, and written down. It was, and
was refuted by re-running the bare command. It also inverts the remedy a reader
is braced for: a positive control is what an empty result is owed, and here the
instrument was already saying the answer in one line that had been deleted. Run
the bare command before concluding anything about a tool's behaviour.

**`git rev-parse` without `--verify` echoes its own argument on failure.**
Measured on git 2.55.0: the bare form exits 128 having printed
`HEAD:no/such/file.md` on stdout, and that string compares unequal to a real blob
id in exactly the way a genuine difference does — so a blob-id comparison
standing in for a file comparison reports *differ* rather than stopping.
`--verify` leaves stdout empty at 128; `--verify --quiet` leaves it empty at 1.
See *A failed read hands its error to whatever consumes the read* in the skill
body.

## Quoting and expansion

**`$var:` starts a modifier in zsh, so `"$ref:path/file"` mangles the path.**
zsh reads the `:h` in `git show "$r:hooks/guard.py"` as head-of-path and expands
it to `.ooks/guard.py`; `:t`, `:r`, `:e` and `:s` bite the same way. Double
quotes do not help — only braces do: `"${r}:hooks/guard.py"`. This hides well
because git reports it as a bad revision, so the instinct is to doubt the ref
rather than the shell — and `:s`, the *substitute* modifier, does not even do
that. It takes the character *after* it as a delimiter — the path's second
character — and then behaves three different ways depending on how often that
character recurs in the rest of the path. Measured 2026-09-13 under zsh 5.9,
with `$b` as `origin/main` and three paths that differ only in that count:

| Delimiter recurs | Example path | git receives | Result |
|---|---|---|---|
| never | `src/main.py` | nothing | `bad substitution`, the shell aborts |
| once | `src/main.rs` | `origin/main` | exit 0, answers about the commit |
| twice or more | `src/parser/read.rs` | `origin/main/read.rs` | exit 128, `fatal: ambiguous argument` |

Two properties of the path do separate jobs, and only the first is about `:s` at
all. The **first** character selects the modifier, so a path starting with `r`
gets `:r` and one starting with `t` gets `:t` — a different mangling, not this
one. The **second** becomes the delimiter, and its recurrence decides which of
the three you get: none leaves `PATTERN` unterminated, one lets `REPLACEMENT`
run to the end of the string with nothing left to append, and two or more closes
both and appends the tail.

That is why *exactly once* is the silent case rather than an arbitrary count. It
is the only one where the substitution consumes the whole remainder of the path,
so git is handed a bare, valid ref and answers a question you did not ask.

Confirm the split by giving `$b` a value the pattern matches: `[c/main.]` under
`src/main.rs` returns `[s]`, and `[c/pa]` under `src/parser/read.rs` returns
`[se]/read.rs` — the tail visibly appended in the second and absent in the
first.

Reproduce any of it with a **literal** path. The modifier resolves at parse time,
so `git show "$b:$p"` with the path in `$p` never triggers it, and that reads as
evidence the trap is not real.

Only the first is harmless, because the command never runs. The second is the
silent one: git is handed a bare revision, so exit 0, empty stderr, the commit
message on stdout, and piped into a count that is a plausible zero rather than
an error.

**The third is the worst, and it is the loud one.** zsh applies the substitution
and appends what is left, so git fails on a name you never typed — and the
mangling depends on the path rather than on the ref, so *every element of a
sweep fails identically*. Re-measured 2026-09-13 over 180 remote refs:

```
unbraced "$b:semantic-remediation/SKILL.md"    180 of 180 failed
braced   "${b}:semantic-remediation/SKILL.md"  177 exit 0, 3 exit 128
```

A uniform column is exactly what a true negative looks like. There is no outlier
to notice, the error blames a ref rather than the shell, and the loop reports
"no branch carries this file" with nothing in it to doubt — which is how one such
sweep came to contradict a peer who had reported the opposite, correctly. **A
sweep whose every element agrees is the one to re-run braced.** A real sweep
usually has an outlier somewhere.

None of this needs an unusual path. It needs only a first character that is a
modifier letter: `docs/`, `README.md` and `Makefile` pass through untouched,
which is what makes the trap feel like it is about the ref.

**A loop over `path` destroys `PATH`, and the failures come back as findings.**
zsh ties the two — `export -T PATH path` — so `for path in a b; do ...; done`
leaves the search path as the single directory `b`, and every command after the
first iteration is *command not found*. A sweep redirects stderr, so those
failures are invisible, and each one arrives at a `|| echo "<hit>"` as a hit:
measured 2026-08-21 on the run this came from, a nested sweep returned 330 hits
from 330 probes where renaming the variable gave a non-uniform 26. `cdpath`,
`fpath`, `manpath` and `module_path` are tied the same way, and bash ties none
of them, so a loop lifted from a bash example is a false-positive machine here
and nowhere it was written. That direction is the one nobody probes for: the
usual control fires a sweep at a known positive, which proves it can report a
hit and says nothing about whether it reports them when there are none.

**Backticks inside double quotes are command substitution.** A title carrying a
markdown code span runs it: `--title "\`foo.py\` is broken"` executes `foo.py`
and files the result with that span deleted — exit 0, artifact created, nothing
flagged. Anything carrying code spans goes in single quotes, or comes from a
file. Read back what you published, not what you sent.

**A word starting with `=` is a command lookup in zsh, and the failure takes
the rest of the line with it.** zsh expands `=name` to that command's path, so
`echo =ls` prints `/bin/ls` and a separator typed as `echo =====` is read as a
lookup for `====`. Measured 2026-08-21 under zsh 5.9:

```
echo one; echo =====; echo three
one
(eval):1: ==== not found
```

`echo three` never ran. Statements before the bad word do, the ones after do
not, and the status is 1 — so a chain ending in the check you care about reports
a failure the check never performed, and the error names a command nobody typed.
bash prints `=====` and carries on, which is why the form survives being copied
from anywhere else. Quote it, or separate output with something that does not
open on `=`.

**An unquoted glob in a search flag dies before the search runs.** `--include=*.sh`
expands against the working directory; quote it. The failure returns nothing and
looks exactly like a legitimate negative.

**An assignment prefix does not reach expansions in the same command.**
`GOOS=linux go build -o "out-$GOOS"` writes `out-`, because the shell expands
`$GOOS` before the assignment exists anywhere but the launched process's own
environment:

```
FOO=bar sh -c 'echo "[$FOO]"'    # [bar]  -- the process sees it
FOO=bar echo "[$FOO]"            # []     -- the shell expanded first
```

Measured 2026-08-21 under zsh 5.9, bash 5.3.15 and `/bin/sh`, all three empty.
This one is POSIX rather than a zsh divergence, so unlike the rest of this
section there is no bash-flavoured version that works.

**What it produces is a loop that overwrites one output N times**, and a build
matrix is the usual host:

```
for t in darwin/arm64 darwin/amd64 linux/amd64 linux/arm64 windows/amd64; do
  GOOS=${t%/*} GOARCH=${t#*/} go build -o "out-${GOOS}-${GOARCH}" .
done
```

Five targets, five builds that genuinely succeed, exit 0 throughout — and one
file called `out--` holding whichever ran last. Nothing fails, so any aggregate
over the results (a `du`, a sum, a mean) returns a real number measured over a
fifth of the work. Measured 2026-08-21: this reported 2.38 MB where the five
binaries were 11.63 MB, and the figure was about to decide whether committing
them to a repo was cheap. A 5x understatement argues for committing; the true
number argues against.

**The tell is in the count, not the status**, which is what makes it survive
every check aimed at failure. Print the per-item listing beside any aggregate
over a loop's outputs and confirm it has the rows you expected — `ls -1 out-* |
wc -l` next to the sum catches this and the sum alone never can. The fix is to
assign on a statement of its own and expand from that:

```
for t in darwin/arm64 darwin/amd64 linux/amd64 linux/arm64 windows/amd64; do
  os=${t%/*}; arch=${t#*/}
  GOOS=$os GOARCH=$arch go build -o "out-$os-$arch" .
done
```

**A path built from `../..` is a value only the venue fixes.** A table
presented `cat <<<"$(cat ../../../../etc/hosts)"` as naming `/private/etc/hosts`
under a setup given only as "a fresh directory outside host temp", which fixes
nothing: from five directories at five depths that command names five different
files, none of them `/etc/hosts`, and `/private/etc/hosts` needs a root exactly
four levels below `/private`. It is also the realpath of `/etc/hosts` on macOS,
so the wrong value reads as the right answer and reproducing it teaches the
reader nothing. The review rounds either side carried a file's existence out of
the venue that created it into a table about `/etc`, and set `/etc/T` against
`/private/etc/T` in adjacent columns. The replacement pair — `cd /etc && cat
<<<"$(cat hosts)"` against `cd /etc && echo "$(cat hosts)"`, same read, same
`cd`, differing only in the here-string — resolves identically from every
reader's root, and the gap between its two verdicts is the defect itself.
Measured 2026-09-08.

## Search and count

**`grep` matches within one line, so a wrapped string is invisible to it.**
Prose wraps and source splits strings constantly — adjacent literals, an
f-string continuation, a `+` join — so searching for a sentence you have seen in
real output returns 0 and reads as "not present". Search a distinctive fragment
that cannot straddle a break, or use `grep -Pzo` or a script for a multi-line
pattern.

The same applies to counting copies of a rule across documents: a search for a
wrapped sentence finds the copies that happen to fit on one line and silently
misses the rest, and a search that under-counts is the one that concludes there
is nothing to fix.

**`grep -c` counts matching *lines*, not matches.** Two hits on one line count
once, so a density or occurrence figure taken from `-c` reads low and reads
plausible. Use `grep -o … | wc -l` when the number is occurrences. `-l` and `-L`
answer "which files", not "how many".

And a count says nothing about *what* matched, so an alternation wider than the
question reads as a larger finding. `assertLess|\.index\(|\.find\(` returned 6
where the order-pinning assertions numbered 4, the extras being `cmd.find(marker)`
in a string-search helper. Where a count is about to justify a correction to
somebody else, read the lines.

**`grep` is case-sensitive by default.** A scan for a phrase about to be
declared absent needs `-i` unless the casing is known. Zero hits from a
case-sensitive scan of prose is not a negative result.

**A whole-line grep over a Claude session transcript returns a skill body as its
first hit.** A `SKILL.md` is injected as an ordinary user record when its skill
fires, so every string that skill contains sits in the corpus as one enormous
line and outranks anything a session actually did. Excluding the record you found
is not the fix. Measured 2026-09-04: a search for `merge-base` across
`~/.claude/projects/**/*.jsonl` hit record 3, a 189 KB skill body, and once that
index was skipped, record 112, a 99 KB one. Re-run 2026-09-13, the same needle
hit a 100.6 KB record and an 85.0 KB one ahead of anything a session did. Which
bodies they are is a function of which skills fired, so there is no fixed number
to skip. Exclude on a property of the record — a size threshold, or its being
a verbatim copy of an installed body — never by index.

**A command-position anchor excludes prose and not a heredoc body.** Counting
invocations of a command across session transcripts by scanning the Bash command
string counts every mention of it — a commit message, a drafted PR body, a
heredoc quoting source. Anchoring to command position removes the bare mentions:

```
(?:^|[;&|(]|&&|\|\||\n)\s*(?:[A-Za-z_][\w]*=\S*\s+)*git\s+merge-tree\b
```

The `[;&|(]` class is load-bearing — `$(git merge-tree ...)` is the commonest
real form, and a `^`-only anchor drops it. Measured 2026-09-16 in
`actions-gateway/github-actions-gateway`: the raw scan returned 326 hits across
80 sessions, the anchored one 264 across 74.

What it still cannot exclude is a command-position match inside a heredoc body, a
quoted script, or a document being drafted, because `$(` is a shell separator and
the pattern has no notion of quoting context. Over the same corpus the raw count
climbed 331 → 335 → 337 → 340 while the anchored one was read as stable at 264;
the fifth reading returned 265, the new hit being a probe script written into a
heredoc at 2026-09-16T21:29:17 containing `tree=$(git merge-tree --write-tree a
b); mt=$?`, and the author's own PR-body draft was already in the count as a
fenced code block inside `cat > .../pr1121-body.md <<'BODY_EOF'`. A genuine
invocation from the same day, for contrast: `git merge-tree --write-tree
origin/main HEAD > tmp/q1052/mt.txt`. Only a parser that treats a heredoc body, a
quoted string and a comment as data separates the two — see *A scan counts text,
and text describing a command cannot be told from text that ran it* in the skill
body. Two sessions each built a careful anchor while actively discussing this
failure mode, and both counted their own drafts.

A control that anchors on a neighbouring string rather than the needle passes
through all three of the traps in this section — see *A control must exercise
the needle itself, somewhere it is known present* in the skill body.

## The tool may not be the tool

**A shell function can shadow the binary you think you are running.** Claude
Code restores shell state from a snapshot, and a function defined there wins
over the binary on `PATH`. Where `grep` resolves to a wrapper around a different
implementation, its flags differ — a rejected flag prints usage to stderr and
produces no matches, so a counting pipeline built on it reports zero and reads
as a real finding. Run `type grep` before trusting a count, and prefer a
dedicated search tool or a script when a zero is about to mean something.

Measured once: a per-session co-occurrence probe returned all zeros and read as
"the skill never co-occurs", when the command had never run at all. A working
earlier call is not evidence the next one ran, since the same invocation shape
can succeed elsewhere in the session.

**macOS ships BSD `sed` and `grep`, which lack GNU extensions silently.** `\b`,
`\+` and `\|` are not word-boundary and quantifier syntax to BSD `sed` — the
substitution matches nothing, changes nothing, and exits 0. Reach for `perl -pe`
or a script when a pattern needs GNU regex, and print a count or a diff after an
in-place edit rather than trusting the exit status.

**`git grep -E` has no word boundaries, and `git grep` without it does.** `\b`
is a GNU and PCRE extension, absent from POSIX ERE, so reaching for `-E` to get a
richer regex silently takes word boundaries away: the pattern degrades to a
literal, matches nothing, and exits 1 with empty stderr. `\<` and `\>` go the
same way. Measured 2026-09-03 under git 2.55.0 on macOS, over this file:

```
git grep -c -E 'grep\b'          nothing, exit 1
git grep -c    'grep\b'          15        -- the default is -G, which honours it
git grep -c -P 'grep\b'          15
git grep -c -E 'su\bstitution'   5         -- identical to -F 'substitution'
```

The last row is the mechanism: `\b` is read as a literal `b`, so `sig\b` searches
for `sigb`. Measured the same day in a sibling repo, a `sig\b` sweep over a
release checker holding `".sig"` reported the string gone, the migration off it
was skipped, and the failure surfaced a tag later in the one job that only runs
behind a tag. Use `-P`, or `-F` for a literal, and make the pattern find a line
you know is there before an empty sweep means anything.

**`git ls-tree` does not glob its pathspec.** It matches literal paths and
directory prefixes only, so `-- '*.go'` matches nothing where the same pathspec
handed to `git ls-files` matches every Go file in the tree. The mismatch is
invisible: the glob form exits 0 with empty stdout and empty stderr, so a
listing that matched nothing is indistinguishable from a tree that holds
nothing. Directory and exact-path pathspecs do agree across the two commands,
which is what makes the glob case surprising rather than obviously wrong.
`:(glob)` magic is rejected outright, and is the only form that says anything.
Narrow with a directory prefix, or list the tree unfiltered and filter in the
caller — swapping in `ls-files` is not the fix, since it reads the index rather
than the revision you reached for `ls-tree` to get.

**`git fetch --prune` deletes a `refs/remotes/origin/prNN` you built by hand.**
A ref created from `refs/pull/NN/head` maps to no remote branch under the default
refspec, so the prune reads it as a branch that has gone away and removes it.
Nothing announces the deletion, and the next `git show
"origin/pr92:docs/notes.md"` fails into empty output — which reads as *#92
does not contain that file*, clearing a PR of a defect it has. Measured 2026-09-04
over a twelve-PR run. This one fails in the clearing direction, which is the worst
of the two: verify the ref resolves (`git rev-parse --verify origin/pr92`)
immediately before you read through it, or re-fetch the pull ref in the same
command.

**`refs/remotes/origin/*` is what this clone fetched, not what the remote has.**
The namespace is called `remotes` and every entry is prefixed `origin/`, so a walk
of it reads as a walk of the remote — and it diverges in both directions at once.
A branch deleted upstream is retained; a ref hand-fetched into that namespace
(`refs/pull/N/head:refs/remotes/origin/prN`) is invented. A plain fetch repairs
neither, because pruning is off unless configured and nothing removes a ref you
made yourself. Constructed 2026-09-04 in an empty repository, both directions in
one run:

```
remote: refs/heads/main                     (doomed deleted; pull/7 pushed)
local:  refs/remotes/origin/doomed          retained after the delete
        refs/remotes/origin/main
        refs/remotes/origin/pr7             hand-fetched, never a branch
```

Three tracking entries, one remote branch, `fetch.prune` unset throughout. Ask
the remote — `git ls-remote --heads origin` — for any claim about which branches
exist. This is the entry above pointed the other way: there a prune deletes the
hand-made ref, here the namespace keeps it and reports it as a branch.

**And a shared ref store makes the absence unreadable too.** Every worktree of a
clone shares one ref store (`git rev-parse --git-common-dir`), so a stale or
hand-made ref is mutable by any session in it. Re-running the check later and
finding nothing does not distinguish *never existed* from *existed and was
cleaned up*, and refs carry no reflog for deletion — so there is nothing to read
afterwards. What that produced the same day is not a measurement but an
unresolvable dispute, which is the point: one session recorded such a ref at
18:05 with the command and the SHA it resolved to; a second had reported it
earlier, cannot re-derive it, and does not stand behind its method — it walked the
tracking namespace and called the result a listing of the remote, which is this
entry's own trap; a third found it absent at 18:20 and read that absence as
evidence the others had misread. No
instrument available to any of them can now decide it. Build the state and
observe it, as the block above does; a ref's history is not recoverable after the
fact, so a dispute about one is settled before it is deleted or not at all.

**A three-dot diff against an ancestor is empty whatever the path.** `git diff
A...B` is `merge-base(A,B)..B`, so where B is an ancestor of A the merge base is
B itself and the diff is empty by construction — `git diff --quiet
"origin/main...origin/main~5" -- <path>` reports no change for a path that has
churned all week. The shape shows up when building a known positive to validate
a sweep with, which is the worst place for it: a probe incapable of firing reads
as a control that passed. Pick a ref that is not an ancestor of the other side,
or use the two-dot form when the question is whether a path changed between two
commits.

**`git merge-tree` prints `Auto-merging <path>` when it *attempts* a content
merge on that path, not when one succeeds.** The same path can carry
`Auto-merging` and then `CONFLICT (content)` a few lines below it, so a scan
keyed on the reassuring line reports clean merges that conflict. Measured
2026-09-04 over the four pairs of open PRs touching one file:

```
453x455  Auto-merging=True  CONFLICT=False
453x454  Auto-merging=True  CONFLICT=False
455x456  Auto-merging=True  CONFLICT=False
454x455  Auto-merging=True  CONFLICT=True     <- same path, same output
```

**What makes this expensive rather than annoying is that sampling more cases
raises confidence without raising correctness.** The obvious remedy on noticing a
narrow scan — read all six pairs instead of three — hardens the wrong conclusion,
because every additional pair prints the same non-discriminating line. A reader
will not derive that, which is why it is worth stating: the two defects are
independent, and a sound instrument read over three of six still misses the pair
never opened.

**Exit status does not rescue it, being whole-merge rather than per-path.** All
four pairs above exit 1, including the three whose decisions-doc merge is clean —
some *other* file conflicts in each. Keying on the status to answer *does this
file conflict* returns a wrong answer whenever anything else in the tree does.
Read `CONFLICT (content): Merge conflict in <path>` for a path, or the stage
1/2/3 entries; scope the exit status to *did anything conflict at all*.

**Knowing this one does not protect you from it**, which is worth stating because
the entry reads as though it would. The wording first proposed for it recommended
keying on exit status — a third signal that could not have shown the opposite,
written into the warning about signals that cannot show the opposite, by a session
an hour deep in the defect. The same hour, this file's *a wrapped string is
invisible to `grep`* produced a false negative here: a probe for text known to be
present spanned a line break, reported it missing, and was believed until re-run
on a fragment that could not straddle. Reading the rule is not running it.

**What does protect you is having been told recently and by name**, which is the
case for this file rather than an argument against it. That zero was disbelieved
within seconds — not from care, but because the wrapped-string rule was in the
file open on screen, so the reading had a candidate cause before it had a
conclusion. A second session hit the same shape an hour later, probing for a
sentence it had written itself, and distrusted its own zero for the same reason:
the trap had been named to it twenty minutes earlier. Neither session was more
careful than the ones that shipped these defects. Both had the rule in working
memory rather than in a file they could have consulted, which is the difference
an entry can make and the whole of what it buys.


**A tracked file deleted with a bare `rm` is still in the index.** Tooling that
builds its file list from the index will fail on a path it cannot open. Stage
the deletion; the index is what a plain commit ships.

**The same mismatch is worse when the deletion is simulated**, because it lands
inside a test rather than in front of you. A case that `rm`s a file to exercise
code reading its file list from git leaves the path listed, so the harness raises
`FileNotFoundError` before the assertion under test ever runs. What comes back is
a *near*-match — `failures=1, errors=1` against a real `failures=2` — and a near
match invites being called close enough, where a wild miss would have been
investigated. Two sessions hit this independently on 2026-09-04. The general form
is worth carrying past git: simulate a state change through the same mechanism
the code under test reads it through.

## Git refs are shared mutable state

**`refs/remotes` lives in the common dir, so a sibling worktree moves it under
you.** `git rev-parse --git-common-dir` and `--git-dir` differ inside a
worktree, and remote-tracking refs are kept in the former. One clone measured on
2026-09-16 carried 264 worktrees under roughly 28 concurrent agent sessions:
`origin/main` there is not a ref that goes stale between your fetches, it is a
value other processes rewrite while you run nothing. Compare against a SHA you
captured, or against `git merge-base`, never against the live ref.

**Which fetch forms move it**, measured both ways on 2026-09-16 because the
obvious guess is wrong. `git fetch origin <branch>`, with an explicit refspec,
does **not** update other remote-tracking refs: rewinding
`refs/remotes/origin/main` and then fetching one unrelated branch left it
untouched, and in a throwaway clone an upstream advance plus `git fetch origin
other` left `origin/main` at the old SHA. A bare `git fetch origin` **does**,
through the default `+refs/heads/*:refs/remotes/origin/*`.

**A non-result that reads as a result.** `git fetch origin <deleted-branch>`
exits 128 and leaves the ref untouched, so a test of *did fetching move this
ref?* reads "did not move" — identical to the real negative, for reasons that
have nothing to do with the question. Only the exit code separates them.

**Install the undo before the mutation, not after it.** One of those two
measurements was taken by rewinding `refs/remotes/origin/main` in the shared
clone, which briefly induced, for every concurrent session, the exact failure
being characterised; and the restore was a plain `git update-ref` appended to
the end of the same chain rather than a `trap`, so any earlier failure would
have left the shared ref rewound with nothing to put it back. Measure in a
throwaway shallow clone in the session scratchpad, and where a mutation of
shared state is unavoidable, arm its undo first.

## Scope of a checker

**A checker run over an extracted subtree re-roots every relative path.**
Pulling one directory out of a tree and pointing a linter at it makes each
`../..` target and every `file.ext:N` citation report unresolvable. What comes
back is not an obvious error but a list of specific, plausible findings naming
real files, which is why it survives a second look. Extract the whole tree, or
run the checker from the directory the paths were written to resolve against.

**A failed extraction reports success, and the checker then passes over
nothing.** The rule above is a *partial* extraction; this is one that produced no
files at all. `git archive <ref> <path> | tar -x -C <dir>` exits 128 with
`fatal: pathspec ... did not match any files` when that path is absent from that
ref — a stale path, a directory that only exists on another branch — but the
pipeline reports `tar`'s status, and `tar` accepts an empty stream without
complaint. Measured on macOS: `git archive` alone exits 128, `tar` over an empty
archive exits 0. The destination is left empty, a linter pointed at it finds no
violations, and an empty store and a clean one print the same thing. Capture the
archive's own status (`git archive ... > t.tar; rc=$?`) and count the extracted
files before reading the checker's verdict.

## Sources

Distilled from traps measured in day-to-day agent sessions on macOS and zsh,
collected in a workstation `CLAUDE.md` before being promoted here so they reach
more than one machine.
