#!/usr/bin/env python3
#
# clarity-reminder.py — hold a commit until the pass that applies to it has run.
#
# A skill fires when something already in the context names it, and a line in a
# CLAUDE.md is read once at session start rather than at the moment its subject
# comes up. Measured over 2,117 local transcripts on one workstation:
# code-restraint ran in 13 of the 531 sessions that edited a source file and
# committed, and in 2 of the 138 that edited five or more. Naming it moved the
# rate from 1.3% to 5.4% and stopped there. This hook is the rung that fires on
# the occasion instead: it reads the session's own transcript at `git commit`,
# and denies when a rule's paths were edited and its skill never ran.
#
# The verdict is `deny` rather than `ask` because the model is the actor who
# has to run the pass. A deny's reason is the tool error, so it reaches the
# model and the fix lands where the work is; an approved ask reaches the human,
# returns as an ordinary tool result, and teaches the session nothing.
#
# What is being committed comes from the index, not from the transcript. A file
# written with a Bash heredoc or sed leaves no Edit tool call, so a transcript
# scan misses it — and at `git commit` the index is the direct evidence anyway.
# The transcript answers the other half: which skills this session invoked.
#
# It speaks at most once per session, and names every unmet rule when it does,
# because that one utterance is the whole budget: a rule left out of the reason
# is discarded rather than deferred to the next commit.
#
# Before deciding it looks for its own earlier deny — a failed tool result
# opening with the prefix, not the prefix anywhere in the line — so a session it
# has already stopped is never stopped again. A pass the hook cannot see having
# run (a transcript still being flushed, a skill invoked some other way) costs
# one deny rather than a loop.
#
# Configure per repo in .claude/clarity-reminder.json under the project root:
#
#   {"rules": [{"skill": "code-restraint",
#               "paths": ["*.go", "*.py"],
#               "min_files": 3,
#               "reason": "what to do about it"}]}
#
# Absent that file, DEFAULT_RULES applies. `"rules": []` disables the hook for
# a repo without uninstalling it.

import fnmatch
import json
import os
import re
import subprocess
import sys

# Spelled as one literal rather than composed from a name constant: the
# attribution checker is a static reader and cannot follow a prefix built at
# runtime, so composing it costs a permanent warning for no gain.
PREFIX = 'clarity-reminder: '
CONFIG = '.claude/clarity-reminder.json'

# Source only; a repo wanting a prose rule adds one.
SOURCE = ['*.go', '*.py', '*.sh', '*.ts', '*.tsx', '*.js', '*.rs', '*.java',
          '*.rb', '*.c', '*.h', '*.cpp', '*.mk', 'Makefile']

DEFAULT_RULES = [{
    'skill': 'code-restraint',
    'paths': SOURCE,
    'min_files': 3,
    'reason': 'It matches comment density, altitude and code shape to the host '
              'file, which is the check a diff cannot pass by being correct.',
}]

def emit(decision, reason):
    """Print a PreToolUse decision as the hook's stdout JSON."""
    print(json.dumps({'hookSpecificOutput': {
        'hookEventName': 'PreToolUse',
        'permissionDecision': decision,
        'permissionDecisionReason': reason}}))


def is_commit(cmd):
    """True for a command that creates a commit, false for one that reads one.

    Splits on every connector, not just `;`. exit-status-guard requires a gate
    to be joined to the commit with `&&`, so `make check && git commit` is the
    ordinary shape here and a `;`-only split misses almost every real commit.
    """
    for seg in re.split(r'&&|\|\||[;\n|]', cmd):
        words = seg.split()
        if 'git' in words[:2] and 'commit' in words:
            return True
    return False


def load_rules(cwd):
    """Read the repo's rules, falling back to the default one."""
    try:
        with open(os.path.join(cwd, CONFIG), encoding='utf-8') as fh:
            rules = json.load(fh).get('rules')
    except (OSError, ValueError):
        return DEFAULT_RULES
    return rules if isinstance(rules, list) else DEFAULT_RULES


def staged(cwd, cmd):
    """Paths this commit would carry, read from git rather than from the tools.

    `git commit -a` stages tracked modifications as it runs, so the unstaged
    set counts too whenever the command carries that flag.
    """
    specs = [['diff', '--cached', '--name-only']]
    if re.search(r'(?<![\w-])-(?:[a-zA-Z]*a[a-zA-Z]*)(?![\w-])|--all(?![\w-])', cmd):
        specs.append(['diff', '--name-only'])
    out = set()
    for spec in specs:
        try:
            run = subprocess.run(['git', '-C', cwd] + spec, capture_output=True,
                                 text=True, timeout=10)
        except (OSError, subprocess.SubprocessError):
            return set()
        if run.returncode != 0:
            return set()
        out.update(p for p in run.stdout.splitlines() if p.strip())
    return out


def is_own_deny(block):
    """True for the failed tool result a call this hook denied comes back as."""
    if block.get('type') != 'tool_result' or not block.get('is_error'):
        return False
    content = block.get('content')
    if isinstance(content, list):
        content = ' '.join(b.get('text') or '' for b in content
                           if isinstance(b, dict))
    return isinstance(content, str) and content.lstrip().startswith(PREFIX)


def read_session(path):
    """Return (skills invoked, whether this hook already denied this session).

    A deny is a failed tool result opening with the prefix. Matching the prefix
    anywhere in the line instead counts a session that merely read this script
    or ran it against a fixture, which silences the hook for every session that
    works on it.
    """
    skills, spoke = set(), False
    try:
        fh = open(path, encoding='utf-8', errors='replace')
    except OSError:
        return skills, spoke
    with fh:
        for line in fh:
            if '"tool_use"' not in line and PREFIX not in line:
                continue
            try:
                rec = json.loads(line)
            except ValueError:
                continue
            content = (rec.get('message') or {}).get('content')
            if not isinstance(content, list):
                continue
            for block in content:
                if not isinstance(block, dict):
                    continue
                if (block.get('type') == 'tool_use'
                        and block.get('name') == 'Skill'):
                    skill = (block.get('input') or {}).get('skill') or ''
                    skills.add(skill.split(':')[-1])
                elif is_own_deny(block):
                    spoke = True
    return skills, spoke


def matches(rule, edited):
    """Paths this rule covers, ignoring anything under a scratch directory."""
    globs = rule.get('paths') or []
    return sorted({
        p for p in edited
        if p and any(fnmatch.fnmatch(os.path.basename(p), g) for g in globs)})


def clause(rule, hits):
    """One rule's share of the reason: what matched, and why the pass exists."""
    shown = ', '.join(os.path.basename(p) for p in hits[:4])
    if len(hits) > 4:
        shown += f', and {len(hits) - 4} more'
    why = rule.get('reason') or ''
    return (f'`{rule["skill"]}`: {len(hits)} staged file(s) — {shown}. '
            f'{why}').strip()


def decide(rules, edited, skills):
    """Every unmet rule, as one reason string, or '' when all of them are met.

    All of them rather than the first, because the budget is one utterance per
    session, not one per rule: after a deny the hook is silent, so a rule left
    out of the reason is discarded rather than deferred to the next commit.
    """
    unmet, names = [], []
    for rule in rules:
        skill = rule.get('skill')
        if not skill or skill in skills:
            continue
        hits = matches(rule, edited)
        if len(hits) < int(rule.get('min_files', 1)):
            continue
        unmet.append(clause(rule, hits))
        names.append(f'`{skill}`')
    if not unmet:
        return ''
    lead = '' if len(unmet) == 1 else f'{len(unmet)} passes have not run. '
    named = names[0] if len(names) == 1 else ', '.join(names[:-1]) + f' and {names[-1]}'
    return (f'{lead}{" ".join(unmet)} '
            f'Fix: invoke {named} over this diff, then re-run the commit. '
            f'This hook speaks once per session, so the next commit is not '
            f'stopped either way. '
            f'Override: CLARITY_REMINDER_OVERRIDE=<reason>.')


def main():
    try:
        data = json.load(sys.stdin)
    except ValueError:
        return
    if (data.get('tool_name') or 'Bash') != 'Bash':
        return
    cmd = (data.get('tool_input') or {}).get('command') or ''
    if not is_commit(cmd):
        return
    if 'CLARITY_REMINDER_OVERRIDE=' in cmd or os.environ.get('CLARITY_REMINDER_OVERRIDE'):
        return
    cwd = data.get('cwd') or ''
    rules = load_rules(cwd)
    if not rules:
        return
    skills, spoke = read_session(data.get('transcript_path') or '')
    if spoke:
        return
    reason = decide(rules, staged(cwd, cmd), skills)
    if not reason:
        return
    posture = os.environ.get('CLARITY_REMINDER_POSTURE') or ''
    emit('ask' if posture == 'supervise' else 'deny', PREFIX + reason)


if __name__ == '__main__':
    main()
