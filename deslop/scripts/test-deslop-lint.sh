#!/usr/bin/env bash
#
# test-deslop-lint.sh — smoke test for deslop-lint.py.
#
# The failure mode of a regex-driven linter is a pattern that quietly stops
# matching: the script still runs, still exits 0, and reports a clean draft.
# A syntax check cannot see that, so these cases pin both ends of the range.
#
#   1. testdata/slop.md is built from the tell catalog and must score far
#      above zero in voice mode, with the structural detectors firing by name
#      (a vocabulary-only hit would mean the regexes died and the word list
#      carried the score).
#   2. testdata/clean.md is written inside the skill's own rules and must
#      score exactly zero in plain mode, which is the stricter direction —
#      a detector that over-matches shows up here as a false positive.
#   3. A bad --mode exits non-zero with usage rather than a traceback.
#
# Usage: test-deslop-lint.sh   (no arguments; run from anywhere)

set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
LINT="$HERE/deslop-lint.py"
DATA="$HERE/testdata"

bad=0

fail() {
    printf 'test-deslop-lint: FAIL: %s\n' "$1" >&2
    bad=1
}

# Pull one `field=value` off the summary line the linter prints per file.
field() {
    awk -v f="$1" 'NR==1 { for (i = 1; i <= NF; i++) if (index($i, f "=") == 1) { sub(f "=", "", $i); print $i } }'
}

slop="$("$LINT" --mode voice "$DATA/slop.md")"
clean="$("$LINT" --mode plain "$DATA/clean.md")"

slop_score="$(field per100w <<<"$slop")"
if ! awk -v s="$slop_score" 'BEGIN { exit !(s > 10) }'; then
    fail "slop.md scored $slop_score per100w, want > 10 (detectors may have stopped matching)"
fi

for detector in vague_attribution unearned_significance negative_parallelism \
    no_x_no_y_just_z false_range tacked_on_analysis summary_opener slop_phrase; do
    grep -q "^  $detector " <<<"$slop" || fail "slop.md did not trip $detector"
done

clean_total="$(field total <<<"$clean")"
if [[ "$clean_total" != "0" ]]; then
    fail "clean.md scored $clean_total violations, want 0:"$'\n'"$clean"
fi

if "$LINT" --mode nonsense "$DATA/clean.md" >/dev/null 2>&1; then
    fail "an unknown --mode exited 0; expected usage and non-zero"
fi

if (( bad )); then
    exit 1
fi

printf 'test-deslop-lint: ok (slop %s per100w, clean %s violations)\n' "$slop_score" "$clean_total"
