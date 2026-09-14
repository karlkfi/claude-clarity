#!/usr/bin/env bash
#
# test-validate-skills.sh — check that validate-skills.py rejects what it
# claims to reject.
#
# The description length check is the fiddly one: the value has to be folded
# the way YAML folds it and then counted in characters rather than bytes. A
# description of em dashes counted as bytes reads over the limit when it is
# not, which is the shape this repo's own descriptions have. Each case below
# builds a throwaway skill tree and asserts the validator's verdict on it.

set -eu

here="$(cd "$(dirname "$0")" && pwd)"
validator="$here/validate-skills.py"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

fail=0

# Build a skill tree containing one SKILL.md and run the validator in it.
# Prints the validator's output; returns its exit status.
run_case() {
    local dir="$tmp/$1" name="$1"
    rm -rf "$dir"
    mkdir -p "$dir/$name"
    cat >"$dir/$name/SKILL.md"
    (cd "$dir" && "$validator" 2>&1) || return 1
}

expect_ok() {
    local name="$1" out
    if out="$(run_case "$name")"; then
        printf 'ok: %s accepted\n' "$name"
    else
        printf 'FAIL: %s rejected: %s\n' "$name" "$out" >&2
        fail=1
    fi
}

expect_reject() {
    local name="$1" pattern="$2" out
    if out="$(run_case "$name")"; then
        printf 'FAIL: %s accepted, expected rejection\n' "$name" >&2
        fail=1
    elif [[ "$out" != *"$pattern"* ]]; then
        printf 'FAIL: %s rejected for the wrong reason: %s\n' "$name" "$out" >&2
        fail=1
    else
        printf 'ok: %s rejected (%s)\n' "$name" "$pattern"
    fi
}

# 1024 ASCII characters on one line: at the limit, accepted.
at_limit="$(head -c 1024 < /dev/zero | tr '\0' 'a')"
expect_ok at-limit <<EOF
---
name: at-limit
description: $at_limit
---
EOF

expect_reject over-limit '1025 characters' <<EOF
---
name: over-limit
description: ${at_limit}a
---
EOF

# 512 em dashes are 1536 bytes but 512 characters — a byte-based count would
# reject this, and this is the shape the repo's own descriptions have.
em="$(printf '%.0s—' $(seq 1 512))"
expect_ok em-dashes <<EOF
---
name: em-dashes
description: $em
---
EOF

# A block scalar folds with one space per line join, so 200 lines of 4 "a"s
# measure 200*4 + 199 = 999 characters, under the limit; 210 lines measure
# 210*4 + 209 = 1049, over it.
block_lines() {
    local n="$1" i
    for ((i = 0; i < n; i++)); do printf '  aaaa\n'; done
}

expect_ok block-under <<EOF
---
name: block-under
description: >
$(block_lines 200)
---
EOF

expect_reject block-over '1049 characters' <<EOF
---
name: block-over
description: >
$(block_lines 210)
---
EOF

# The pre-existing checks still work.
expect_reject name-mismatch 'does not match directory' <<'EOF'
---
name: wrong
description: A short description.
---
EOF

expect_reject empty-block 'block scalar is empty' <<'EOF'
---
name: empty-block
description: >
---
EOF

# Any unindented line ends a block scalar, `name:` included, so the indented
# line below belongs to nothing and the description is still empty. The two awk
# programs this replaced disagreed here — one ended the scalar, the other did
# not — and between them an empty description passed.
expect_reject block-then-key 'block scalar is empty' <<'EOF'
---
description: >
name: block-then-key
  stray
---
EOF

# --- the colon that stops a YAML parser -------------------------------------
#
# A plain inline scalar carrying ": ", or ending in ":", is rejected outright by
# YAML — the block parses nowhere, so the skill is one loader change away from
# not loading at all. Three descriptions here were written that way for months
# with the gate green, which is what the first case below reproduces.
#
# The accept cases are the half that keeps the check honest. A tightening that
# also rejected a quoted colon, a block scalar, or a ratio would redden every
# skill in the repo, and a reject-only suite cannot tell that apart from a check
# that works.

expect_reject colon-space 'unquoted inline value with a colon' <<'EOF'
---
name: colon-space
description: A description carrying a fatal construct: a colon and a space.
---
EOF

expect_reject colon-eol 'unquoted inline value with a colon' <<'EOF'
---
name: colon-eol
description: A description ending in a colon:
---
EOF

# Not description-only: a colon anywhere in the block stops the same parse, and
# a check wired to the one key the scan already reads would miss it.
expect_reject colon-other-key 'unquoted inline value with a colon' <<'EOF'
---
name: colon-other-key
description: A well-formed description.
target: ../scripts/thing.py and then: a colon
---
EOF

expect_ok colon-double-quoted <<'EOF'
---
name: colon-double-quoted
description: "A quoted value: the colon is ordinary text."
---
EOF

expect_ok colon-single-quoted <<'EOF'
---
name: colon-single-quoted
description: 'A quoted value: the colon is ordinary text.'
---
EOF

expect_ok colon-block-scalar <<'EOF'
---
name: colon-block-scalar
description: >-
  A block scalar: the colon is ordinary text, which is why this is the repair
  the rejection message names.
---
EOF

# YAML only objects to a colon followed by a space or a line end, so a ratio and
# a bare URL scheme are legal and must stay legal. Without this the narrow rule
# and a blanket ban on ":" are indistinguishable.
expect_ok colon-no-space <<'EOF'
---
name: colon-no-space
description: A ratio of 3:1 and a scheme like https://example.com parse fine.
---
EOF

# The dated-claim check warns without failing, so expect_ok cannot see it and
# expect_reject would report the wrong verdict. These two assert exit 0 plus the
# presence or absence of the warning, which is the only thing that distinguishes
# a check that fired from one that silently matched nothing.
expect_warns() {
    local name="$1" pattern="$2" out
    if ! out="$(run_case "$name")"; then
        printf 'FAIL: %s rejected, expected exit 0 with a warning: %s\n' "$name" "$out" >&2
        fail=1
    elif [[ "$out" != *"$pattern"* ]]; then
        printf 'FAIL: %s did not warn (%s): %s\n' "$name" "$pattern" "$out" >&2
        fail=1
    else
        printf 'ok: %s warned (%s)\n' "$name" "$pattern"
    fi
}

expect_quiet() {
    local name="$1" pattern="$2" out
    if ! out="$(run_case "$name")"; then
        printf 'FAIL: %s rejected: %s\n' "$name" "$out" >&2
        fail=1
    elif [[ "$out" == *"$pattern"* ]]; then
        printf 'FAIL: %s warned unexpectedly: %s\n' "$name" "$out" >&2
        fail=1
    else
        printf 'ok: %s did not warn\n' "$name"
    fi
}

# The cap is a cliff: nothing reports how close a description is until it goes
# over. A description inside the warning band is named with its measured count,
# and one a single character outside it is not. The pair is what separates a
# band that fired from one matching every skill in the repo — and the count is
# the point of the warning, since "close to the cap" leaves the reader deriving
# the number by hand.
band_edge="$(head -c 1004 < /dev/zero | tr '\0' 'a')"
expect_warns near-cap '1004 characters, 20 left' <<EOF
---
name: near-cap
description: $band_edge
---
EOF

expect_quiet outside-band 'characters of the 1024-character cap' <<EOF
---
name: outside-band
description: ${band_edge%a}
---
EOF

expect_warns dated-body 'dated claim' <<'EOF'
---
name: dated-body
description: A skill whose body carries a date.
---

Measured 2026-08-17 on one workstation, the thing was true.
EOF

# The same date under Sources is where provenance belongs, so it must not warn.
# Without this case the check could match every skill and still look correct.
expect_quiet dated-sources 'dated claim' <<'EOF'
---
name: dated-sources
description: A skill dating only its Sources section.
---

The rule, with no date attached.

## Sources

Derived from an audit on 2026-08-17.
EOF

# The Sources block the dated-claim check deliberately skips is still body text
# charged on every invocation, so its size is warned about separately. Both
# thresholds must trip: large in absolute terms and disproportionate.
expect_warns bulky-sources 'Sources block' <<'EOF'
---
name: bulky-sources
description: A skill whose Sources block dominates its body.
---

The rule, stated briefly.

## Sources

xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
EOF

# A Sources block over the byte floor but a small fraction of a large body is
# the shape a large skill body takes and must stay quiet. Without this the check
# could key on size alone and still pass the case above.
expect_quiet proportionate-sources 'Sources block' <<'EOF'
---
name: proportionate-sources
description: A skill with a large body and a modest Sources block.
---

The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. The rule, stated at length. 

## Sources

xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
EOF

expect_quiet undated 'dated claim' <<'EOF'
---
name: undated
description: A skill with no dates at all.
---

The rule, with no date attached.
EOF

# A body date still warns when a Sources section exists below it — the section
# ends the scan, it does not exempt the whole file.
expect_warns dated-both 'dated claim' <<'EOF'
---
name: dated-both
description: A skill dating both its body and its Sources.
---

Measured 2026-08-17, the thing was true.

## Sources

Derived from an audit on 2026-08-16.
EOF

# An untracked SKILL.md is skipped by the git-ls-files discovery, so a run over
# a brand-new skill validates nothing and still exits 0. The warning has to name
# it. Needs a real repo: run_case above works in a bare directory, where the
# validator takes the find branch and this path is never reached.
untracked_case() {
    local dir="$tmp/untracked"
    rm -rf "$dir"
    mkdir -p "$dir/tracked" "$dir/newskill"
    printf -- '---\nname: tracked\ndescription: A tracked skill.\n---\n' >"$dir/tracked/SKILL.md"
    # Deliberately invalid, to prove it was skipped rather than quietly passed.
    printf 'no frontmatter at all\n' >"$dir/newskill/SKILL.md"
    (
        cd "$dir"
        git init -q .
        git add tracked/SKILL.md
        "$validator" 2>&1
    )
}

# expect_ok and expect_reject above are wired to run_case's heredoc; the mode
# cases build a tree of their own, so they assert through these two instead.
expect_case_ok() {
    local label="$1" out
    shift
    if out="$("$@")"; then
        printf 'ok: %s accepted\n' "$label"
    else
        printf 'FAIL: %s rejected: %s\n' "$label" "$out" >&2
        fail=1
    fi
}

expect_case_reject() {
    local label="$1" pattern="$2" out
    shift 2
    if out="$("$@")"; then
        printf 'FAIL: %s accepted, expected rejection\n' "$label" >&2
        fail=1
    elif [[ "$out" != *"$pattern"* ]]; then
        printf 'FAIL: %s rejected for the wrong reason: %s\n' "$label" "$out" >&2
        fail=1
    else
        printf 'ok: %s rejected (%s)\n' "$label" "$pattern"
    fi
}

# The executable-mode check has two branches, printing different messages: run
# outside a git repository it reads st_mode off the filesystem, and inside one
# it reads the index, which is the mode other people clone. The two can
# disagree, so each git case below sets the on-disk mode to the opposite of the
# index mode — a verdict there is then evidence about the index alone.
#
# Both branches are exercised at two shapes, because they once disagreed about
# one of them: `git ls-files '*/scripts/*.sh'` needs a character ahead of the
# `/`, so it reached a skill's scripts directory and never the repo's own,
# while the filesystem branch's `**/scripts/*.sh` matched both. A fixture built
# only under a skill passes either way, so the root-shaped cases are the ones
# that fail if the pathspec narrows again.
write_skill_with_script() {
    local dir="$1" script="$2"
    rm -rf "$dir"
    mkdir -p "$dir/myskill" "$dir/${script%/*}"
    printf -- '---\nname: myskill\ndescription: A skill.\n---\n' >"$dir/myskill/SKILL.md"
    printf '#!/usr/bin/env bash\ntrue\n' >"$dir/$script"
}

# One script at the given mode, in a bare directory, where the validator falls
# back to reading the filesystem.
disk_mode_case() {
    local dir="$tmp/diskmode" script="$1"
    write_skill_with_script "$dir" "$script"
    chmod "$2" "$dir/$script"
    (cd "$dir" && "$validator" 2>&1) || return 1
}

# The same in a real repo, with the index mode forced and the on-disk mode set
# to the opposite of it.
index_mode_case() {
    local dir="$tmp/indexmode" script="$1" index="$2" disk="$3"
    write_skill_with_script "$dir" "$script"
    (
        cd "$dir"
        git init -q .
        git add myskill/SKILL.md "$script"
        git update-index "--chmod=$index" "$script"
        chmod "$disk" "$script"
        "$validator" 2>&1
    ) || return 1
}

for shape in myskill/scripts/tool.sh scripts/tool.sh; do
    expect_case_ok "executable $shape (on disk)" disk_mode_case "$shape" 755
    expect_case_reject "non-executable $shape (on disk)" \
        'not executable; fix with chmod +x' disk_mode_case "$shape" 644

    expect_case_ok "$shape 100755 in the index, 644 on disk" \
        index_mode_case "$shape" +x 644
    expect_case_reject "$shape 100644 in the index, 755 on disk" \
        'mode 100644, not executable' index_mode_case "$shape" -x 755
done

if out="$(untracked_case)"; then
    if [[ "$out" != *'newskill/SKILL.md'* ]]; then
        printf 'FAIL: untracked SKILL.md not named in the output: %s\n' "$out" >&2
        fail=1
    elif [[ "$out" != *'1 skill(s)'* ]]; then
        printf 'FAIL: untracked skill appears to have been validated: %s\n' "$out" >&2
        fail=1
    else
        printf 'ok: untracked skill warned about and skipped\n'
    fi
else
    printf 'FAIL: untracked SKILL.md turned the run red; it should warn only: %s\n' "$out" >&2
    fail=1
fi

# --- --report: the enforcer's own count, asked for rather than refolded ------
#
# The failure this replaces is two sessions independently folding the block
# scalar by hand and both landing exactly two characters over the enforcer on 12
# of 21 skills. So what has to be asserted is agreement with the enforcer
# — never with a number written into this file, which would be a third fold and
# would pass the day the enforcer changed.
#
# Both numbers are extracted from output, and two failed extractions compare
# equal, so each is checked for being a number first. Without that, a message
# this test no longer matches reports the same green as agreement.

numeric() {  # numeric LABEL VALUE — the extraction landed, so the case can fail
    if [[ "$2" =~ ^[0-9]+$ ]]; then
        return 0
    fi
    printf 'FAIL: %s came back as %s, not a count; the comparison below proves nothing\n' \
        "$1" "${2:-<empty>}" >&2
    fail=1
    return 1
}

# A tree carrying one description inside the warning band, run both ways. The
# band is where the gate already prints a count, which makes it the one place
# the two paths can be held against each other directly.
agree_dir="$tmp/agree"
rm -rf "$agree_dir"
mkdir -p "$agree_dir/near-cap"
cat >"$agree_dir/near-cap/SKILL.md" <<EOF
---
name: near-cap
description: $band_edge
---
EOF

# Run the validator inside a throwaway tree and capture its output whatever it
# exits with. The `|| true` sits outside the `&&` chain deliberately: written as
# `cd X && validator || true` it is SC2015, which the runner's shellcheck flags
# and 0.11.0 does not.
validator_in() {
    local dir="$1"
    shift
    (
        cd "$dir" || exit 1
        "$validator" "$@" 2>&1
    ) || true
}

gate_out="$(validator_in "$agree_dir")"
report_out="$(validator_in "$agree_dir" --report)"
gate_n="$(printf '%s\n' "$gate_out" | awk '$1 ~ /near-cap/ { print $2 }')"
report_n="$(printf '%s\n' "$report_out" | awk '$1 ~ /near-cap/ { print $2 }')"

if numeric 'the warning band count' "$gate_n" \
    && numeric 'the --report count' "$report_n"; then
    if [[ "$gate_n" == "$report_n" ]]; then
        printf 'ok: --report and the warning band agree (%s characters)\n' "$gate_n"
    else
        printf 'FAIL: --report says %s, the warning band says %s\n' \
            "$report_n" "$gate_n" >&2
        fail=1
    fi
fi

# The same agreement where the enforcer speaks through a rejection instead of a
# warning. --report is a query, so it reports the overage and stays at exit 0;
# the count it prints still has to be the one the gate rejected on.
over_dir="$tmp/over-report"
rm -rf "$over_dir"
mkdir -p "$over_dir/over-limit"
cat >"$over_dir/over-limit/SKILL.md" <<EOF
---
name: over-limit
description: ${at_limit}a
---
EOF

over_gate="$(validator_in "$over_dir")"
if over_report="$(cd "$over_dir" && "$validator" --report 2>&1)"; then
    printf 'ok: --report does not gate an over-cap description\n'
else
    printf 'FAIL: --report exited non-zero on an over-cap description: %s\n' \
        "$over_report" >&2
    fail=1
fi
over_gate_n="$(printf '%s\n' "$over_gate" | sed -n 's/.*is \([0-9]*\) characters.*/\1/p')"
over_report_n="$(printf '%s\n' "$over_report" | awk '$1 ~ /over-limit/ { print $2 }')"

if numeric 'the rejection count' "$over_gate_n" \
    && numeric 'the --report count over the cap' "$over_report_n"; then
    if [[ "$over_gate_n" == "$over_report_n" ]]; then
        printf 'ok: --report and the rejection agree (%s characters)\n' "$over_gate_n"
    else
        printf 'FAIL: --report says %s, the rejection says %s\n' \
            "$over_report_n" "$over_gate_n" >&2
        fail=1
    fi
fi

if [[ "$over_report" == *"over the cap"* ]]; then
    printf 'ok: --report names the overage\n'
else
    printf 'FAIL: --report did not name the overage: %s\n' "$over_report" >&2
    fail=1
fi

# Naming a skill is the case that matters for a session drafting one, since a
# new SKILL.md is untracked and so invisible to the gate's own discovery. Both
# spellings resolve, and reporting one must not report the other.
named_dir="$tmp/named"
rm -rf "$named_dir"
mkdir -p "$named_dir/alpha" "$named_dir/beta"
printf -- '---\nname: alpha\ndescription: The alpha description.\n---\n' \
    >"$named_dir/alpha/SKILL.md"
printf -- '---\nname: beta\ndescription: A longer beta description than alpha carries.\n---\n' \
    >"$named_dir/beta/SKILL.md"

for spelling in alpha alpha/SKILL.md; do
    out="$(cd "$named_dir" && "$validator" --report "$spelling" 2>&1)"
    if [[ "$out" == *alpha/SKILL.md* && "$out" != *beta* ]]; then
        printf 'ok: --report %s reports that skill alone\n' "$spelling"
    else
        printf 'FAIL: --report %s reported the wrong set: %s\n' "$spelling" "$out" >&2
        fail=1
    fi
done

# The same lookup one directory down, which is where this repo's skills sit. The
# case above puts them at the tree root, so `--report alpha` resolves there as a
# plain relative path and passes whether or not a name lookup exists at all —
# it could not fail on a resolver that only tries the working directory. Run
# from the root of a tree whose skills are under skills/, a bare name has no
# path to be, so this is the case that discriminates.
nested_dir="$tmp/nested"
rm -rf "$nested_dir"
mkdir -p "$nested_dir/skills/alpha" "$nested_dir/skills/beta"
printf -- '---\nname: alpha\ndescription: The alpha description.\n---\n' \
    >"$nested_dir/skills/alpha/SKILL.md"
printf -- '---\nname: beta\ndescription: A longer beta description than alpha carries.\n---\n' \
    >"$nested_dir/skills/beta/SKILL.md"

rc=0
out="$(cd "$nested_dir" && "$validator" --report alpha 2>&1)" || rc=$?
if (( rc == 0 )) && [[ "$out" == *skills/alpha/SKILL.md* && "$out" != *beta* ]]; then
    printf 'ok: --report resolves a bare name from outside the skills directory\n'
else
    printf 'FAIL: --report alpha from a tree root exited %d: %s\n' "$rc" "$out" >&2
    fail=1
fi

# An untracked skill: the gate warns and skips it, so --report is the only way
# to measure the file a session is actually writing.
untracked_report="$tmp/untracked-report"
rm -rf "$untracked_report"
mkdir -p "$untracked_report/tracked" "$untracked_report/draft"
printf -- '---\nname: tracked\ndescription: A tracked skill.\n---\n' \
    >"$untracked_report/tracked/SKILL.md"
printf -- '---\nname: draft\ndescription: A draft nobody has staged.\n---\n' \
    >"$untracked_report/draft/SKILL.md"
out="$(cd "$untracked_report" && git init -q . && git add tracked/SKILL.md \
    && "$validator" --report draft 2>&1)"
draft_n="$(printf '%s\n' "$out" | awk '$1 ~ /draft/ { print $2 }')"
if numeric 'the count for an untracked draft' "$draft_n"; then
    printf 'ok: --report measures an untracked draft (%s characters)\n' "$draft_n"
fi

# A name that resolves to nothing is the one thing --report fails on, and it
# still reports whatever it could measure alongside.
rc=0
out="$(cd "$named_dir" && "$validator" --report alpha nosuchskill 2>&1)" || rc=$?
if (( rc == 1 )) && [[ "$out" == *nosuchskill* && "$out" == *alpha/SKILL.md* ]]; then
    printf 'ok: --report fails on an unresolvable name and reports the rest\n'
else
    printf 'FAIL: --report on a bad name exited %d: %s\n' "$rc" "$out" >&2
    fail=1
fi

# A skill with no description at all measures nothing, and saying "0" would be a
# number a session could budget against.
nodesc_dir="$tmp/nodesc"
rm -rf "$nodesc_dir"
mkdir -p "$nodesc_dir/bare"
printf -- '---\nname: bare\n---\n' >"$nodesc_dir/bare/SKILL.md"
out="$(cd "$nodesc_dir" && "$validator" --report 2>&1)"
if [[ "$out" == *"no description:"* ]]; then
    printf 'ok: --report says a missing description is missing\n'
else
    printf 'FAIL: --report on a description-less skill said: %s\n' "$out" >&2
    fail=1
fi

# A tracked SKILL.md deleted on disk but not staged stays in the git-ls-files
# discovery — correctly, since the index is what a plain commit ships. The read
# was unguarded, so that state raised FileNotFoundError and the gate exited on a
# traceback, which reads as the validator being broken rather than as the tree
# being in a state it correctly rejects.
absent_dir="$tmp/absent"
rm -rf "$absent_dir"
mkdir -p "$absent_dir/gone" "$absent_dir/kept"
printf -- '---\nname: gone\ndescription: A skill about to vanish.\n---\n' >"$absent_dir/gone/SKILL.md"
printf -- '---\nname: kept\ndescription: A skill that stays.\n---\n' >"$absent_dir/kept/SKILL.md"
git -C "$absent_dir" init -q
git -C "$absent_dir" add gone/SKILL.md kept/SKILL.md
rm "$absent_dir/gone/SKILL.md"

# A `git add` that silently did not take leaves the discovery finding nothing,
# which exits non-zero for an unrelated reason and reads exactly the same.
if git -C "$absent_dir" ls-files --error-unmatch gone/SKILL.md >/dev/null 2>&1 \
        && [[ ! -e "$absent_dir/gone/SKILL.md" ]]; then
    printf 'ok: the absent-skill fixture is tracked and gone\n'
else
    printf 'FAIL: the absent-skill fixture is not tracked-and-gone; the case below proves nothing\n' >&2
    fail=1
fi

rc=0
out="$(cd "$absent_dir" && "$validator" 2>&1)" || rc=$?
if (( rc != 0 )) && [[ "$out" != *Traceback* ]] \
        && [[ "$out" == *"gone/SKILL.md: No such file or directory"* ]]; then
    printf 'ok: an absent tracked SKILL.md is a named diagnostic, not a traceback\n'
else
    printf 'FAIL: an absent tracked SKILL.md exited %d without a diagnostic: %s\n' "$rc" "$out" >&2
    fail=1
fi

# --report walks the same discovery, so it takes the same guard.
rc=0
out="$(cd "$absent_dir" && "$validator" --report 2>&1)" || rc=$?
if (( rc != 0 )) && [[ "$out" != *Traceback* ]] \
        && [[ "$out" == *"gone/SKILL.md: No such file or directory"* ]]; then
    printf 'ok: --report names the absent skill instead of tracebacking\n'
else
    printf 'FAIL: --report over an absent tracked SKILL.md exited %d: %s\n' "$rc" "$out" >&2
    fail=1
fi

# The block scalar named in the colon rejection must not move the number the
# cap is enforced through: hand-folded counts taken from
# this script. The same text is measured inline and as a ">-" scalar, and the
# counts have to match.
#
# Quoting is the other repair a reader might reach for, and it does NOT measure
# the same — the quote characters are never stripped, so it reports two long.
# That is asserted here as the behaviour it is rather than left to be
# rediscovered. Whether to strip the quotes or to reject the form is open.
same_dir="$tmp/same-length"
rm -rf "$same_dir"
mkdir -p "$same_dir/inline" "$same_dir/blocked" "$same_dir/wrapped"
cat >"$same_dir/inline/SKILL.md" <<'EOF'
---
name: inline
description: A description with no colon in it and some words after it.
---
EOF
cat >"$same_dir/blocked/SKILL.md" <<'EOF'
---
name: blocked
description: >-
  A description with no colon in it
  and some words after it.
---
EOF
cat >"$same_dir/wrapped/SKILL.md" <<'EOF'
---
name: wrapped
description: "A description with no colon in it and some words after it."
---
EOF

same_out="$(validator_in "$same_dir" --report)"
count_of() { printf '%s\n' "$same_out" | awk -v s="$1" '$1 ~ s { print $2 }'; }
inline_n="$(count_of inline)"
blocked_n="$(count_of blocked)"
wrapped_n="$(count_of wrapped)"

if numeric 'the inline count' "$inline_n" && numeric 'the block-scalar count' "$blocked_n"; then
    if [[ "$inline_n" == "$blocked_n" ]]; then
        printf 'ok: a >- block scalar measures what the inline value did (%s characters)\n' "$inline_n"
    else
        printf 'FAIL: inline measures %s, the >- block scalar measures %s\n' \
            "$inline_n" "$blocked_n" >&2
        fail=1
    fi
fi

# Two more, for the two quote characters. Asserting the gap rather than
# equality is deliberate: this pins today's behaviour so that changing it
# fails here and has to be looked at, instead of passing silently.
if numeric 'the quoted count' "$wrapped_n" && numeric 'the inline count' "$inline_n"; then
    if (( wrapped_n == inline_n + 2 )); then
        printf 'ok: a quoted value still counts its quotes (%s vs %s)\n' \
            "$wrapped_n" "$inline_n"
    else
        printf 'FAIL: quoted measures %s against inline %s; expected exactly two more\n' \
            "$wrapped_n" "$inline_n" >&2
        fail=1
    fi
fi

# ---------------------------------------------------------------------------
# The body-ceiling check. It had no test at all until this block, and three
# sessions in a row settled its tier by hand from a mutation each of them
# had to invent. Every case below builds a throwaway git
# repository, because the check grandfathers each body at the size it measured
# on the merge base and there is no such reading without one.

# Build a repo holding one skill at `base_bytes`, commit it as the base, then
# resize the body to `head_bytes` and run the validator against that base.
# Prints the validator's output; returns its exit status.
ceiling_case() {
    local name="$1" skill="$2" base_bytes="$3" head_bytes="$4"
    local dir="$tmp/ceil-$name"
    rm -rf "$dir"
    mkdir -p "$dir/$skill"
    (
        cd "$dir"
        git init -q .
        git config user.email t@example.com
        git config user.name test
        body "$skill" "$base_bytes" > "$skill/SKILL.md"
        git add -A
        git -c commit.gpgsign=false commit -qm base
        body "$skill" "$head_bytes" > "$skill/SKILL.md"
        "$validator" --base HEAD 2>&1
    )
}

# A valid SKILL.md for `name`, padded to exactly `size` bytes. The padding is a
# comment line so the file stays a plausible body rather than a blob.
body() {
    local name="$1" size="$2" head pad
    head="---
name: $name
description: a body sized for the ceiling test.
---

"
    pad=$(( size - ${#head} - 1 ))
    printf '%s' "$head"
    head -c "$pad" < /dev/zero | tr '\0' 'z'
    printf '\n'
}

expect_ceiling_ok() {
    local label="$1"; shift
    local out
    if out="$(ceiling_case "$@")"; then
        printf 'ok: %s\n' "$label"
    else
        printf 'FAIL: %s — rejected: %s\n' "$label" "$out" >&2
        fail=1
    fi
}

expect_ceiling_reject() {
    local label="$1" pattern="$2"; shift 2
    local out
    if out="$(ceiling_case "$@")"; then
        printf 'FAIL: %s — accepted, expected rejection: %s\n' "$label" "$out" >&2
        fail=1
    elif [[ "$out" != *"$pattern"* ]]; then
        printf 'FAIL: %s — rejected for the wrong reason: %s\n' "$label" "$out" >&2
        fail=1
    else
        printf 'ok: %s (%s)\n' "$label" "$pattern"
    fi
}

# A skill absent from SKILL_TIER is cold, so 12 KiB is its ceiling. The pair
# straddles it by one byte in each direction, which is what says the boundary
# is where the constant puts it rather than near it. These two name a skill
# that does not exist on purpose: absence *is* the case under test, so no edit
# to the map can reach them. The warm and hot pair below cannot do that — a
# tier only exists for a name the map lists — which is why they ask for one.
expect_ceiling_ok 'a cold body at its 12 KiB ceiling' \
    cold-at unlisted-skill 4096 12288
expect_ceiling_reject 'a cold body one byte over' '12,288-byte cold ceiling' \
    cold-over unlisted-skill 4096 12289

# The name of a skill in one tier, from the enforcer's own reading of the map.
# Hardcoding one here reddens this test whenever SKILL_TIER is edited for an
# unrelated reason: the extraction that produced this repo hit it twice in one
# session, once by making the named skill cold and once by naming a skill that
# had not come across. The fixture follows the map instead.
if ! tiers="$("$validator" --report-tiers 2>&1)"; then
    printf 'FAIL: --report-tiers failed: %s\n' "$tiers" >&2
    fail=1
    tiers=''
fi
tier_member() {
    awk -v tier="$1" '$1 == tier { print $2; exit }' <<<"$tiers"
}

# Warm and hot are the same check reading a different row of TIER_CEILING; a
# case each is what catches a tier whose ceiling was mistyped. A tier nobody is
# in skips rather than fails — an empty tier is a legitimate map, and failing
# on it would be the hardcoding defect back in another form.
warm_skill="$(tier_member warm)"
if [[ -n "$warm_skill" ]]; then
    expect_ceiling_reject "a warm body one byte over ($warm_skill)" \
        '16,384-byte warm ceiling' \
        warm-over "$warm_skill" 4096 16385
else
    printf 'skip: the warm ceiling — no skill is tiered warm\n'
fi

hot_skill="$(tier_member hot)"
if [[ -n "$hot_skill" ]]; then
    expect_ceiling_ok "a hot body under its 24 KiB ceiling ($hot_skill)" \
        hot-under "$hot_skill" 4096 24576
else
    printf 'skip: the hot ceiling — no skill is tiered hot\n'
fi

# The grandfather, which is the whole transition: a body already past its
# ceiling on the base keeps that size and may only lose bytes. Growth of one
# byte is the rejection, and the same body shrinking is the control that says
# the refusal is about direction rather than about the file having changed.
expect_ceiling_reject 'a grandfathered body growing by one byte' \
    'over the 40,000 it measured at the merge base' \
    grandfather-grow verify-claims 40000 40001
expect_ceiling_ok 'the same grandfathered body shrinking' \
    grandfather-shrink verify-claims 40000 39000

# Without a base there is nothing to grandfather against, so the check says so
# and reports; --strict is what stops CI being a place it can silently not run.
no_base_dir="$tmp/ceil-nobase"
rm -rf "$no_base_dir"
mkdir -p "$no_base_dir/verify-claims"
body verify-claims 40000 > "$no_base_dir/verify-claims/SKILL.md"
if out="$(cd "$no_base_dir" && "$validator" 2>&1)"; then
    if [[ "$out" == *"no merge base"* ]]; then
        printf 'ok: an unreadable merge base reports and does not fail\n'
    else
        printf 'FAIL: an unreadable merge base passed without saying so: %s\n' "$out" >&2
        fail=1
    fi
else
    printf 'FAIL: an unreadable merge base failed without --strict: %s\n' "$out" >&2
    fail=1
fi

# The check must be SKIPPED with no base, not run against a baseline of zero.
# The body above is 40,000 bytes against a 24 KiB hot ceiling, so a zero
# baseline reports it as having grown — nine such lines shipped in review,
# above a "24 skill(s) OK" and an exit 0, which is a gate contradicting itself.
# Assert on the output rather than the status: both arms exit 0, so the status
# cannot tell the two apart and is not the observable here.
if [[ "$out" == *"grew past the ceiling"* ]]; then
    printf 'FAIL: with no base, a grandfathered body was reported as grown: %s\n' "$out" >&2
    fail=1
else
    printf 'ok: with no base the ceiling check is skipped, not measured against zero\n'
fi
if out="$(cd "$no_base_dir" && "$validator" --strict 2>&1)"; then
    printf 'FAIL: --strict accepted an unreadable merge base: %s\n' "$out" >&2
    fail=1
elif [[ "$out" != *"--strict was passed"* ]]; then
    printf 'FAIL: --strict failed for the wrong reason: %s\n' "$out" >&2
    fail=1
else
    printf 'ok: --strict turns an unreadable merge base into a failure\n'
fi

if (( fail )); then
    printf 'test-validate-skills: FAILED\n' >&2
    exit 1
fi

printf 'test-validate-skills: all cases passed\n'
