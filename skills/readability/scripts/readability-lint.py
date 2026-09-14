#!/usr/bin/env python3
"""readability-lint: find shorthand a document invented and never explained.

Usage: readability-lint.py [--known TERM,TERM] [--known-file PATH]
                          [--list] file.md [file2.md ...]

Mechanizes one rule from the skill's "No unexplained shorthand" — the third
kind, "a shorthand the document invented for itself", which the skill calls
the worst case because the term exists nowhere else for a reader to look up.
The other two kinds need world knowledge (is this product one the reader
already knows?) and are deliberately not attempted here.

The rule's test is whether a term appears in "the material the reader already
has". A script cannot know what that is, so --known is where you say: pass the
terms the audience arrives with and they stop being findings. A project whose
reader has a standing vocabulary should commit it and pass --known-file, one
term per line, `#` for comments — the same shape as a spell-checker dictionary,
and for the same reason. A finding here means "you have not told me your reader
knows this", which is a claim about the audience rather than about the word.

  FAIL  used, never expanded anywhere. Certain, and the repair is mechanical:
        expand it at first use.
  WARN  expanded, but after the reader first meets it. Moving the expansion is
        usually right and sometimes wrong, so this one wants a human.

An expansion is recognised as `Full Name (ABC)`, `ABC (Full Name)`, or
`ABC stands for/is short for ...`, matching on initials.

Limits worth knowing before trusting a clean run. A candidate needs two or
more uses, because a single all-caps word is nearly always emphasis rather
than a coined term — so a shorthand used exactly once is invisible here.
Candidates are letters only, because an expansion maps words to initials and a
digit never comes from one; that is what keeps identifiers like Q644 out, and
it also means a term carrying a number (ASD-STE100) is never a finding. Code
spans, fenced blocks, and link URLs are stripped first, which means a term
introduced only inside a code sample reads as never expanded. And matching is
on initials, so an expansion that does not share them ("k8s" for Kubernetes)
is missed. Exit 1 on any FAIL, 0 otherwise; a WARN never changes the status.
"""
import re
import sys

# Initialisms a general technical reader is assumed to arrive with. Keeping
# this list short is deliberate: every entry is a finding the tool agrees not
# to make, and the skill's rule is about the reader rather than about us.
ASSUMED = {
    "API", "APIS", "CLI", "CPU", "CSS", "CSV", "DNS", "GPU", "HTML", "HTTP",
    "HTTPS", "ID", "IDE", "IO", "IP", "JSON", "OS", "PDF", "RAM", "REST",
    "SDK", "SHA", "SQL", "SSH", "SSL", "SVG", "PNG", "JPEG", "GIF", "TSV",
    "POSIX", "BSD", "TCP", "TLS", "TODO", "UI", "URL", "URI",
    "UTC", "UUID", "XML", "YAML", "ZIP",
    "AI", "CI", "CD", "PR", "PRS", "OK", "FAQ", "MIT", "GNU",
    # Units and clock, which are read rather than expanded.
    "KB", "MB", "GB", "TB", "KIB", "MIB", "GIB", "MS", "NS", "AM", "PM",
    "GMT", "PDT", "PST", "EST", "EDT", "CET",
    # Filenames a repo reader meets as files, not as terms.
    "README", "LICENSE", "CHANGELOG", "CODEOWNERS", "MAKEFILE", "STATUS",
    "NOTICE", "CONTRIBUTING",
}

# All-caps English words are emphasis, not coinage. Only the common ones are
# needed: a word used for stress twice in one document is rare.
EMPHASIS = {
    "A", "I", "ALL", "ALWAYS", "AND", "ANY", "BUT", "CAN", "DO", "DONT",
    "EVER", "EVERY", "FOR", "HOW", "IF", "IS", "IT", "MUST", "NEVER", "NEW",
    "NO", "NOT", "NOTE", "NOW", "OF", "OLD", "ON", "ONE", "ONLY", "OR", "SO",
    "THE", "THIS", "TO", "USE", "VERY", "WARNING", "WHAT", "WHEN", "WHY",
    "WILL", "WITH", "YES", "YOU", "YOUR", "HUGE", "BIG", "REAL", "TRUE",
    "FALSE", "NONE", "OFF", "UP", "DOWN", "GOOD", "BAD", "BEST", "WORST",
}

TERM = re.compile(r"\b[A-Z]{2,10}\b")


def strip_noise(text):
    """Remove what a reader does not read as prose, keeping line numbers."""
    text = re.sub(r"```.*?```", lambda m: "\n" * m.group(0).count("\n"),
                  text, flags=re.S)
    text = re.sub(r"`[^`\n]*`", " ", text)
    text = re.sub(r"\]\([^)\s]*\)", "] ", text)
    text = re.sub(r"<[^>\s]*>", " ", text)
    return text


def initials(phrase):
    return "".join(w[0] for w in re.findall(r"[A-Za-z][\w-]*", phrase)).upper()


def expansion_line(text, term):
    """First line number where `term` is expanded, or None."""
    n = len(term)
    for i, line in enumerate(text.splitlines(), 1):
        # Full Name (ABC)
        for m in re.finditer(r"([\w][\w '-]*?)\s*\(" + re.escape(term) + r"s?\)",
                             line):
            words = re.findall(r"[A-Za-z][\w-]*", m.group(1))
            if len(words) >= n and initials(" ".join(words[-n:])) == term:
                return i
        # ABC (Full Name)
        for m in re.finditer(re.escape(term) + r"s?\s*\(([^)]{3,})\)", line):
            words = re.findall(r"[A-Za-z][\w-]*", m.group(1))
            if len(words) >= n and initials(" ".join(words[:n])) == term:
                return i
        # ABC stands for / is short for
        if re.search(re.escape(term) + r"\b[^.]{0,20}?\b"
                     r"(?:stands for|short for|is shorthand for)\b", line):
            return i
    return None


def lint(text, known=()):
    prose = strip_noise(text)
    known = {k.strip().upper() for k in known if k.strip()}
    skip = ASSUMED | EMPHASIS | known

    first = {}
    counts = {}
    for i, line in enumerate(prose.splitlines(), 1):
        for term in TERM.findall(line):
            base = term[:-1] if term.endswith("S") and term[:-1] in first else term
            counts[base] = counts.get(base, 0) + 1
            first.setdefault(base, i)

    fails, warns = [], []
    for term, count in sorted(counts.items(), key=lambda kv: first[kv[0]]):
        if term in skip or count < 2:
            continue
        where = expansion_line(prose, term)
        if where is None:
            fails.append((first[term], term, count))
        elif where > first[term]:
            warns.append((first[term], term, count, where))
    return fails, warns, len(counts)


def main():
    args = sys.argv[1:]
    known, listing = [], False
    while args and args[0].startswith("--"):
        if args[0] == "--known" and len(args) > 1:
            known += args[1].split(",")
            args = args[2:]
        elif args[0] == "--known-file" and len(args) > 1:
            with open(args[1], encoding="utf-8") as fh:
                known += [ln.split("#")[0] for ln in fh]
            args = args[2:]
        elif args[0] == "--list":
            listing = True
            args = args[1:]
        else:
            sys.exit(__doc__)
    if not args:
        sys.exit(__doc__)

    status = 0
    for path in args:
        with open(path, encoding="utf-8") as fh:
            text = fh.read()
        fails, warns, seen = lint(text, known)
        print(f"{path}  candidates={seen}  fail={len(fails)}  warn={len(warns)}")
        for line, term, count in fails:
            print(f"  FAIL  {path}:{line}: {term} used {count}x, never expanded"
                  f" — expand it at first use, or pass --known {term}")
        for line, term, count, where in warns:
            print(f"  WARN  {path}:{line}: {term} used {count}x, first expanded"
                  f" at line {where} — move the expansion to first use unless"
                  f" line {line} is a title or a quotation")
        if listing:
            print("  assumed-known:", " ".join(sorted(ASSUMED | set(
                k.strip().upper() for k in known if k.strip()))))
        if fails:
            status = 1
    return status


if __name__ == "__main__":
    sys.exit(main())
