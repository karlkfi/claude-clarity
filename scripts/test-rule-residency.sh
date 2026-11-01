#!/usr/bin/env bash
# Checks scripts/rule-residency.py against fixtures whose answers are known by
# construction, and against a fixture it must reject. A control that only ever
# passes tells you nothing, so the twin fixture below is the point of this file:
# it confirms --self-test can fail before any green is read as evidence.
#
# Nothing here touches ~/.claude/projects. That corpus is machine state and
# changes between runs; what is testable is the parsing, the marker build, the
# self-test's own discrimination, and the verdict. The two-reading arm at the
# end fabricates a transcript tree of its own and points the module's PROJECTS
# global at it, so its answers are fixed by construction like the rest.
set -uo pipefail

cd "$(dirname "$0")/.." || exit 1
PROBE=scripts/rule-residency.py
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
rc=0

ok() { printf 'ok   %s\n' "$1"; }
bad() { printf 'FAIL %s\n' "$1"; rc=1; }

mkdir -p "$tmp/good" "$tmp/twin"

# Two rules. The bold span mid-paragraph is emphasis, not a third rule: it lands
# at the start of a line only because the prose wrapped there.
cat > "$tmp/good/SKILL.md" <<'EOF'
---
name: good
description: fixture
---

# Good

## One

**A backup tape rewinds before the audit.** The reel spools to its magnetic origin, and
**the operator** reading a mid-paragraph emphasis is not a rule.

**Blue herons nest downstream of the weir.** Counting nests from the towpath
undercounts the colony by roughly a third.
EOF

# The same rule twice. Its lead belongs to the first copy, and the second has
# nothing left that is unique to it -- which is what a rule the probe cannot
# distinguish looks like, and what --self-test exists to refuse.
cat > "$tmp/twin/SKILL.md" <<'EOF'
---
name: twin
description: fixture
---

# Twin

## One

**A backup tape rewinds before the audit.** The reel spools to its magnetic origin.

**A backup tape rewinds before the audit.** The reel spools to its magnetic origin.
EOF

# A lead too long for one line closes its bold span on the next. An opening
# that never closes is not a rule, whether it would borrow the `**` of the
# paragraph after it or of inline bold later in its own.
mkdir -p "$tmp/wrapped"
cat > "$tmp/wrapped/SKILL.md" <<'EOF'
---
name: wrapped
description: fixture
---

# Wrapped

## One

**A backup tape rewinds before the audit.** The reel spools to its magnetic origin.

**Stray markup opens this paragraph and
never closes it.

**Unclosed markup opens this one, and
later **inline bold** sits in the same paragraph.

**Blue herons nest downstream of the weir, and the count from the
towpath runs low.** Counting nests undercounts the colony by roughly a third.
EOF

out=$(python3 - "$tmp/wrapped/SKILL.md" <<'EOF'
import importlib.util, sys
spec = importlib.util.spec_from_file_location("rr", "scripts/rule-residency.py")
rr = importlib.util.module_from_spec(spec); spec.loader.exec_module(rr)
rules = rr.load_rules(sys.argv[1])
print("leads:", " | ".join(r["lead"] for r in rules))
print("folded:", "herons" in rules[0]["text"])
EOF
)
case $out in
    *"leads: A backup tape rewinds before the audit | Blue herons nest downstream of the weir, and the count from the towpath runs low"$'\n'*)
        ok  "a lead wrapped onto a second line is a rule, named in full" ;;
    *)  bad "a lead wrapped onto a second line is a rule, named in full"$'\n'"$out" ;;
esac
case $out in
    *"folded: False"*) ok   "a wrapped lead's paragraph is not folded into the rule before it" ;;
    *)                 bad "a wrapped lead's paragraph is not folded into the rule before it"$'\n'"$out" ;;
esac

out=$("$PROBE" "$tmp/good/SKILL.md" --self-test 2>&1); status=$?
if [ "$status" -eq 0 ]; then
    ok "a well-formed body passes --self-test"
else
    bad "a well-formed body passes --self-test (exit $status)"$'\n'"$out"
fi
case $out in
    *"rules: 2"*) ok   "mid-paragraph emphasis is not counted as a rule" ;;
    *)            bad "mid-paragraph emphasis is not counted as a rule"$'\n'"$out" ;;
esac

out=$("$PROBE" "$tmp/twin/SKILL.md" --self-test 2>&1); status=$?
if [ "$status" -eq 1 ]; then
    ok "--self-test rejects a rule it cannot tell from its twin"
else
    bad "--self-test rejects a rule it cannot tell from its twin (exit $status)"$'\n'"$out"
fi
case $out in
    *MISS*) ok   "the rejection names the rule it could not find" ;;
    *)      bad "the rejection names the rule it could not find"$'\n'"$out" ;;
esac

# The verdict reads rates, not raw counts: POST is the longer window by
# construction, so a rule firing at an unchanged rate must not read as uptake.
out=$(python3 - <<'EOF'
import importlib.util
spec = importlib.util.spec_from_file_location("rr", "scripts/rule-residency.py")
rr = importlib.util.module_from_spec(spec); spec.loader.exec_module(rr)
reach = {"use:post:action:blocks": 1000, "use:pre:action:blocks": 100,
         "use:post:prose:blocks": 1000, "use:pre:prose:blocks": 100}
def row(**kw):
    r = dict(corpus=0, post_action=0, pre_action=0, post_prose=0, pre_prose=0)
    r.update(kw)
    r["corpus"] = r["post_action"] + r["pre_action"] + r["post_prose"] + r["pre_prose"]
    return r
print("silent",  rr.verdict(row(), reach))
# More raw hits after the load and a lower rate: the case that separates the
# two readings. Equal counts would pass under either and pin nothing.
print("flat",    rr.verdict(row(post_action=15, pre_action=10), reach))
print("uptake",  rr.verdict(row(post_action=20, pre_action=1), reach))
print("talked",  rr.verdict(row(post_prose=20, pre_prose=1), reach))
EOF
)
check() {
    case $out in
        *"$1 $2"*) ok   "$3" ;;
        *)         bad "$3"$'\n'"$out" ;;
    esac
}
check silent BLIND "a rule that never fires anywhere reads BLIND, not unused"
check flat   FLAT  "more hits in a window ten times the size is not uptake"
check uptake RAN   "a rule firing in commands at a raised rate reads RAN"
check talked SAID  "a rule firing only in prose reads SAID"

# Which sessions count as authoring decides the whole table, and only the
# `# authoring repos` line and the --json `repos` key say which reading was
# taken. So one fabricated tree is read twice, each run marking the other's
# project as authoring. The sessions mirror each other: the same block counts,
# so the runs' stderr differs only in that line, and opposite rules firing
# after the load, so the verdicts read [RAN, FLAT] against [FLAT, RAN].
# Keys are read with .get so a missing one fails an assertion by name.
mkdir -p "$tmp/residencyfixture" "$tmp/projects/-work-aardvarkrepo" "$tmp/projects/-work-zebrarepo"
cat > "$tmp/residencyfixture/SKILL.md" <<'EOF'
---
name: residencyfixture
description: fixture
---

# Residency fixture

## One

**Backup tapes rewind before audits.** The reel spools to its magnetic origin.

**Blue herons nest below weirs.** Counting nests from the towpath runs low.
EOF
out=$(python3 - "$tmp" <<'EOF'
import contextlib, importlib.util, io, json, sys
tmp = sys.argv[1]
spec = importlib.util.spec_from_file_location("rr", "scripts/rule-residency.py")
rr = importlib.util.module_from_spec(spec); spec.loader.exec_module(rr)
tape, heron = "backup tapes rewind before audits", "blue herons nest below weirs"
def act(text):
    return {"message": {"role": "assistant",
                        "content": [{"type": "tool_use", "input": {"command": text}}]}}
load = act(""); load["message"]["content"][0]["input"] = {"skill": "residencyfixture"}
for proj, before, after in (("aardvarkrepo", heron, tape), ("zebrarepo", tape, heron)):
    recs = [act(before), load, act(after), act(before)]
    with open(f"{tmp}/projects/-work-{proj}/s.jsonl", "w") as f:
        f.write("\n".join(json.dumps(r) for r in recs) + "\n")
rr.PROJECTS = rr.pathlib.Path(f"{tmp}/projects")
for repo, other in (("zebrarepo", "aardvarkrepo"), ("aardvarkrepo", "zebrarepo")):
    sys.argv = ["rule-residency.py", f"{tmp}/residencyfixture/SKILL.md",
                "--repo", repo, "--json", f"{tmp}/{repo}.json"]
    err = io.StringIO()
    with contextlib.redirect_stderr(err), contextlib.redirect_stdout(io.StringIO()):
        status = rr.main()
    first = (err.getvalue().splitlines() or [""])[0]
    try:
        doc = json.load(open(f"{tmp}/{repo}.json"))
    except (OSError, ValueError):
        doc = {}
    print(f"{repo} status {status}")
    print(f"{repo} names-own {repo in first and other not in first}")
    print(f"{repo} repos {doc.get('repos')}")
    print(f"{repo} verdicts {[r.get('verdict') for r in doc.get('rules', [])]}")
EOF
)
# Every line but the last argument must appear in the output whole.
claim() {
    local name=${*: -1} line
    for line in "${@:1:$#-1}"; do
        case $'\n'$out$'\n' in
            *$'\n'"$line"$'\n'*) ;;
            *) bad "$name"$'\n'"$out"; return ;;
        esac
    done
    ok "$name"
}
claim "zebrarepo names-own True" "aardvarkrepo names-own True" \
    "each reading's first line names its own authoring repo"
claim "zebrarepo repos ['zebrarepo']" "aardvarkrepo repos ['aardvarkrepo']" \
    "each reading's --json records its own repos"
claim "zebrarepo verdicts ['RAN', 'FLAT']" "aardvarkrepo verdicts ['FLAT', 'RAN']" \
    "the two readings of one corpus give the verdicts their segregation builds"

[ "$rc" -eq 0 ] && echo "test-rule-residency: all checks passed"
exit "$rc"
