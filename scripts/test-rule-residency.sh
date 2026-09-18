#!/usr/bin/env bash
# Checks scripts/rule-residency.py against fixtures whose answers are known by
# construction, and against a fixture it must reject. A control that only ever
# passes tells you nothing, so the twin fixture below is the point of this file:
# it confirms --self-test can fail before any green is read as evidence.
#
# Nothing here touches ~/.claude/projects. The corpus arm is machine state and
# changes between runs; what is testable is the parsing, the marker build, the
# self-test's own discrimination, and the verdict.
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

**A backup tape rewinds before the audit.** The reel spools to its magnetic
origin, and **the operator** reading a mid-paragraph emphasis is not a rule.

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

[ "$rc" -eq 0 ] && echo "test-rule-residency: all checks passed"
exit "$rc"
