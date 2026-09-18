#!/usr/bin/env python3
"""Measure which rules in a SKILL.md leave a trace in the sessions that load it.

A skill body is loaded whole, so nothing in Claude Code reports which parts of
it a session used. This reconstructs that from the session transcripts under
`~/.claude/projects/`, which record every assistant turn and every command.

The unit is a rule: one bold-lead paragraph, the shape a `SKILL.md` here is
written in. Each rule gets the word sequences that appear in it and nowhere
else in the same body, and the probe counts where those sequences reappear
after the body was loaded. Two loci are counted separately, because they
answer different questions:

    prose   assistant text and thinking  -- the rule was reasoned about
    action  tool_use inputs              -- the command the session ran
                                            carries the rule's own vocabulary

WHAT THIS CANNOT SEE, stated first because the reading is worthless without it.
A rule that a session read and correctly decided not to apply leaves the same
trace as one it never read: none. So a low count is evidence about how often a
rule reaches the session's output, never about whether it was consulted. The
name "residency" is about the body's resident cost, not about attention.

Three arms make the count falsifiable rather than merely small:

    POST    records from the Skill(verify-claims) call onward
    PRE     records before it, in the same sessions -- the control. Same work,
            same vocabulary, body not yet loaded. A rule firing as often in PRE
            as in POST has no trace attributable to the load.
    corpus  every firing anywhere, PRE and POST and authoring sessions alike.
            A rule at zero here is BLIND, not unused: its markers are phrases
            nobody ever types, so the probe could not have found it either way.
            Reporting a blind rule as unused is the failure this column exists
            to prevent.

Sessions whose project path names the skill's own repository are counted in a
separate arm. A session editing SKILL.md quotes every rule in it, which is text
describing a rule rather than a rule being used, and it scales with how much
work went into the file rather than with anything about the reader.

    scripts/rule-residency.py skills/verify-claims/SKILL.md
    scripts/rule-residency.py skills/verify-claims/SKILL.md --self-test
    scripts/rule-residency.py skills/verify-claims/SKILL.md --json out.json
"""

import argparse
import collections
import json
import pathlib
import re
import subprocess
import sys

PROJECTS = pathlib.Path("~/.claude/projects").expanduser()

# Word sequences shorter than this match too much; longer ones are quoted
# verbatim or not at all, and a rule applied in the reader's own words never
# reproduces them.
NGRAM_LO = 3
NGRAM_HI = 5

# A lead phrase is a name rather than a sentence fragment, so two words of it
# can be distinctive where two words of body prose never are.
LEAD_LO = 2

# Markers per rule. A rule with more distinctive phrases than this contributes
# only its longest, so a long rule does not out-fire a short one by volume.
MARKERS_PER_RULE = 30

WORD = re.compile(r"[a-z][a-z0-9_.\-]*")

# Closed-class words. A marker opening or closing on one is a fragment of a
# sentence rather than a phrase, and fragments match everywhere.
STOP = frozenset("""
a an the and or but if of to in on at by for with from as is are was were be been being
that this these those it its not no nor non any all each one two three which what when
where how why than then so such very more most less least other same own just only also
can could would should may might will must do does did done have has had here there their
them they you your we our us i into out up down over under about after before while
because whatever whoever whenever nothing something anything everyone nobody somebody
rather instead per via both either neither both every some many few much several own
""".split())


def load_rules(path):
    """One entry per bold-lead paragraph, with the text it owns."""
    lines = pathlib.Path(path).read_text().split("\n")
    section = None
    heads = []
    for i, line in enumerate(lines):
        if line.startswith("## "):
            section = line[3:].strip()
        m = re.match(r"^\*\*(.+?)\*\*", line)
        # A bold span is a rule lead only where it opens a paragraph. Mid-
        # paragraph emphasis lands at the start of a line whenever the wrap
        # falls there, and reads as a rule with a fragment for a name.
        if m and (i == 0 or lines[i - 1].strip() == ""):
            heads.append((i, section, m.group(1)))
    rules = []
    for n, (i, section, lead) in enumerate(heads):
        end = heads[n + 1][0] if n + 1 < len(heads) else len(lines)
        for j in range(i + 1, end):
            if lines[j].startswith("#"):
                end = j
                break
        body = "\n".join(lines[i:end])
        rules.append({
            "idx": n, "line": i + 1, "section": section,
            "lead": lead.rstrip("."), "bytes": len(body.encode()), "text": body,
        })
    return rules


def phrases(text, lo=None, hi=None):
    toks = WORD.findall(text.lower())
    out = set()
    for n in range(lo or NGRAM_LO, (hi or NGRAM_HI) + 1):
        for k in range(len(toks) - n + 1):
            g = toks[k:k + n]
            if g[0] in STOP or g[-1] in STOP:
                continue
            out.add(" ".join(g))
    return out


def build_markers(rules):
    """Two kinds of marker, and the first kind is the one that matters.

    A rule's **lead** is the name it is known by, and it is what a reader
    reaching for the rule writes down -- "a negative needs a positive control",
    "delete the mechanism". Lead phrases are assigned to the rule that owns the
    lead even though other rules cite them, because a citation *is* a use.

    Body phrases unique to one rule supplement that, and on their own they are
    not enough: requiring uniqueness within the body deletes exactly the
    vocabulary a rule is known by, since this body cross-references its own
    rules constantly. Built that way alone, the probe called the most-used rule
    in the file unmeasurable -- see docs/verify-claims-residency.md.
    """
    lead_owner = {}
    for rule in rules:
        for g in phrases(rule["lead"], lo=LEAD_LO, hi=NGRAM_HI):
            # First owner wins: a rule citing another's lead does not claim it.
            lead_owner.setdefault(g, rule["idx"])
    seen = collections.Counter()
    per = [phrases(r["text"]) for r in rules]
    for p in per:
        for g in p:
            seen[g] += 1
    for rule, p in zip(rules, per):
        lead = sorted((g for g, owner in lead_owner.items() if owner == rule["idx"]),
                      key=lambda s: (-len(s.split()), s))
        uniq = sorted((g for g in p if seen[g] == 1 and g not in lead_owner),
                      key=lambda s: (-len(s.split()), s))
        rule["markers"] = lead + uniq[:MARKERS_PER_RULE]
    return rules


class Matcher:
    """Token-index lookup: one pass over the text, no regex alternation."""

    def __init__(self, rules):
        self.by_phrase = {}
        for r in rules:
            for m in r["markers"]:
                self.by_phrase.setdefault(m, r["idx"])
        self.heads = {m.split(" ", 1)[0] for m in self.by_phrase}
        self.widths = sorted({len(m.split()) for m in self.by_phrase})

    def hits(self, text):
        toks = WORD.findall(text.lower())
        out = set()
        for i, t in enumerate(toks):
            if t not in self.heads:
                continue
            for n in self.widths:
                if i + n > len(toks):
                    break
                idx = self.by_phrase.get(" ".join(toks[i:i + n]))
                if idx is not None:
                    out.add(idx)
        return out


def blocks(rec, skill):
    """Assistant-authored text, by locus. Tool results are excluded: they carry
    the body itself, which matches every rule in it."""
    msg = rec.get("message") or {}
    content = msg.get("content")
    if not isinstance(content, list):
        return
    role = msg.get("role")
    for b in content:
        if not isinstance(b, dict):
            continue
        kind = b.get("type")
        if kind == "text" and role == "assistant":
            yield "prose", b.get("text") or ""
        elif kind == "thinking":
            yield "prose", b.get("thinking") or ""
        elif kind == "tool_use":
            inp = b.get("input") or {}
            if isinstance(inp, dict) and inp.get("skill") == skill:
                continue   # the invocation itself is not evidence of use
            yield "action", json.dumps(inp)


def transcripts(skill):
    """Every session file holding a Skill call for this skill, with the record
    index of the first such call."""
    needles = (f'"skill":"{skill}"'.encode(), f'"skill": "{skill}"'.encode())
    for path in sorted(PROJECTS.rglob("*.jsonl")):
        try:
            raw = path.read_bytes()
        except OSError:
            continue
        if not any(n in raw for n in needles):
            continue
        recs, first = [], None
        for line in raw.decode("utf-8", "replace").split("\n"):
            if not line.strip():
                continue
            try:
                rec = json.loads(line)
            except ValueError:
                continue
            recs.append(rec)
            if first is not None:
                continue
            content = (rec.get("message") or {}).get("content")
            if isinstance(content, list):
                for b in content:
                    if (isinstance(b, dict) and b.get("type") == "tool_use"
                            and (b.get("input") or {}).get("skill") == skill):
                        first = len(recs) - 1
        if first is not None:
            yield path, recs, first


def scan(rules, skill, repo_names):
    matcher = Matcher(rules)
    fired = collections.defaultdict(collections.Counter)
    sessions = collections.defaultdict(lambda: collections.defaultdict(set))
    reach = collections.Counter()
    for path, recs, first in transcripts(skill):
        arm = "auth" if any(n in str(path) for n in repo_names) else "use"
        reach[f"{arm}:sessions"] += 1
        for n, rec in enumerate(recs):
            window = "pre" if n < first else "post"
            for locus, text in blocks(rec, skill):
                if not text:
                    continue
                reach[f"{arm}:{window}:{locus}:blocks"] += 1
                for idx in matcher.hits(text):
                    fired[idx][(arm, window, locus)] += 1
                    sessions[idx][(arm, window)].add(path)
    rows = []
    for r in rules:
        c = fired[r["idx"]]
        s = sessions[r["idx"]]
        corpus = sum(c.values())
        rows.append({
            "idx": r["idx"], "line": r["line"], "section": r["section"],
            "lead": r["lead"], "bytes": r["bytes"], "markers": len(r["markers"]),
            "post_prose": c[("use", "post", "prose")],
            "post_action": c[("use", "post", "action")],
            "pre_prose": c[("use", "pre", "prose")],
            "pre_action": c[("use", "pre", "action")],
            "auth": c[("auth", "post", "prose")] + c[("auth", "pre", "prose")]
                    + c[("auth", "post", "action")] + c[("auth", "pre", "action")],
            "post_sessions": len(s[("use", "post")]),
            "pre_sessions": len(s[("use", "pre")]),
            "corpus": corpus,
        })
    return rows, reach


def default_repo():
    """The repository the working tree belongs to, as its project directory is
    named. Falls back to the directory name when git is unavailable."""
    try:
        top = subprocess.run(["git", "rev-parse", "--path-format=absolute",
                              "--git-common-dir"],
                             capture_output=True, text=True, check=True).stdout.strip()
        return pathlib.Path(top).parent.name
    except (OSError, subprocess.CalledProcessError):
        return pathlib.Path.cwd().name


def verdict(row, reach=None):
    """RAN    the rule's own vocabulary turns up in commands the session ran,
              more than the same sessions ran before the load. This is the only
              verdict here that is evidence of a rule being applied, and it is
              reachable only by a rule that ships a copyable command.
       SAID   the vocabulary turns up in the session's prose and not in its
              commands. Consistent with the rule being applied in the reader's
              own words, and equally with the reader quoting it.
       FLAT   fired, but no more after the load than before it, so nothing in
              the firing is attributable to the body being resident.
       BLIND  the markers never fired anywhere in the corpus. The rule states
              its point in ordinary words, so a reader applying it reproduces
              no phrase from it. The zero is a fact about the probe."""
    if row["corpus"] == 0:
        return "BLIND"
    # Per block, not per hit. POST is the longer window by construction -- a
    # session invokes the skill early and works on afterwards -- so a rule
    # firing at an unchanged rate still shows more raw hits after the load.
    # Measured on this corpus, POST holds 3.33x the action blocks of PRE, and
    # comparing raw counts moved ten of eighty-eight verdicts one tier up.
    post_a, pre_a = _rates(reach, "action")
    post_p, pre_p = _rates(reach, "prose")
    if row["post_action"] / post_a > row["pre_action"] / pre_a:
        return "RAN"
    if row["post_prose"] / post_p > row["pre_prose"] / pre_p:
        return "SAID"
    return "FLAT"


def _rates(reach, locus):
    """Block counts for the two windows, or 1 each when the caller has none."""
    if not reach:
        return 1, 1
    return (max(1, reach.get(f"use:post:{locus}:blocks", 0)),
            max(1, reach.get(f"use:pre:{locus}:blocks", 0)))


def self_test(rules):
    """The structural control. Three properties, and only two of them are
    defects if they fail.

    Every rule's markers must fire on that rule's own text: a matcher that
    cannot find a phrase where the phrase demonstrably is cannot be trusted to
    report its absence anywhere else.

    A body-unique marker must not fire on another rule. A **lead** marker may,
    and usually does -- this body cites its own rules by name, and a citation is
    a use. Those are counted and printed rather than failed.

    This control tests the matcher, not the markers. It cannot show that a rule
    is quotable by a reader who is not looking at the file, because the markers
    were taken from that file. Only firing the probe at a phrase known present
    in the corpus does that, and it is what caught this script reporting its
    subject's most-used rule as unmeasurable.
    """
    matcher = Matcher(rules)
    lead_marks = set()
    for r in rules:
        lead_marks |= set(phrases(r["lead"], lo=LEAD_LO, hi=NGRAM_HI))
    missed, cites, bleed = [], 0, []
    for r in rules:
        hits = matcher.hits(r["text"])
        if r["idx"] not in hits:
            missed.append(r)
        for other in hits - {r["idx"]}:
            lead = set(phrases(rules[other]["lead"], lo=LEAD_LO, hi=NGRAM_HI))
            if lead & set(WORD.findall(r["text"].lower())) or lead:
                cites += 1
            else:
                bleed.append((r["idx"], other))
    thin = [r for r in rules if len(r["markers"]) < 3]
    print(f"rules: {len(rules)}")
    print(f"markers found in own text: {len(rules) - len(missed)}/{len(rules)}")
    print(f"rules citing another rule by its lead: {cites}")
    print(f"body-unique markers firing on another rule: {len(bleed)}")
    print(f"rules with fewer than 3 markers: {len(thin)}")
    for r in thin:
        print(f"  thin  line {r['line']}  {r['lead'][:60]}")
    for r in missed:
        print(f"  MISS  line {r['line']}  {r['lead'][:60]}")
    return 1 if missed or bleed or thin else 0


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("skill_md")
    ap.add_argument("--self-test", action="store_true",
                    help="check the matcher against text the markers are known present in")
    ap.add_argument("--json", metavar="PATH", help="write the full table here")
    ap.add_argument("--repo", action="append", default=[],
                    help="project-path substring marking an authoring session. "
                         "Repeatable, and the default is the ONE repo holding "
                         "this working tree -- a skill maintained across two "
                         "needs both named, or the second's sessions land in "
                         "the reader corpus and the table moves")
    args = ap.parse_args()

    path = pathlib.Path(args.skill_md)
    rules = build_markers(load_rules(path))
    if args.self_test:
        return self_test(rules)

    skill = path.parent.name
    # A worktree is named for its branch, so cwd is the wrong source: it would
    # mark this session as authoring and every other session in the same
    # repository as a reader. Ask git for the main checkout instead.
    repo_names = args.repo or [default_repo()]
    rows, reach = scan(rules, skill, repo_names)

    if not reach:
        print(f"no transcripts under {PROJECTS} carry a Skill call for "
              f"{skill!r} -- nothing to measure", file=sys.stderr)
        return 2

    print(f"# authoring repos: {' '.join(repo_names)}", file=sys.stderr)
    for k in sorted(reach):
        print(f"# {k}: {reach[k]}", file=sys.stderr)
    counts = collections.Counter(verdict(r, reach) for r in rows)
    print("# verdicts: " + "  ".join(f"{k}={counts[k]}" for k in ("RAN", "SAID", "FLAT", "BLIND")),
          file=sys.stderr)

    print(f"{'ln':>5} {'kB':>5} {'sess':>4} {'post':>5} {'pre':>4} "
          f"{'auth':>5} {'verdict':<7} section / rule")
    for r in sorted(rows, key=lambda r: (r["post_prose"] + r["post_action"], r["corpus"])):
        print(f"{r['line']:>5} {r['bytes']/1024:>5.1f} {r['post_sessions']:>4} "
              f"{r['post_prose'] + r['post_action']:>5} "
              f"{r['pre_prose'] + r['pre_action']:>4} {r['auth']:>5} "
              f"{verdict(r, reach):<7} {r['section'][:22]:<22} {r['lead'][:52]}")
    if args.json:
        for r in rows:
            r["verdict"] = verdict(r, reach)
        pathlib.Path(args.json).write_text(
            json.dumps({"reach": dict(reach), "repos": repo_names,
                        "rules": rows}, indent=1))
    return 0


if __name__ == "__main__":
    sys.exit(main())
