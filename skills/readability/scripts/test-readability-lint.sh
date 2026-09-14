#!/usr/bin/env bash
# Behavioral tests for readability-lint.py.
#
# The load-bearing assertion is the last group: a checker that has never been
# seen to fail is not evidence of anything when it passes.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
lint="$here/readability-lint.py"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
fails=0

check() {
	local name="$1" want="$2" got="$3"
	if [[ "$want" == "$got" ]]; then
		echo "ok   $name"
	else
		echo "FAIL $name: want '$want', got '$got'"
		fails=$((fails + 1))
	fi
}

run() { # run <file> [args...] -> prints "<exit> <fail-count>"
	local f="$1"
	shift
	local out rc
	out="$("$lint" "$@" "$f" 2>&1)" && rc=0 || rc=$?
	echo "$rc $(grep -c 'FAIL ' <<<"$out" || true)"
}

# --- the rule: shorthand the document invented and never explained ---------
cat >"$tmp/never.md" <<'MD'
The RPO target is four hours.

Every service inherits that RPO from the platform tier.
MD
check "never expanded fails" "1 1" "$(run "$tmp/never.md")"

cat >"$tmp/early.md" <<'MD'
Recovery Point Objective (RPO) is four hours.

Every service inherits that RPO.
MD
check "expanded at first use passes" "0 0" "$(run "$tmp/early.md")"

cat >"$tmp/late.md" <<'MD'
The RPO target is four hours.

Every service inherits that RPO, our Recovery Point Objective (RPO).
MD
check "expanded late warns but does not fail" "0 0" "$(run "$tmp/late.md")"
check "expanded late says WARN" "1" \
	"$("$lint" "$tmp/late.md" | grep -c 'WARN ' || true)"

cat >"$tmp/reversed.md" <<'MD'
RPO (Recovery Point Objective) is four hours.

Every service inherits that RPO.
MD
check "ABC (Full Name) counts as expansion" "0 0" "$(run "$tmp/reversed.md")"

cat >"$tmp/glossed.md" <<'MD'
RPO stands for the target we restore to.

Every service inherits that RPO.
MD
check "stands-for gloss counts as expansion" "0 0" "$(run "$tmp/glossed.md")"

# --- what the tool agrees not to flag -------------------------------------
cat >"$tmp/once.md" <<'MD'
This is REALLY the only time that word is shouted.
MD
check "a single all-caps use is emphasis, not coinage" "0 0" "$(run "$tmp/once.md")"

cat >"$tmp/assumed.md" <<'MD'
The API returns JSON over HTTPS.

Every API call is logged, and the JSON is archived.
MD
check "assumed-known terms are not findings" "0 0" "$(run "$tmp/assumed.md")"

cat >"$tmp/ids.md" <<'MD'
Q644 blocks the release.

Q644 is ranked above Q12, and Q12 is stale.
MD
check "identifiers carrying digits are not initialisms" "0 0" "$(run "$tmp/ids.md")"

cat >"$tmp/code.md" <<'MD'
Run `RPO --check` twice.

The `RPO` flag is idempotent.
MD
check "code spans are not prose" "0 0" "$(run "$tmp/code.md")"

check "--known silences a finding" "0 0" "$(run "$tmp/never.md" --known RPO)"

printf 'RPO  # recovery point objective\n' >"$tmp/known.txt"
check "--known-file silences a finding" "0 0" \
	"$(run "$tmp/never.md" --known-file "$tmp/known.txt")"

# --- the checker can fail ---------------------------------------------------
# Two documents differing only in whether the expansion is present must land on
# different exit statuses. If they do not, every pass above is meaningless.
a="$(run "$tmp/never.md")"
b="$(run "$tmp/early.md")"
check "the checker discriminates" "different" \
	"$([[ "$a" != "$b" ]] && echo different || echo identical)"

if ((fails)); then
	echo "test-readability-lint: $fails check(s) failed"
	exit 1
fi
echo "test-readability-lint: all checks passed"
