#!/usr/bin/env bash
#
# install.sh — install everything this repo ships: the skills and the output
# style(s).
#
# The two halves land in different directories and have different failure
# modes, so the work is still done by install-skills.sh for the skills and by
# the loop below for the styles. This script exists so that a clone has one
# obvious entry point and nobody installs half the repo by running the half
# they happened to find.
#
# It does not write to any settings file. Selecting an output style replaces
# whichever style the machine runs today — only one is ever active, and a style
# replaces Claude Code's defaults rather than layering on them. That is the
# machine's decision, not a clone's, so this prints the line to add and stops.
#
# Usage:
#   scripts/install.sh [--dry-run] [--force] [--skills-target DIR]
#                      [--styles-target DIR]
#
# It installs everything. Choosing which skills to take is install-skills.sh's
# job, and this refuses skill names rather than growing a second spelling of a
# partial install.
#
#   --dry-run      Report what would change and exit.
#   --force        Replace an existing entry that is not our symlink. Refuses
#                  without this, because that entry may be someone else's.
#   --skills-target  Install skills somewhere other than ~/.claude/skills.
#   --styles-target  Install styles somewhere other than ~/.claude/output-styles.
#
# Requires: bash, coreutils. No network.

set -euo pipefail

die() { echo "install: $*" >&2; exit 1; }

DRY_RUN=0
FORCE=0
STYLES_TARGET="${HOME}/.claude/output-styles"
SKILLS_FLAGS=()

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run)       DRY_RUN=1; SKILLS_FLAGS+=("$1"); shift ;;
    --force)         FORCE=1; SKILLS_FLAGS+=("$1"); shift ;;
    --skills-target) SKILLS_FLAGS+=(--target "${2:-}"); shift 2 ;;
    --styles-target) STYLES_TARGET="${2:-}"; shift 2 ;;
    -h|--help)       awk 'NR>1 { if (!/^#/) exit; sub(/^# ?/, ""); print }' "$0"; exit 0 ;;
    -*)              die "unknown option: $1" ;;
    *)               die "this installs everything; for one skill run: scripts/install-skills.sh $1" ;;
  esac
done

# Resolving through the script's own location rather than the working directory
# keeps `bash /path/to/scripts/install.sh` working from anywhere.
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# Both halves report conflicts and keep going, so a conflict in the skills does
# not skip the styles. The status is carried to the end instead.
rc=0

echo "== skills"
# INSTALL_SKILLS_UMBRELLA suppresses that script's pointer back to this one,
# which is addressed to somebody who ran it directly.
INSTALL_SKILLS_UMBRELLA=1 \
  "$ROOT/scripts/install-skills.sh" ${SKILLS_FLAGS[@]+"${SKILLS_FLAGS[@]}"} || rc=$?

echo
echo "== output styles"

SRC_DIR="$ROOT/output-styles"
[ -d "$SRC_DIR" ] || die "no such source directory: $SRC_DIR"

# The target usually does not exist on a machine that has never set a style, and
# `ln -s` into a missing directory fails with a message about the wrong file.
[ "$DRY_RUN" -eq 1 ] || mkdir -p "$STYLES_TARGET"

linked=0 already=0 replaced=0 conflicts=0

for src in "$SRC_DIR"/*.md; do
  [ -f "$src" ] || continue
  name="$(basename "$src")"

  # README.md documents the styles rather than being one. Claude Code would
  # read it as a style named README and offer it in the picker.
  [ "$name" = "README.md" ] && continue

  dest="$STYLES_TARGET/$name"

  if [ -L "$dest" ]; then
    current="$(readlink -f "$dest" 2>/dev/null || true)"
    if [ "$current" = "$(readlink -f "$src")" ]; then
      echo "  ok       $name"
      already=$((already + 1))
      continue
    fi
    # A link whose target is gone — the repo it pointed into was moved,
    # renamed, or had the style taken out of it. -e follows the link, so
    # this is the dangling case and nothing else. --force exists to stop us
    # destroying somebody's only copy, and here there is no copy: the style
    # is already broken, and a prompt to re-run with --force spends a decision
    # on a file that cannot be read either way.
    if [ ! -e "$dest" ]; then
      # Read before the relink, or this reports the target we just wrote.
      was="$(readlink "$dest" 2>/dev/null || echo "$current")"
      [ "$DRY_RUN" -eq 1 ] || { rm -f "$dest"; ln -s "$src" "$dest"; }
      echo "  relink   $name (was a broken link to $was)"
      replaced=$((replaced + 1))
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
    # A real file here is someone's own style, and it is very likely the only
    # copy. Overwriting it without being told to would destroy it.
    if [ "$FORCE" -eq 0 ]; then
      echo "  CONFLICT $name is a real file, not a link (--force to replace)" >&2
      conflicts=$((conflicts + 1))
      continue
    fi
    [ "$DRY_RUN" -eq 1 ] || { rm -f "$dest"; ln -s "$src" "$dest"; }
    echo "  replace  $name (was a real file)"
    replaced=$((replaced + 1))
    continue
  fi

  [ "$DRY_RUN" -eq 1 ] || ln -s "$src" "$dest"
  echo "  link     $name"
  linked=$((linked + 1))
done

echo
if [ "$DRY_RUN" -eq 1 ]; then
  echo "install: dry run — nothing written."
else
  echo "install: $STYLES_TARGET"
fi
echo "  linked $linked, replaced $replaced, already installed $already," \
     "conflicts $conflicts"

# Linking a style makes it available; it does not select it. Without this the
# install looks complete and nothing about the session changes.
if [ "$DRY_RUN" -eq 0 ] && { [ "$linked" -gt 0 ] || [ "$replaced" -gt 0 ]; }; then
  echo
  echo "A linked style is available, not active. To use Clarity, add this to"
  echo "$HOME/.claude/settings.json (or a project .claude/settings.json):"
  echo
  echo '    { "outputStyle": "Clarity" }'
  echo
  echo "Only one style is active at a time and it replaces Claude Code's"
  echo "defaults, so this is a trade against whichever style you run now."
  echo "Restart Claude Code afterwards — style files are read at startup."
fi

if [ "$conflicts" -gt 0 ]; then
  echo
  echo "$conflicts style(s) already exist and were left alone. Re-run with" >&2
  echo "--force to replace them, after checking you do not need what is there." >&2
  rc=1
fi

exit $rc
