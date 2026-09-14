#!/usr/bin/env bash
#
# test-clarity-reminder.sh — check that the hook denies what it claims to deny,
# and stays silent everywhere else.
#
# Silence is the hook's own success path, so a test that only asserted silence
# would pass against a script that had been emptied. Every case names the
# verdict it expects, and the first two are a matched pair: the same staged
# files under the same command, differing only in whether the pass has run.
#
# The fixtures are real git repositories because the hook reads a real index.
# A stub standing in for `git diff --cached` would agree with whatever the hook
# asked it, including the wrong question.

set -eu

here="$(cd "$(dirname "$0")" && pwd)"
hook="$here/clarity-reminder.py"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

fail=0

# A git repo with one commit behind it, so the index has something to differ
# from. $1 directory name; the rest are files to create and stage.
repo() {
    local dir="$tmp/$1"; shift
    mkdir -p "$dir"
    git -C "$dir" init -q
    git -C "$dir" config user.email t@e; git -C "$dir" config user.name t
    echo seed > "$dir/seed.txt"
    git -C "$dir" add seed.txt
    git -C "$dir" commit -qm seed
    local f
    for f in "$@"; do
        mkdir -p "$dir/$(dirname "$f")"
        echo 'x' > "$dir/$f"
        git -C "$dir" add "$f"
    done
    echo "$dir"
}

# A transcript naming the skills this session invoked. $1 name, rest are skills.
transcript() {
    local out="$tmp/$1.jsonl"; shift
    : > "$out"
    local s
    for s in "$@"; do
        printf '{"message":{"role":"assistant","content":[{"type":"tool_use","name":"Skill","input":{"skill":"%s"}}]}}\n' "$s" >> "$out"
    done
    echo "$out"
}

json() { printf '%s' "$1" | python3 -c 'import json,sys;print(json.dumps(sys.stdin.read()))'; }

# $1 label, $2 expected verdict, $3 command, $4 cwd, $5 transcript.
expect() {
    local label="$1" want="$2" got
    got="$(printf '{"tool_name":"Bash","tool_input":{"command":%s},"cwd":%s,"transcript_path":%s}' \
        "$(json "$3")" "$(json "$4")" "$(json "$5")" | python3 "$hook" | python3 -c '
import json,sys
raw = sys.stdin.read().strip()
if not raw:
    print("silent")
else:
    d = json.loads(raw)["hookSpecificOutput"]
    assert d["permissionDecisionReason"].startswith("clarity-reminder: "), "unprefixed reason"
    print(d["permissionDecision"])
')"
    if [ "$got" = "$want" ]; then
        printf 'ok   %s\n' "$label"
    else
        printf 'FAIL %s — wanted %s, got %s\n' "$label" "$want" "$got" >&2
        fail=1
    fi
}

three="$(repo three a.go b.go c.go)"
two="$(repo two a.go b.go)"
prose="$(repo prose a.md b.md c.md)"
none="$(transcript none)"
met="$(transcript met code-restraint)"
commit='git commit -m x'

expect "three staged source files and no pass denies"  deny   "$commit" "$three" "$none"
expect "the same commit with the pass run is silent"   silent "$commit" "$three" "$met"
expect "two files are below the rule's floor"          silent "$commit" "$two"   "$none"
expect "prose files match no default rule"             silent "$commit" "$prose" "$none"
expect "a command that is not a commit is silent"      silent 'git log --oneline' "$three" "$none"
expect "commit named in an unrelated word"             silent 'grep commit a.go'  "$three" "$none"
expect "an inline override is silent"                  silent "CLARITY_REMINDER_OVERRIDE=typo $commit" "$three" "$none"
expect "a commit later in an && chain still denies"    deny   "make check && $commit" "$three" "$none"
expect "a directory that is not a repo stays silent"   silent "$commit" "$tmp"   "$none"

# Staged nothing, but `-a` sweeps a tracked modification into the commit.
dasha="$(repo dasha a.go b.go c.go)"
git -C "$dasha" commit -qm staged
printf 'changed\n' >> "$dasha/a.go"; printf 'changed\n' >> "$dasha/b.go"; printf 'changed\n' >> "$dasha/c.go"
expect "plain commit sees an empty index"              silent "$commit" "$dasha" "$none"
expect "commit -a sees the tracked modifications"      deny   'git commit -am x' "$dasha" "$none"

# The hook speaks once: a session carrying its earlier deny is left alone. The
# deny is a failed tool result, which is the shape Claude Code returns a denied
# call as — matched on that rather than on the prefix appearing anywhere, per
# the pair below.
spoke="$(transcript spoke)"
printf '{"message":{"role":"user","content":[{"type":"tool_result","is_error":true,"content":"clarity-reminder: 3 staged file(s) ..."}]}}\n' >> "$spoke"
expect "a session it already stopped is not stopped again" silent "$commit" "$three" "$spoke"

# The matched pair the raw-string scan failed. Reading this script, or running
# it against a fixture, puts the prefix in the session's own transcript as
# ordinary output — six such lines in the session that made this change, none a
# deny. Matching the string silenced the hook for every session that ever
# worked on it, so both halves below are asserted: the quote must not count,
# and the deny above must still count.
quoted="$(transcript quoted)"
printf '{"message":{"role":"user","content":[{"type":"tool_result","is_error":false,"content":"clarity-reminder: 3 staged file(s) match the ..."}]}}\n' >> "$quoted"
printf '{"message":{"role":"assistant","content":[{"type":"text","text":"the reason opens clarity-reminder: and then says why"}]}}\n' >> "$quoted"
expect "a session that only quoted the prefix is still stopped" deny "$commit" "$three" "$quoted"

# A repo can disable the hook, or point a rule at its own paths.
mkdir -p "$three/.claude"
printf '{"rules": []}\n' > "$three/.claude/clarity-reminder.json"
expect "an empty rule list disables it"                silent "$commit" "$three" "$none"
rm -rf "$three/.claude"

mkdir -p "$prose/.claude"
printf '{"rules":[{"skill":"readability","paths":["*.md"],"min_files":2}]}\n' > "$prose/.claude/clarity-reminder.json"
expect "a repo rule replaces the default"              deny   "$commit" "$prose" "$none"

CLARITY_REMINDER_POSTURE=supervise \
    expect "supervise posture asks instead of denying" ask    "$commit" "$three" "$none"

# Two rules unmet at once. The hook has one utterance per session, so a rule
# left out of the reason is discarded rather than deferred — both names have to
# appear in the one deny. Asserted on the reason text, since the verdict is the
# same either way and would pass against the first-rule-only version.
both="$(repo both a.go b.go c.go x.md y.md z.md)"
mkdir -p "$both/.claude"
printf '{"rules":[{"skill":"code-restraint","paths":["*.go"],"min_files":2},{"skill":"readability","paths":["*.md"],"min_files":2}]}\n' \
    > "$both/.claude/clarity-reminder.json"
both_reason="$(printf '{"tool_name":"Bash","tool_input":{"command":%s},"cwd":%s,"transcript_path":%s}' \
    "$(json "$commit")" "$(json "$both")" "$(json "$none")" | python3 "$hook" \
    | python3 -c 'import json,sys;print(json.loads(sys.stdin.read())["hookSpecificOutput"]["permissionDecisionReason"])')"
if [ "${both_reason#*code-restraint}" != "$both_reason" ] \
    && [ "${both_reason#*readability}" != "$both_reason" ]; then
    printf 'ok   one deny names both unmet rules\n'
else
    printf 'FAIL one deny named only: %s\n' "$both_reason" >&2
    fail=1
fi

# And the met one drops out rather than being listed as outstanding.
met_go="$(transcript met_go code-restraint)"
one_reason="$(printf '{"tool_name":"Bash","tool_input":{"command":%s},"cwd":%s,"transcript_path":%s}' \
    "$(json "$commit")" "$(json "$both")" "$(json "$met_go")" | python3 "$hook" \
    | python3 -c 'import json,sys;print(json.loads(sys.stdin.read())["hookSpecificOutput"]["permissionDecisionReason"])')"
if [ "${one_reason#*readability}" != "$one_reason" ] \
    && [ "${one_reason#*code-restraint}" = "$one_reason" ]; then
    printf 'ok   a rule whose pass has run is left out of the reason\n'
else
    printf 'FAIL the met rule was not dropped: %s\n' "$one_reason" >&2
    fail=1
fi

if [ "$fail" -eq 0 ]; then
    echo "test-clarity-reminder: all checks passed"
else
    echo "test-clarity-reminder: failures above" >&2
fi
exit "$fail"
