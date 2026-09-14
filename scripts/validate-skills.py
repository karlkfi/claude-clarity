#!/usr/bin/env python3
"""validate-skills — check every skill's SKILL.md frontmatter.

It scans the frontmatter rather than parsing it. PyYAML is not a dependency of
this repo and `scripts/check-tools.sh` is the approved set of host tools, so
each check below names the rule it covers and none of them stands in for a
parse. Rule 2 is the one place the scan asks whether the block is YAML at all.

For each */SKILL.md it checks the rules from CLAUDE.md:
  1. The file opens with a YAML frontmatter block — line 1 is "---", closed
     by a matching "---".
  2. No unquoted inline value carries a colon followed by a space, or ends in
     one. YAML reads either as a nested mapping key and rejects the whole
     block, so a value written that way parses nowhere and the skill is one
     loader change away from not loading at all. The repair is a ">-" block
     scalar, which most descriptions here already use. This is narrower than a
     parse and deliberately so: a plain scalar continued onto an indented
     line, an unbalanced quote, and a " #" that YAML would read as a comment
     all pass here.
  3. `name:` equals the skill's directory name. A mismatch breaks the Skill
     tool's lookup.
  4. `description:` is present, non-empty, and at most 1024 characters. It is
     the trigger signal surfaced in the available-skills reminder, so an empty
     one means the skill never fires and an over-long one is rejected
     outright. Both inline and block-scalar (`>` / `|`) forms are accepted; a
     block scalar is measured as YAML folds it, one space per line join.

It also checks that every `scripts/*.sh` and `scripts/*.py` is executable, at
the repository root and under a skill both. A skill's script is invoked by
path — SKILL.md tells the user to run `~/.claude/skills/<skill>/scripts/<name>`,
and skills install as symlinks into that directory — so a script committed 644
is broken for every installer no matter how correct its contents are. The root
ones are invoked by path too: the README tells a reader to run
`./scripts/install-skills.sh`. Both pathspecs are needed because `*` crossing a
`/` still requires a character ahead of it, so `*/scripts/` reaches a skill's
directory and never the root one. The mode is read from the index rather than
the filesystem, since that is what other people clone.

Separately it reports two things as warnings, leaving the exit status alone.
A description within `DESC_WARN_MARGIN` of the cap is named with its measured
length, because the cap is otherwise a cliff — nothing tells a session it is
at 1021 until the clause that takes it to 1025. And a dated claim in a
SKILL.md body outside a Sources or Prior art section: `CLAUDE.md` puts
provenance in a companion doc under `docs/`. A date inside a worked example
can be load-bearing, and the script cannot tell which kind it is looking at.

Prints one line per problem and exits non-zero if any skill fails.
Run from the repo root.

ASKING FOR THE NUMBER

`--report` prints each description's measured length instead of gating, so a
session budgeting a new description or trimming a mid-range one can ask rather
than fold the block scalar again by hand. The count comes from `problems_with`,
the same call the cap is enforced through — a second fold is a second definition,
and the reimplementations this replaces came out two characters over on more than
half the skills here. With no arguments it reports every skill; given names
(`deslop`, or a path to a SKILL.md) it reports those, including a draft that is
not staged yet and so is invisible to the gate's own discovery.

It is a query, not the gate: an over-cap description is reported with the overage
and does not change the exit status, which is non-zero only for a name that could
not be read.

Usage:

    scripts/validate-skills.py                  # gate every skill
    scripts/validate-skills.py --report         # every description's length
    scripts/validate-skills.py --report deslop  # one, by name or by path
"""
import argparse
import re
import subprocess
import sys
from pathlib import Path

DESC_MAX = 1024

# Report a description this close to the cap. Sorted by length, the skills fall
# into an upper cluster and a long tail separated by a 14-character gap, and any
# margin from 14 to 27 names exactly the cluster; 20 is the midpoint of that
# range, which is the choice that survives the most drift in either direction
# before the band's membership changes. It warns and never fails — whether a
# nearly-full description is a problem depends on what the skill still has to
# say, which is the reader's call.
DESC_WARN_MARGIN = 20

# A `description:` whose value is one of these opens a block scalar; the text
# is on the indented lines that follow.
BLOCK_OPENERS = ("", ">", "|", ">-", "|-")

# A plain (unquoted) inline value may not contain a colon followed by a space,
# and may not end in one: YAML reads either as the start of a nested mapping
# and rejects the whole block with "mapping values are not allowed here". The
# two spellings are one rule, so both are matched — nothing in this repo has
# ever carried the second, and enforcing half a rule would leave the gate
# green on the half it skipped.
PLAIN_COLON = re.compile(r":(?=\s)|:$")

CLOSE = re.compile(r"---\s*")

DATE = re.compile(r"\b20\d\d-\d\d-\d\d\b")

# Provenance belongs under one of these, so a date below one is expected.
PROVENANCE_HEADING = re.compile(r"^#{2,}\s+(Sources|Prior art)\b", re.M)

# A `Sources` block is provenance, and the dated-claim check below deliberately
# skips it — a date there is expected. But the block is body text, charged on
# every invocation like any other, so "correctly filed within the file" and
# "not a cost" are different questions and only the first was being asked.
# The two skills this was set against each spent about a third of a body on
# Sources — 5,682 bytes of 17,545 and 2,551 of 9,609 — and neither was visible
# to any check here.
#
# Both thresholds have to trip, because either alone misfires: a large skill
# carries a big Sources at a trivial fraction (838 bytes at 0.5% is a real
# case), and a small one hits a high fraction with a block too small to be
# worth a file of its own. Set against those two cases rather than the current
# tree, which is clean at it — the nearest miss is rendered-page-review at
# 2,530 bytes and 14.2%, a bibliography of public links rather than a corpus,
# and the kind of call this warns about rather than decides.
SOURCES_WARN_BYTES = 2000
SOURCES_WARN_FRACTION = 0.20

# Ceilings by tier, from docs/skill-body-ceilings.md. A body is charged its
# size times the calls that follow it in the session that loaded it, so a tier
# is a residency band rather than a size band, and 24 KiB is the size the
# largest bodies here already work at rather than a budget invented for it.
TIER_CEILING = {"hot": 24 * 1024, "warm": 16 * 1024, "cold": 12 * 1024}

# Resident calls per invocation: hot is over 100, warm 50 to 100, cold under
# 50 or never fired. Only hot and warm are listed; a skill absent here is cold,
# which is the right default for one with no residency reading behind it yet.
#
# This replaced a per-skill byte budget, and the difference is what a raise
# costs. A number is negotiable in one line and was negotiated 49 times; a tier
# asserts a residency figure somebody can go and re-measure. Nothing here is an
# escape hatch for a body that grew — that is what the baseline below refuses.
# docs/skill-body-ceilings.md holds the provenance.
SKILL_TIER = {
    "code-restraint": "hot",
    "deslop": "hot",
    "rendered-page-review": "hot",
    "verify-claims": "hot",
    "brevity": "warm",
    "claim-provenance": "warm",
    "readability": "warm",
    "substantiate": "warm",
    "tech-docs-layers": "warm",
}


def git(*args):
    """NUL-separated `git` output as a list, or None when the call fails."""
    try:
        out = subprocess.run(
            ("git", *args), capture_output=True, text=True, check=True
        ).stdout
    except (OSError, subprocess.CalledProcessError):
        return None
    return [entry for entry in out.split("\0") if entry]


def quoted(value):
    """Whether a frontmatter value is a quoted scalar, where a colon is text.

    The closing quote is checked as well as the opening one. An unbalanced
    quote is not a quoted scalar — YAML rejects it too — so treating it as one
    would exempt the line from the check most likely to catch it.
    """
    return len(value) > 1 and value[0] in "\"'" and value[-1] == value[0]


def problems_with(text, skill):
    """Every frontmatter problem in one SKILL.md, and the description's length.

    The description is folded the way YAML folds a block scalar — one space per
    line join — so that it can be measured in characters, which is what the cap
    counts. A blank line does not end the scalar; any unindented line does.

    The length comes back rather than being judged here, so that the caller can
    report the warning band the way it reports dated claims — separately from
    the failures, and without changing the exit status.
    """
    lines = text.splitlines()
    if not lines or lines[0] != "---":
        return ['missing YAML frontmatter (line 1 is not "---")'], None

    name = None
    have_desc = folded = block = closed = False
    parts = []
    fatal_colons = []

    for line in lines[1:]:
        if CLOSE.fullmatch(line):
            closed = True
            break
        if not line.strip():
            continue
        if line[0].isspace():
            if block:
                parts.append(line.strip())
            continue
        block = False
        key, _, value = line.partition(":")
        value = value.strip()
        if line.startswith("name:"):
            name = value.replace('"', "").strip()
        elif line.startswith("description:"):
            have_desc = True
            block = folded = value in BLOCK_OPENERS
            if not block:
                parts.append(value)
        # Every unindented line, not just the two keys above: a colon is fatal
        # to the block wherever it lands, and the scan should not be quiet
        # about a field it does not otherwise read.
        if not block and not quoted(value):
            hit = PLAIN_COLON.search(value)
            if hit:
                fatal_colons.append((key, hit.start()))

    desc = " ".join(parts)
    problems = []
    if not closed:
        problems.append('frontmatter not closed with "---"')
    for key, offset in fatal_colons:
        problems.append(
            f'"{key}:" is an unquoted inline value with a colon at offset '
            f"{offset} that YAML reads as a nested mapping key, so the whole "
            'frontmatter block fails to parse; move the value under a ">-" '
            "block scalar"
        )
    if name is None:
        problems.append('frontmatter has no "name:" field')
    elif name != skill:
        problems.append(f'name "{name}" does not match directory "{skill}"')
    if not have_desc:
        problems.append('frontmatter has no "description:" field')
    elif folded and not desc:
        problems.append('"description:" block scalar is empty')
    elif len(desc) > DESC_MAX:
        problems.append(
            f'"description:" is {len(desc)} characters, '
            f"over the {DESC_MAX}-character limit"
        )
    return problems, len(desc) if have_desc else None


def dated_claims(text):
    """Lines carrying an ISO date in a SKILL.md body, outside Sources.

    `CLAUDE.md` puts provenance — the date, the batch, the counts — in a
    companion doc, because a skill is loaded whole on every invocation while a
    date is only wanted by someone deciding whether to *change* the rule.

    Only the date is mechanically visible; a batch or a count reads like any
    other number. And a date can be load-bearing inside a worked example, where
    it is what makes a case a measurement rather than an anecdote. So this
    reports and never fails: which side of that line a hit falls on is the
    reader's call, not the script's.
    """
    body = text.split("\n---\n", 1)[-1]
    cut = PROVENANCE_HEADING.search(body)
    if cut:
        body = body[: cut.start()]
    return [line.strip() for line in body.splitlines() if DATE.search(line)]


def bulky_sources(text):
    """This body's `Sources` block when it is both large and disproportionate.

    Returns `(size, fraction)` or `None`. Warns rather than fails: whether a
    block is a corpus that belongs in a companion doc or a bibliography of
    public links a reader may want to follow is a content judgement, and only
    the first is worth moving. `CLAUDE.md` reserves the failing tier for a
    repair the script is certain of, and this one leaves the decision in the
    reader's hands.
    """
    body = text.split("\n---\n", 1)[-1]
    found = PROVENANCE_HEADING.search(body)
    if not found or not body:
        return None
    size = len(body[found.start():].encode("utf-8"))
    fraction = size / len(body.encode("utf-8"))
    if size > SOURCES_WARN_BYTES and fraction > SOURCES_WARN_FRACTION:
        return size, fraction
    return None


def baseline_sizes(base, files):
    """Each body's size at `base`, in bytes, or None when there is no base.

    A path absent at `base` reads 0; a *missing base* is not that, and the
    caller skips the check rather than passing a zero for every skill. The two
    look alike and are opposite: 0 means "this skill is new, so meet the tier
    ceiling", and no base means there is no claim to make at all.

    The grandfather is the merged tree rather than a number in this file. A
    body already over its tier ceiling may not grow, and the allowance it gets
    falls on its own as the splits land — with nothing to edit, so nothing to
    raise and nothing for two branches to collide on. A new skill has no
    baseline, reads 0, and meets its tier ceiling outright.
    """
    sizes = {}
    for file in files:
        try:
            out = subprocess.run(
                ("git", "show", f"{base}:{file}"), capture_output=True, check=True
            ).stdout
        except (OSError, subprocess.CalledProcessError):
            sizes[file] = 0
        else:
            sizes[file] = len(out)
    return sizes


def oversize(file, text, skill, baseline):
    """This body's size and the limit it broke, or None.

    The limit is the looser of the skill's tier ceiling and what the body
    measured at the merge base, so the check asserts one thing: no body grew
    past its ceiling on this branch. That **fails** — `CLAUDE.md` reserves the
    warning tier for a repair a reader has to decide inside, and this one names
    the bytes to take back out of the diff. The tier ceilings are a target a
    body works toward, not a size any reviewer is asked to adjudicate.
    """
    size = len(text.encode("utf-8"))
    ceiling = TIER_CEILING[SKILL_TIER.get(skill, "cold")]
    limit = max(ceiling, baseline)
    if size <= limit:
        return None
    return (file, skill, size, limit, ceiling, baseline)


def find_skills():
    """Every SKILL.md to validate, preferring git's view of what is tracked."""
    tracked = git("ls-files", "-z", "*SKILL.md")
    if tracked is None:
        return sorted(
            str(p) for p in Path(".").glob("**/SKILL.md") if ".git" not in p.parts
        )

    # An untracked SKILL.md is invisible to git ls-files, so a run over a new
    # skill validates nothing and still exits 0. Name them: a clean pass that
    # skipped the file under review is worse than a failure. Warn rather than
    # fail, since an unstaged work-in-progress skill is legitimate.
    untracked = git("ls-files", "-z", "--others", "--exclude-standard", "*SKILL.md")
    if untracked:
        print(
            f"validate-skills: WARNING: {len(untracked)} untracked SKILL.md "
            "not validated (stage to include):",
            file=sys.stderr,
        )
        for path in untracked:
            print(f"  {path}", file=sys.stderr)
    return tracked


def check_modes():
    """Report scripts that are not executable; returns (count, bad)."""
    entries = git(
        "ls-files",
        "-s",
        "-z",
        "*/scripts/*.sh",
        "*/scripts/*.py",
        "scripts/*.sh",
        "scripts/*.py",
    )
    if entries is None:
        paths = sorted(
            str(p)
            for pattern in ("**/scripts/*.sh", "**/scripts/*.py")
            for p in Path(".").glob(pattern)
            if ".git" not in p.parts
        )
        bad = 0
        for path in paths:
            if not Path(path).stat().st_mode & 0o111:
                print(
                    f"validate-skills: {path}: not executable; "
                    f"fix with chmod +x {path}",
                    file=sys.stderr,
                )
                bad += 1
        return len(paths), bad

    bad = 0
    for entry in entries:
        meta, path = entry.split("\t", 1)
        mode = meta.split(" ", 1)[0]
        if mode != "100755":
            print(
                f"validate-skills: {path}: mode {mode}, not executable; "
                f"fix with git update-index --chmod=+x {path}",
                file=sys.stderr,
            )
            bad += 1
    return len(entries), bad


def measure(file):
    """One skill's measured description length, from the enforcer's own fold."""
    path = Path(file)
    _, length = problems_with(
        path.read_text(encoding="utf-8"), path.parent.resolve().name
    )
    return length


def resolve(name):
    """A SKILL.md path from a skill name, a directory, or a path to the file."""
    candidate = Path(name)
    if candidate.is_file():
        return candidate
    nested = candidate / "SKILL.md"
    if nested.is_file():
        return nested
    return None


def report(names):
    """Print each description's measured length. Returns a process exit status."""
    if names:
        files, missing = [], []
        for name in names:
            path = resolve(name)
            if path:
                files.append(str(path))
            else:
                missing.append(name)
        for name in missing:
            print(f"validate-skills: {name}: no SKILL.md found", file=sys.stderr)
        if not files:
            return 1
    else:
        files, missing = find_skills(), []
        if not files:
            print("validate-skills: no SKILL.md files found", file=sys.stderr)
            return 1

    print(
        f"validate-skills: description lengths, folded as the gate folds them "
        f"(cap {DESC_MAX}, warning band {DESC_WARN_MARGIN})"
    )
    rows = []
    for file in files:
        try:
            rows.append((measure(file), file))
        except OSError as exc:
            print(f"validate-skills: {file}: {exc.strerror}", file=sys.stderr)
            missing.append(file)
    # Longest first: the reason to ask is almost always how much room is left,
    # and the skills with least of it are the ones being asked about.
    order = sorted(rows, key=lambda r: -1 if r[0] is None else r[0], reverse=True)
    for length, file in order:
        if length is None:
            print(f"  {file:<44} no description:")
            continue
        left = DESC_MAX - length
        note = "over the cap" if left < 0 else "left"
        band = "  <- within the warning band" if 0 <= left <= DESC_WARN_MARGIN else ""
        print(f"  {file:<44} {length:>5}  {abs(left):>4} {note}{band}")
    return 1 if missing else 0


def main():
    ap = argparse.ArgumentParser(
        description="Validate every skill's SKILL.md frontmatter."
    )
    ap.add_argument(
        "--report",
        nargs="*",
        metavar="SKILL",
        help="print measured description lengths instead of gating "
        "(default: every skill; or name skills or SKILL.md paths)",
    )
    ap.add_argument(
        "--base",
        default="origin/main",
        help="the ref body sizes are grandfathered against (default: origin/main)",
    )
    ap.add_argument(
        "--strict",
        action="store_true",
        help="treat an unreadable merge base as a failure; pass it where the "
        "history is guaranteed to be there",
    )
    args = ap.parse_args()
    if args.report is not None:
        return report(args.report)

    files = find_skills()
    if not files:
        print("validate-skills: no SKILL.md files found", file=sys.stderr)
        return 1

    # The body check asserts that no body grew past its tier ceiling on this
    # branch, and that sentence needs a base to be about anything. Without one
    # the check does not run at all — it is skipped, not measured against a
    # baseline of zero, which would report every grandfathered body as having
    # grown and is what this did until the no-base path was reviewed. The skip
    # is loud, and CI passes --strict, so the one place this gate is guaranteed
    # to run is not also a place it can silently not run. Same treatment as the
    # flag. The skip is reachable in ordinary use too: any workflow that
    # extracts a tree with `git archive` and `git init` and runs `make check`
    # inside it has no remote ref to resolve.
    found = git("merge-base", args.base, "HEAD")
    base = found[0].strip() if found else None
    baselines = baseline_sizes(base, files) if base else None

    fail = False
    dated = {}
    near_cap = {}
    bodies = []
    sources = {}
    unreadable = []
    for file in files:
        path = Path(file)
        try:
            text = path.read_text(encoding="utf-8")
        except OSError as exc:
            unreadable.append(f"{file}: {exc.strerror}")
            continue
        problems, length = problems_with(text, path.parent.resolve().name)
        for problem in problems:
            print(f"validate-skills: {file}: {problem}", file=sys.stderr)
        fail = fail or bool(problems)
        if length is not None and 0 <= DESC_MAX - length <= DESC_WARN_MARGIN:
            near_cap[file] = length
        hits = dated_claims(text)
        if hits:
            dated[file] = hits
        if baselines is not None:
            over = oversize(file, text, path.parent.resolve().name, baselines[file])
            if over:
                bodies.append(over)
        bulky = bulky_sources(text)
        if bulky:
            sources[file] = bulky

    for entry in unreadable:
        print(f"validate-skills: {entry}", file=sys.stderr)
    if unreadable:
        print(
            f"validate-skills: {len(unreadable)} path(s) in the file list could "
            "not be read. The list comes from the index, so a tracked file deleted "
            "on disk stays in it until the deletion is staged — the index is what "
            "a plain `git commit` ships. Stage it and re-run.",
            file=sys.stderr,
        )

    scripts, bad_modes = check_modes()
    if fail or bad_modes or unreadable:
        return 1

    if near_cap:
        print(
            f"validate-skills: WARNING: {len(near_cap)} description(s) within "
            f"{DESC_WARN_MARGIN} characters of the {DESC_MAX}-character cap. "
            "One more clause fails the gate, so budget the space before "
            "writing it:",
            file=sys.stderr,
        )
        for file, length in sorted(near_cap.items()):
            print(
                f"  {file}: {length} characters, {DESC_MAX - length} left",
                file=sys.stderr,
            )

    if dated:
        total = sum(len(hits) for hits in dated.values())
        print(
            f"validate-skills: WARNING: {total} dated claim(s) in "
            f"{len(dated)} skill(s); CLAUDE.md puts provenance in a companion "
            "doc under docs/. A date inside a worked example can be "
            "load-bearing — decide per hit:",
            file=sys.stderr,
        )
        for file, hits in sorted(dated.items()):
            for line in hits:
                print(f"  {file}: {line[:88]}", file=sys.stderr)

    if sources:
        print(
            f"validate-skills: WARNING: {len(sources)} Sources block(s) over "
            f"{SOURCES_WARN_BYTES:,} bytes and {SOURCES_WARN_FRACTION:.0%} of "
            "the body. The dated-claim check skips Sources, so this is the "
            "half it cannot see; a block that is a corpus belongs in a "
            "companion doc under docs/, and one that is a "
            "bibliography of public links can stay:",
            file=sys.stderr,
        )
        for file, (size, fraction) in sorted(sources.items()):
            print(
                f"  {file}: {size:,} bytes, {fraction:.1%} of the body",
                file=sys.stderr,
            )

    if base is None:
        print(
            f"validate-skills: no merge base between {args.base} and HEAD, so "
            "the body-ceiling check did not run — it asserts that no body grew "
            "past its ceiling, and there is nothing here to have grown from. "
            "Fetch it, deepen a shallow clone, or pass --base",
            file=sys.stderr,
        )

    if bodies:
        # An error rather than a warning, and the split is the repair rather
        # than the certainty. `CLAUDE.md` reserves the warning tier for a
        # repair a reader has to make a decision inside; this one names the
        # bytes to take back out of the diff, so the actor applies it and
        # nobody is interrupted. Before this class moved off advisory, three
        # bodies sat past their ceilings across six commits and six gate runs
        # and the number was raised zero times. The two warnings that remain
        # below — dated claims and a near-cap description — each leave a
        # judgement in the fix and stay advisory.
        print(
            f"validate-skills: {len(bodies)} skill body(ies) grew past the "
            "ceiling. A body is re-read on every call after the one that loads "
            "it, so a kilobyte here is paid about a hundred times per "
            "session:",
            file=sys.stderr,
        )
        for file, skill, size, limit, ceiling, baseline in sorted(bodies):
            tier = SKILL_TIER.get(skill, "cold")
            note = (
                f"{size - limit:,} over the {baseline:,} it measured at the "
                f"merge base"
                if limit > ceiling
                else f"{size - limit:,} over the {ceiling:,}-byte {tier} ceiling"
            )
            print(f"  {file}: {size:,} bytes, {note}", file=sys.stderr)
        print(
            "  Take those bytes back out of this diff. There is no budget to "
            "raise: a body already over its tier ceiling is grandfathered at "
            "what it measured on main and may only shrink from there "
            "(docs/skill-body-ceilings.md records why).",
            file=sys.stderr,
        )

    if base is None and args.strict:
        print(
            "validate-skills: --strict was passed, so an unreadable merge base "
            "is a failure",
            file=sys.stderr,
        )
        return 1
    if bodies and base is not None:
        return 1

    print(f"validate-skills: {len(files)} skill(s), {scripts} script(s) OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
