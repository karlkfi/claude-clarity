#!/usr/bin/env bash
#
# test-install.sh — behavioral tests for scripts/install.sh.
#
# Every case passes both --skills-target and --styles-target, so a bug in the
# argument parsing cannot reach the real ~/.claude. The sources are this repo's
# own skills and styles, because install.sh has no --src: the assertions name
# clarity.md and one skill, so adding a skill or a style does not change what
# they check.
#
# Self-contained, takes no arguments. Run from anywhere.

set -euo pipefail

cd "$(dirname "$0")/.."
script="$PWD/scripts/install.sh"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

fail=0
pass=0

# check NAME EXPECTED_STATUS — execute the rest as a command, compare exit
# status. Output is captured into $out for the caller to assert against.
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

# assert NAME — the rest is a test expression executed as a command.
assert() {
    local name="$1"; shift
    if "$@"; then
        pass=$((pass + 1))
    else
        printf 'FAIL %s\n' "$name" >&2
        fail=1
    fi
}

# Spliced into every invocation rather than wrapped in a helper, so shellcheck
# can see each call site.
targets=(--skills-target "$tmp/skills" --styles-target "$tmp/styles")

# --- a dry run writes nothing, including the target directories -------------
check 'dry run succeeds' 0 "$script" "${targets[@]}" --dry-run
expect 'dry run says so' 'dry run'
assert 'dry run creates no styles target' [ ! -e "$tmp/styles" ]
assert 'dry run creates no skills target' [ ! -e "$tmp/skills" ]

# --- a plain invocation installs both halves --------------------------------
check 'install succeeds' 0 "$script" "${targets[@]}"
expect 'reports the skills section' '^== skills'
expect 'reports the styles section' '^== output styles'

# install-skills.sh tells a direct caller that the styles are a separate run.
# Here they are the next thing this script does.
if printf '%s' "$out" | grep -q 'skills only'; then
    printf 'FAIL the skills-only pointer is suppressed under install.sh\n' >&2
    fail=1
else
    pass=$((pass + 1))
fi
assert 'clarity.md is linked' [ -L "$tmp/styles/clarity.md" ]
assert 'the link resolves' [ -f "$tmp/styles/clarity.md" ]
assert 'skills were installed too' [ -L "$tmp/skills/verify-claims" ]

# The styles README documents the styles; linked, Claude Code would offer it in
# the picker as a style named README.
assert 'the styles README is not linked' [ ! -e "$tmp/styles/README.md" ]

# Linking a style makes it available, not active, and nothing else would say so.
expect 'names the settings key' 'outputStyle'
assert 'no settings file is written' [ ! -e "$tmp/settings.json" ]

# --- a second invocation is a no-op -----------------------------------------
check 'reinstall succeeds' 0 "$script" "${targets[@]}"
expect 'reports the style as already installed' 'ok +clarity\.md'

# --- a real file in the way is a conflict, not an overwrite -----------------
rm "$tmp/styles/clarity.md"
echo 'mine' > "$tmp/styles/clarity.md"
check 'a real file conflicts' 1 "$script" "${targets[@]}"
expect 'names the conflict' 'CONFLICT clarity\.md'
assert 'the real file survives' grep -q mine "$tmp/styles/clarity.md"

check '--force replaces it' 0 "$script" "${targets[@]}" --force
assert 'the link is back' [ -L "$tmp/styles/clarity.md" ]

# --- a link to someone else's real file is a conflict -----------------------
# The target has to exist: a link into nothing is the dangling case below, and
# writing this one without the file tested that instead under the wrong name.
rm "$tmp/styles/clarity.md"
echo 'theirs' > "$tmp/elsewhere.md"
ln -s "$tmp/elsewhere.md" "$tmp/styles/clarity.md"
check 'a foreign link conflicts' 1 "$script" "${targets[@]}"
expect 'names the foreign link' 'CONFLICT clarity\.md ->'

# --- a dangling link is repaired without --force ----------------------------
# The case this hit for real: the style had been linked into a repo that was
# later renamed, so the link survived and its target did not.
rm -f "$tmp/styles/clarity.md"
ln -s "$tmp/gone/clarity.md" "$tmp/styles/clarity.md"
check 'a broken link is repaired' 0 "$script" "${targets[@]}"
expect 'says the link was broken' 'relink +clarity\.md \(was a broken link to'
expect 'names the old target, not the new one' 'broken link to .*/gone/clarity\.md'
assert 'the link now resolves' [ -f "$tmp/styles/clarity.md" ]

# --- argument handling ------------------------------------------------------
check 'an unknown option fails' 1 "$script" "${targets[@]}" --nope
expect 'names the option' 'unknown option'

# Partial selection belongs to install-skills.sh. Accepting a name here would
# be a second spelling of it that silently installs the styles as well.
check 'a skill name is refused' 1 "$script" "${targets[@]}" verify-claims
expect 'points at the skills half' 'install-skills\.sh verify-claims'

check '--help succeeds' 0 "$script" --help
expect '--help shows the usage' 'scripts/install\.sh'

printf '\ntest-install: %d passed' "$pass"
[ "$fail" -eq 0 ] && { printf ', 0 failed\n'; exit 0; }
printf ', failures above\n' >&2
exit 1
