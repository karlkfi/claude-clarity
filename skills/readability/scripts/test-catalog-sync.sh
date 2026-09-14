#!/usr/bin/env bash
# Does the script still check what SKILL.md says it checks?
#
# Not a string diff against the prose — the skill legitimately describes three
# kinds of unintroduced term while the script attempts one, and a diff would
# report that standing split as drift every run until someone deleted the test.
# Instead each documented claim becomes an input the script must react to.
#
# Warn where a human has to settle it; fail only where this script is certain.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
lint="$here/readability-lint.py"
skill="$here/../SKILL.md"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
fails=0
warns=0

# --- claims the skill makes about the script, each as a probe --------------

# "checks the third kind and only the third kind"
cat >"$tmp/coined.md" <<'MD'
The XYZ budget is fixed.

Nothing may exceed the XYZ budget.
MD
if "$lint" "$tmp/coined.md" >/dev/null 2>&1; then
	echo "FAIL the skill says the script catches an unexpanded coinage; it did not"
	fails=$((fails + 1))
else
	echo "ok   catches the coined shorthand the skill calls the worst case"
fi

# "a shorthand used twice or more" — the stated threshold, both sides of it
cat >"$tmp/once.md" <<'MD'
The XYZ budget is fixed and nothing else mentions it.
MD
if "$lint" "$tmp/once.md" >/dev/null 2>&1; then
	echo "ok   one use is below the documented threshold and is not flagged"
else
	echo "FAIL the skill documents a two-use threshold; one use was flagged"
	fails=$((fails + 1))
fi

# "--known-file is for what the reader already has"
printf 'XYZ\n' >"$tmp/known.txt"
if "$lint" --known-file "$tmp/known.txt" "$tmp/coined.md" >/dev/null 2>&1; then
	echo "ok   --known-file suppresses a finding, as the skill says it does"
else
	echo "FAIL the skill says --known-file settles the audience question; it did not"
	fails=$((fails + 1))
fi

# --- the split the skill declares, which only a reader can confirm ---------
if grep -q 'third kind and only the third kind' "$skill"; then
	echo "ok   SKILL.md still scopes the script to one of the three kinds"
else
	echo "WARN SKILL.md no longer says the script covers only the third kind."
	echo "     Someone widened or narrowed the claim. Decide whether the script"
	echo "     grew to match it, or whether the sentence is now overselling."
	warns=$((warns + 1))
fi

# The skill's own invocation line has to be runnable as written.
if grep -q 'readability/scripts/readability-lint.py --known-file' "$skill"; then
	echo "ok   SKILL.md's invocation line names the flags the script accepts"
else
	echo "WARN SKILL.md's invocation line changed; re-check it against --help."
	warns=$((warns + 1))
fi

((warns)) && echo "test-catalog-sync: $warns warning(s) for a human to settle"
if ((fails)); then
	echo "test-catalog-sync: $fails check(s) failed"
	exit 1
fi
echo "test-catalog-sync: all checks passed"
