#!/usr/bin/env bash
#
# install-skills.sh — make this repo's skills available to Claude Code by
# symlinking each one into ~/.claude/skills/.
#
# Symlinks rather than copies, so `git pull` updates every installed skill at
# once and an edit to an installed skill is an edit to the repo.
#
# Claude Code only discovers skills in ~/.claude/skills/ (user) and
# .claude/skills/ (the project you are working in), so a skill sitting in this
# clone is invisible from any other repo until it is linked.
#
# Usage:
#   scripts/install-skills.sh [--dry-run] [--force] [--target DIR] [--src DIR]
#                             [SKILL ...]
#
#   SKILL      Install only the named skills. Every skill in the repo by
#              default. A name matching no skill is an error rather than a
#              quiet no-op, which is what a typo would otherwise be. Naming a
#              skill the ignore file lists installs it anyway, after printing
#              the reason — an explicit name is an explicit decision.
#   --ignore-file  Read the skip list from somewhere other than
#              TARGET/.install-skills-ignore.
#
# The ignore file lists skills this machine does not want linked, one name per
# line, `#` comments and blank lines ignored, and anything after the name on
# the line kept as the reason and printed when the skip happens. Which skills a
# machine wants is that machine's business rather than the repo's, which is why
# the list lives beside the install target instead of in the tree — a clone
# should not inherit it.
#
# It exists because a bare run of this script will otherwise link every skill
# in the repo, silently reversing a deliberate decision to leave one out.
#   --dry-run  Report what would change and exit.
#   --force    Replace an existing entry that is not our symlink. Refuses
#              without this, because that entry may be someone's own skill.
#   --target   Install somewhere other than ~/.claude/skills.
#   --src      Read skills from somewhere other than the repo root — for a
#              clone that keeps them under skills/ rather than beside the
#              README.
#
# Requires: bash, coreutils. No network.

set -euo pipefail

die() { echo "install-skills: $*" >&2; exit 1; }

DRY_RUN=0
FORCE=0
TARGET="${HOME}/.claude/skills"
SRC_DIR=""
IGNORE_FILE=""
NAMES=()

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    --force)   FORCE=1; shift ;;
    --target)  TARGET="${2:-}"; shift 2 ;;
    --ignore-file) IGNORE_FILE="${2:-}"; shift 2 ;;
    --src)     SRC_DIR="${2:-}"; shift 2 ;;
    -h|--help) awk 'NR>1 { if (!/^#/) exit; sub(/^# ?/, ""); print }' "$0"; exit 0 ;;
    -*)        die "unknown option: $1" ;;
    *)         NAMES+=("$1"); shift ;;
  esac
done

# An empty selection means all of them. Expanding NAMES unguarded would abort
# under `set -u` on the bash 3.2 that ships with macOS.
wanted() {
  [ "${#NAMES[@]}" -eq 0 ] && return 0
  local n
  for n in "${NAMES[@]}"; do [ "$n" = "$1" ] && return 0; done
  return 1
}

# Skills live beside the README here, one directory each, so the repo root is
# the default source. Resolving through the script's own location rather than
# the working directory keeps `bash /path/to/scripts/install-skills.sh` working
# from anywhere.
[ -n "$SRC_DIR" ] || SRC_DIR="$(dirname "$0")/.."
[ -d "$SRC_DIR" ] || die "no such source directory: $SRC_DIR"

# The link target is written into the symlink verbatim, so a relative --src
# would resolve against ~/.claude/skills and dangle.
SRC_DIR="$(cd "$SRC_DIR" && pwd)"

# Defaulted here rather than at declaration, so --target and --ignore-file can
# arrive in either order.
[ -n "$IGNORE_FILE" ] || IGNORE_FILE="$TARGET/.install-skills-ignore"

# reason_to_skip NAME — exits 0 when the ignore file lists NAME, printing
# whatever follows the name on that line as the reason. A missing ignore file
# is the ordinary case, not an error.
reason_to_skip() {
  [ -f "$IGNORE_FILE" ] || return 1
  awk -v want="$1" '
    /^[[:space:]]*#/ || /^[[:space:]]*$/ { next }
    $1 == want {
      $1 = ""
      sub(/^[[:space:]]*#?[[:space:]]*/, "")
      print
      found = 1
      exit
    }
    END { exit !found }
  ' "$IGNORE_FILE"
}

[ "$DRY_RUN" -eq 1 ] || mkdir -p "$TARGET"

linked=0 already=0 replaced=0 conflicts=0 skipped=0
seen=""

for src in "$SRC_DIR"/*/; do
  [ -d "$src" ] || continue
  src="${src%/}"
  name="$(basename "$src")"
  dest="$TARGET/$name"

  # Most directories at the repo root are not skills — scripts/, docs/, and
  # whatever arrives next. A skill is a directory holding a SKILL.md, and
  # anything else is passed over without comment. A directory meant to be a
  # skill and missing one is validate-skills.py's to catch, not this script's;
  # here it would be a line of noise on every run.
  [ -f "$src/SKILL.md" ] || continue

  seen="$seen $name"
  wanted "$name" || continue

  # A skill this machine does not want linked. Skipped by the default run and
  # installed when named, because the failure being guarded is a bare run
  # reversing a decision silently, not a maintainer choosing to link it.
  if reason="$(reason_to_skip "$name")"; then
    [ -n "$reason" ] || reason="no reason given in $IGNORE_FILE"
    if [ "${#NAMES[@]}" -eq 0 ]; then
      echo "  skip     $name ($reason)"
      skipped=$((skipped + 1))
      continue
    fi
    echo "  NOTE     $name is in the ignore file and you named it: $reason" >&2
  fi

  if [ -L "$dest" ]; then
    current="$(readlink -f "$dest" 2>/dev/null || true)"
    if [ "$current" = "$(readlink -f "$src")" ]; then
      echo "  ok       $name"
      already=$((already + 1))
      continue
    fi
    if [ "$FORCE" -eq 0 ]; then
      echo "  CONFLICT $name -> $current (already linked elsewhere; --force to replace)" >&2
      conflicts=$((conflicts + 1))
      continue
    fi
    [ "$DRY_RUN" -eq 1 ] || { rm -f "$dest"; ln -s "$src" "$dest"; }
    echo "  replace  $name (was $current)"
    replaced=$((replaced + 1))
    continue
  fi

  if [ -e "$dest" ]; then
    # A real directory here is very likely a skill someone installed by hand.
    # Removing it without being told to would destroy the only copy. `ln -sfn`
    # does not refuse this case — it drops the link *inside* the directory and
    # exits 0, so the install silently does not happen.
    if [ "$FORCE" -eq 0 ]; then
      echo "  CONFLICT $name is a real directory, not a link (--force to replace)" >&2
      conflicts=$((conflicts + 1))
      continue
    fi
    [ "$DRY_RUN" -eq 1 ] || { rm -rf "$dest"; ln -s "$src" "$dest"; }
    echo "  replace  $name (was a directory)"
    replaced=$((replaced + 1))
    continue
  fi

  [ "$DRY_RUN" -eq 1 ] || ln -s "$src" "$dest"
  echo "  link     $name"
  linked=$((linked + 1))
done

# A misspelled name would otherwise install nothing and exit 0, which reads as
# "already up to date".
for n in ${NAMES[@]+"${NAMES[@]}"}; do
  case " $seen " in
    *" $n "*) ;;
    *) die "no skill named '$n' in $SRC_DIR" ;;
  esac
done

echo
if [ "$DRY_RUN" -eq 1 ]; then
  echo "install-skills: dry run — nothing written."
else
  echo "install-skills: $TARGET"
fi
echo "  linked $linked, replaced $replaced, already installed $already," \
     "skipped $skipped, conflicts $conflicts"

# Naming the file is what makes the skip actionable; a bare count reads as a
# glitch and gets re-run with --force.
if [ "$skipped" -gt 0 ]; then
  echo
  echo "$skipped skill(s) listed in $IGNORE_FILE were skipped."
  echo "Name a skill explicitly to install it anyway."
fi

# Claude Code reads the skill list at startup, so a freshly linked skill will
# not appear in a session that is already running. Both notices below are about
# a link that now exists, so a dry run has nothing to say.
if [ "$DRY_RUN" -eq 0 ] && { [ "$linked" -gt 0 ] || [ "$replaced" -gt 0 ]; }; then
  echo
  echo "Restart Claude Code to pick up the changes."
fi

# Linking is only half of reaching a user; see "Some skills need naming before
# they fire" in the README for the measurement behind the other half.
if [ "$DRY_RUN" -eq 0 ] && [ "$linked" -gt 0 ]; then
  echo
  echo "A linked skill fires when something already in context names it. For one"
  echo "that should run on every applicable occasion, add a line naming it to"
  echo "$HOME/.claude/CLAUDE.md — see the README."
fi

# Non-zero on an unresolved conflict. Reporting one and exiting 0 means a setup
# script that calls this reads as successful having installed nothing.
if [ "$conflicts" -gt 0 ]; then
  echo
  echo "$conflicts skill(s) already exist and were left alone. Re-run with" >&2
  echo "--force to replace them, after checking you do not need what is there." >&2
  exit 1
fi
