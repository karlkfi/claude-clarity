#!/usr/bin/env bash
#
# test-install-skills.sh — behavioral tests for scripts/install-skills.sh.
#
# Every case passes --target, so a bug in the argument parsing cannot reach the
# real ~/.claude/skills. The fixtures are a throwaway source tree rather than
# this repo's own skills, so adding a skill does not change what the tests
# assert.
#
# Self-contained, takes no arguments. Run from anywhere.

set -euo pipefail

cd "$(dirname "$0")/.."
# Absolute: one case runs the script from a different working directory to
# check that a relative --src is resolved before it is written into a symlink.
script="$PWD/scripts/install-skills.sh"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

fail=0
pass=0

# check NAME EXPECTED_STATUS — run the rest as a command, compare exit status.
# Output is captured into $out for the caller to assert against.
out=''
check() {
    local name="$1" want="$2"; shift 2
    local got=0
    out="$("$@" 2>&1)" || got=$?
    if [[ "$got" == "$want" ]]; then
        pass=$((pass + 1))
    else
        printf 'FAIL %s: exit %s, want %s\n' "$name" "$got" "$want" >&2
        printf '%s\n' "$out" | sed 's/^/     /' >&2
        fail=1
    fi
}

# expect NAME PATTERN — assert the last captured output matches PATTERN.
expect() {
    local name="$1" pat="$2"
    if printf '%s' "$out" | grep -qE "$pat"; then
        pass=$((pass + 1))
    else
        printf 'FAIL %s: output does not match /%s/\n' "$name" "$pat" >&2
        printf '%s\n' "$out" | sed 's/^/     /' >&2
        fail=1
    fi
}

# reject NAME PATTERN — assert the last captured output does NOT match.
reject() {
    local name="$1" pat="$2"
    if printf '%s' "$out" | grep -qE "$pat"; then
        printf 'FAIL %s: output unexpectedly matches /%s/\n' "$name" "$pat" >&2
        printf '%s\n' "$out" | sed 's/^/     /' >&2
        fail=1
    else
        pass=$((pass + 1))
    fi
}

# assert NAME — the rest is a test expression run as a command.
assert() {
    local name="$1"; shift
    if "$@"; then
        pass=$((pass + 1))
    else
        printf 'FAIL %s\n' "$name" >&2
        fail=1
    fi
}

# alpha and beta are skills; plain/ stands in for scripts/ and docs/, which sit
# beside the skills at the repo root and must not be linked.
mkdir -p "$tmp/src/alpha" "$tmp/src/beta" "$tmp/src/plain"
touch "$tmp/src/alpha/SKILL.md" "$tmp/src/beta/SKILL.md" "$tmp/src/plain/README.md"

# --- Option handling --------------------------------------------------------
check 'help exits 0' 0 bash "$script" --help
expect 'help prints the header' 'install-skills\.sh'

check 'unknown option exits 1' 1 bash "$script" --nonsense
check 'missing source exits 1' 1 bash "$script" --src "$tmp/absent" --target "$tmp/t0"

# --- Naming a subset --------------------------------------------------------
check 'one skill exits 0' 0 bash "$script" --src "$tmp/src" --target "$tmp/one" alpha
assert 'alpha installed' [ -f "$tmp/one/alpha/SKILL.md" ]
assert 'beta left out' [ ! -e "$tmp/one/beta" ]

check 'a misspelled name exits 1' 1 bash "$script" --src "$tmp/src" --target "$tmp/typo" alfa
expect 'says which name' "no skill named 'alfa'"

# --- Dry run writes nothing -------------------------------------------------
check 'dry run exits 0' 0 bash "$script" --src "$tmp/src" --target "$tmp/dry" --dry-run
expect 'dry run says so' 'nothing written'
assert 'dry run creates no target' [ ! -e "$tmp/dry" ]
reject 'dry run does not tell you to restart' 'Restart Claude Code'

# --- A fresh install --------------------------------------------------------
check 'install exits 0' 0 bash "$script" --src "$tmp/src" --target "$tmp/dest"
expect 'links alpha' 'link +alpha'
expect 'links beta' 'link +beta'
expect 'counts two' 'linked 2,'
expect 'a real install does say to restart' 'Restart Claude Code'
assert 'alpha resolves' [ -f "$tmp/dest/alpha/SKILL.md" ]
# The check that should fail if the SKILL.md filter is dropped.
assert 'a directory without SKILL.md is not linked' [ ! -e "$tmp/dest/plain" ]

# --- Re-running is a no-op --------------------------------------------------
check 'reinstall exits 0' 0 bash "$script" --src "$tmp/src" --target "$tmp/dest"
expect 'reports already installed' 'ok +alpha'
expect 'links nothing new' 'linked 0,'

# --- A real directory at the destination is not clobbered -------------------
# `ln -sfn` exits 0 here and drops the link inside the directory; refusing is
# the reason this script exists.
mkdir -p "$tmp/hand/alpha"
echo 'hand-written' > "$tmp/hand/alpha/SKILL.md"
check 'conflict exits 1' 1 bash "$script" --src "$tmp/src" --target "$tmp/hand"
expect 'names the conflict' 'CONFLICT alpha'
assert 'the hand-written skill survives' [ ! -L "$tmp/hand/alpha" ]
assert 'nothing was nested inside it' [ ! -e "$tmp/hand/alpha/alpha" ]

check 'force exits 0' 0 bash "$script" --src "$tmp/src" --target "$tmp/hand" --force
expect 'reports the replacement' 'replace +alpha'
assert 'alpha is now a link' [ -L "$tmp/hand/alpha" ]

# --- A link pointing somewhere else is a conflict too -----------------------
mkdir -p "$tmp/other/alpha" "$tmp/elsewhere"
touch "$tmp/other/alpha/SKILL.md"
ln -s "$tmp/other/alpha" "$tmp/elsewhere/alpha"
check 'foreign link conflicts' 1 bash "$script" --src "$tmp/src" --target "$tmp/elsewhere"
expect 'names the foreign target' 'CONFLICT alpha ->'

# --- A link whose target is gone is repaired, not refused -------------------
# Observed on a real machine: the repo a skill was linked into got renamed, so
# the link survived and what it pointed at did not. --force guards somebody's
# only copy, and a dangling link is not one — refusing here spends a decision
# on a skill that cannot be read either way.
mkdir -p "$tmp/dangling"
ln -s "$tmp/vanished/alpha" "$tmp/dangling/alpha"
check 'a broken link is repaired' 0 bash "$script" --src "$tmp/src" --target "$tmp/dangling"
expect 'says the link was broken' 'relink +alpha \(was a broken link to'
expect 'names the old target' 'broken link to .*/vanished/alpha'
assert 'the link now resolves' [ -f "$tmp/dangling/alpha/SKILL.md" ]

# --- The machine-local ignore file -----------------------------------------
# gamma stands in for a skill this machine does not want linked.
# The default every-skill run must not link it, because that run is how the
# ignore file came to exist — a bare invocation silently reversed a documented
# decision. The list is machine state, so it lives beside the install target
# rather than in the source tree, and a clone does not inherit it.
mkdir -p "$tmp/src/gamma" "$tmp/marked"
touch "$tmp/src/gamma/SKILL.md"
printf '# this machine leaves these out\n\ngamma  # because the absence is the measurement\n' \
    > "$tmp/marked/.install-skills-ignore"

check 'default run exits 0 with an ignored skill listed' 0 \
    bash "$script" --src "$tmp/src" --target "$tmp/marked"
assert 'the ignored skill is not linked' [ ! -e "$tmp/marked/gamma" ]
assert 'the unlisted ones still are' [ -f "$tmp/marked/alpha/SKILL.md" ]
expect 'the skip is reported by name' 'skip +gamma'
expect 'with the reason from the line' 'because the absence is the measurement'
expect 'the summary counts it' 'skipped 1'

# Naming it is an explicit decision, so it installs — the guard is against the
# bare run, not against a maintainer who typed the name.
check 'naming an ignored skill exits 0' 0 \
    bash "$script" --src "$tmp/src" --target "$tmp/marked" gamma
assert 'naming it installs it' [ -f "$tmp/marked/gamma/SKILL.md" ]
expect 'and says why it was listed' 'in the ignore file and you named it'

# The ignore file is what causes the skip. Without this case the two above pass
# over a skill that was never going to be linked for some unrelated reason.
check 'no ignore file exits 0' 0 bash "$script" --src "$tmp/src" --target "$tmp/unlisted"
assert 'with no ignore file it is linked' [ -f "$tmp/unlisted/gamma/SKILL.md" ]
reject 'and nothing is skipped' 'skipped 1'

# A comment line naming a skill must not skip it, or every documented example
# in the file becomes an accidental rule.
mkdir -p "$tmp/commented"
printf '# gamma is discussed here, not listed\n#gamma\n' > "$tmp/commented/.install-skills-ignore"
check 'a commented name exits 0' 0 bash "$script" --src "$tmp/src" --target "$tmp/commented"
assert 'a commented name does not skip' [ -f "$tmp/commented/gamma/SKILL.md" ]

# --ignore-file reads the list from elsewhere, and wins over the target's own.
check '--ignore-file exits 0' 0 bash "$script" --src "$tmp/src" --target "$tmp/elsewhere-ig" \
    --ignore-file "$tmp/marked/.install-skills-ignore"
assert '--ignore-file is honoured' [ ! -e "$tmp/elsewhere-ig/gamma" ]

rm -r "$tmp/src/gamma"

# --- A relative --src still yields a resolvable link ------------------------
# The symlink stores its target verbatim, so a relative source that is not
# resolved first dangles when read from the target directory.
#
# `check` runs its command inside a command substitution, so this cd is
# confined to that subshell and the later cases still start from the repo root.
run_from() { cd "$1" && bash "$2" --src src --target "$3"; }
check 'relative src exits 0' 0 run_from "$tmp" "$script" "$tmp/rel"
assert 'the relative-src link resolves' [ -f "$tmp/rel/alpha/SKILL.md" ]

# --- The default source prefers skills/ over the repo root -----------------
# This repo keeps its skills under skills/, which is the layout a Claude Code
# plugin needs, and the script has to find them with no --src. Both arms are
# asserted: a root holding skills/ reads that, and a root without one still
# reads itself, so a clone laid out the old way keeps working. Without the
# second arm the preference could be an unconditional rewrite and pass.
mkdir -p "$tmp/plugin/scripts" "$tmp/plugin/skills/nested" "$tmp/plugin/decoy"
touch "$tmp/plugin/skills/nested/SKILL.md" "$tmp/plugin/decoy/SKILL.md"
cp "$script" "$tmp/plugin/scripts/install-skills.sh"
check 'a skills/ dir is the default source' 0 \
    bash "$tmp/plugin/scripts/install-skills.sh" --target "$tmp/plug"
assert 'the nested skill is linked' [ -f "$tmp/plug/nested/SKILL.md" ]
assert 'a skill beside skills/ is not' [ ! -e "$tmp/plug/decoy" ]

mkdir -p "$tmp/flat/scripts" "$tmp/flat/solo"
touch "$tmp/flat/solo/SKILL.md"
cp "$script" "$tmp/flat/scripts/install-skills.sh"
check 'a root with no skills/ is still the default source' 0 \
    bash "$tmp/flat/scripts/install-skills.sh" --target "$tmp/flatdest"
assert 'the root-level skill is linked' [ -f "$tmp/flatdest/solo/SKILL.md" ]

if (( fail )); then
    printf 'test-install-skills: FAILED\n' >&2
    exit 1
fi
printf 'test-install-skills: %d assertion(s) OK\n' "$pass"
