#!/usr/bin/env bash
#
# test-catalog-sync.sh — every tell the skill documents must be one the
# linter can catch.
#
# SKILL.md's Step 4 catalog and deslop-lint.py's word lists are the same
# knowledge written twice, so they drift: a term gets added to the prose and
# the linter silently stops covering the catalog it claims to check.
#
# Comparing the two as string sets does not work. The script deliberately
# carries inflections the prose does not spell out (tapestries, leveraging),
# truncated prefixes that catch a family ("in the ever-evolving"), contraction
# variants, and one entry — "ultimately" as a paragraph opener — that a
# separate regex handles rather than the phrase list. All of those read as
# drift to a set comparison and none of them are.
#
# So this checks behavior instead. Each catalog entry becomes a one-line probe
# containing that tell and nothing else; the linter must report at least one
# violation for it. What the entry is called internally, and which regex
# catches it, stay free to change.
#
# The reverse direction is not checked: the linter flags some terms the
# catalog does not list, which only makes it stricter than documented.
#
# Usage: test-catalog-sync.sh   (no arguments; run from anywhere)

set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
LINT="$HERE/deslop-lint.py"
SKILL="$HERE/../SKILL.md"

probe="$(mktemp)"
trap 'rm -f "$probe"' EXIT

bad=0

# Emit one probe line per catalog entry: vocabulary terms from the
# comma-separated list, phrases from the quoted list. Phrases lead the line so
# the paragraph-opener rule can see them.
mapfile -t probes < <(python3 - "$SKILL" <<'PY'
import re
import sys

skill = open(sys.argv[1], encoding="utf-8").read()

vocab = re.search(r"^Vocabulary \([^)]*\): (.+)$", skill, re.M).group(1)
for term in vocab.split(","):
    term = re.sub(r"\s*\(.*?\)", "", term).strip(" .")
    if term:
        print(f"{term}\tA sentence with {term} in it.")

phrases = re.search(r"^Phrases \([^)]*\): (.+)$", skill, re.M).group(1)
for phrase in re.findall(r'"([^"]+)"', phrases):
    lead = phrase[0].upper() + phrase[1:]
    print(f"{phrase}\t{lead}, and no other tells here.")
PY
)

if [[ ${#probes[@]} -lt 20 ]]; then
    printf 'test-catalog-sync: FAIL: parsed only %d catalog entries; the Step 4 lists moved\n' \
        "${#probes[@]}" >&2
    exit 1
fi

for row in "${probes[@]}"; do
    entry="${row%%$'\t'*}"
    printf '%s\n' "${row#*$'\t'}" > "$probe"
    # A caught tell prints the summary line plus at least one detector line.
    if [[ "$("$LINT" --mode voice "$probe" | wc -l)" -lt 2 ]]; then
        printf 'test-catalog-sync: FAIL: catalog lists "%s" but the linter does not flag it\n' \
            "$entry" >&2
        bad=1
    fi
done

if (( bad )); then
    exit 1
fi

printf 'test-catalog-sync: ok (%d catalog entries, all flagged)\n' "${#probes[@]}"
