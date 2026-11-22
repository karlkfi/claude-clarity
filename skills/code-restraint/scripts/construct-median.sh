#!/usr/bin/env bash
#
# construct-median.sh — median span, in lines, between successive matches of
# a construct in one file. Usage: construct-median.sh <ERE-pattern> <file>
#
# Kept out of SKILL.md: a body has its $1 rewritten when invoked with arguments.

set -eu

[ "$#" -eq 2 ] || { echo "usage: ${0##*/} <pattern> <file>" >&2; exit 2; }

grep -nE -e "$1" -- "$2" | cut -d: -f1 \
  | awk 'NR>1 {print $1-p} {p=$1}' | sort -n \
  | awk '{a[NR]=$1} END {if (NR) printf "median %d lines over %d\n", a[int((NR+1)/2)], NR}'
