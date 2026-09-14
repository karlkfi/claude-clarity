#!/usr/bin/env python3
"""deslop-lint: heuristic AI-slop linter for the deslop skill.

Usage: deslop-lint.py [--mode voice|plain|strict] file.md [file2.md ...]

Modes match the skill:
  voice  - essays/articles: tells and content-slop only. Contractions,
           fragments, and long sentences are voice, not violations.
  plain  - docs/READMEs/PR text: voice checks + STE mechanics minus the
           vocabulary lockdown. (default)
  strict - runbooks/procedures/error messages: everything, both word caps.

Score is violations per 100 words; lower is cleaner. The useful signal is
the delta between two drafts, not the absolute number. A clean score does
not mean the text is true, specific, or worth reading: content-slop checks
here are regex-shaped and catch only the canned forms. The skill's Step 3
needs a reader.

Unlike ste-lint.py (woosal1337/blog ep01, MIT, which inspired this),
markdown link URLs are stripped before counting, so a citation-dense
paragraph is not misread as a run-on sentence.
"""
import re
import sys

# --- tell catalog: all modes ------------------------------------------------

VOCAB = [
    "delve", "delves", "delving", "tapestry", "tapestries", "realm", "realms",
    "beacon", "intricate", "intricacies", "pivotal", "crucial", "vital",
    "seamless", "seamlessly", "robust", "leverage", "leverages", "leveraging",
    "foster", "fosters", "fostering", "empower", "empowers", "empowering",
    "unlock", "unlocks", "unleash", "unleashes", "elevate", "elevates",
    "streamline", "streamlines", "supercharge", "game-changing", "game-changer",
    "cutting-edge", "state-of-the-art", "best-in-class", "battle-tested",
    "enterprise-grade", "transformative", "revolutionary", "groundbreaking",
    "comprehensive", "multifaceted", "myriad", "plethora", "ever-evolving",
    "fast-paced", "landscape", "journey", "symphony", "synergy",
    "paradigm shift", "demystify", "holistic",
]
# words that are legitimate in a technical register; flagged at low
# confidence so the report separates them from the hard list
VOCAB_SOFT = ["landscape", "journey", "comprehensive", "crucial", "vital", "robust"]

PHRASES = [
    "it's important to note", "it is important to note", "it should be noted",
    "it's worth noting", "it is worth noting", "worth mentioning",
    "in today's digital age", "in today's fast-paced", "in the ever-evolving",
    "let's dive in", "dive into", "at its core", "at the end of the day",
    "in conclusion", "in summary", "in essence", "needless to say",
    "no discussion would be complete", "but here's the kicker",
    "that's only half the story", "here's the truth", "real talk",
    "i hope this helps", "let me know if", "great question",
    "i hope this message finds you well", "look no further",
    "the world of", "when it comes to", "first and foremost",
]

# content-slop, regex-shaped (canned forms only; Step 3 needs a reader)
VAGUE_ATTRIBUTION = re.compile(
    r"\b(studies (show|suggest|indicate)|experts (say|agree|believe)|"
    r"research (shows|suggests)|many (developers|engineers|users|teams) "
    r"(find|say|believe|agree)|it is widely (known|accepted))\b", re.I)
SIGNIFICANCE = re.compile(
    r"\b(plays a (vital|crucial|key|pivotal) role|underscores? the|"
    r"is a testament to|stands as a|marks a (pivotal|significant)|"
    r"cannot be overstated|rich (history|heritage))\b", re.I)
NEG_PARALLEL = re.compile(
    r"(\bnot (just|only|merely|simply)\b[^.!?]{0,80}\bbut\b|"
    r"\b(is|it's|its|are|was)n?'?t\s+(just\s+)?(a|an|about)\b[^.!?—;]{0,60}"
    r"[.;—,]\s*(it|this|that)(\'s| is| are)\b)", re.I)
NO_X_NO_Y = re.compile(r"\bNo \w[^.!?]{0,25}\.\s*No \w[^.!?]{0,25}\.\s*Just \w", re.I)
FALSE_RANGE = re.compile(
    r"\bfrom \w[\w\s-]{2,30} to \w[\w\s-]{2,30}(, | and )\w[\w\s-]{2,30}\b|"
    r"\b(whether you're|whether you are) [^.!?]{5,60},? or\b", re.I)
TACKED_ANALYSIS = re.compile(
    r",\s+(highlighting|underscoring|demonstrating|showcasing|reflecting|"
    r"emphasizing|signaling|cementing)\s+(the|its|a|how)\b", re.I)

SUMMARY_OPENER = re.compile(r"^(overall|in conclusion|in summary|ultimately|in essence)\b[, ]", re.I | re.M)
EMOJI_HEADER = re.compile(r"^#{1,6}\s*[^\w\s#>`\[]", re.M)
CURLY = re.compile(r"[“”‘’]")

# --- STE mechanics: plain + strict -------------------------------------------

PHRASAL = ["spin up", "spin down", "spun up", "reach out", "reaching out",
           "kick off", "kicks off", "roll out", "rolls out", "ramp up",
           "circle back", "drill down", "tear down"]
NOMINAL = re.compile(
    r"\b(perform(s|ed)?|conduct(s|ed)?|carry out|carries out|"
    r"make use of|makes use of)\b|\b\w{5,}(tion|ment|ance|ence)\s+of\b", re.I)
BE = r"(?:am|is|are|was|were|be|been|being)"
PP_IRREG = r"(?:done|made|sent|read|built|kept|held|set|put|run|written|shown|given|taken|found|seen|known)"
PASSIVE = re.compile(rf"\b{BE}\s+(?:\w+ed|{PP_IRREG})\b(\s+by\b)?", re.I)
CONTRACTION = re.compile(r"\b\w+['’](?:t|re|ve|ll|d|s|m)\b")


def strip_markup(t):
    t = re.sub(r"```.*?```", " ", t, flags=re.S)
    t = re.sub(r"`[^`]*`", " ", t)
    t = re.sub(r"==([^=]*)==", r"\1", t)                 # Medium inline-code marks
    t = re.sub(r"!\[[^\]]*\]\([^)]*\)", " ", t)          # images
    t = re.sub(r"\[([^\]]*)\]\([^)]*\)", r"\1", t)       # links: keep text, drop URL
    t = re.sub(r"<[^>]+>", " ", t)
    return t


def sentences(text):
    out = []
    for line in text.split("\n"):
        s = re.sub(r"^\s*(#{1,6}|>|[-*+]|\d+[.)])\s*", "", line.strip())
        if not s:
            continue
        for p in re.split(r"(?<=[.!?])\s+(?=[A-Z\"'])", s):
            if p.strip():
                out.append(p.strip())
    return out


def wc(s):
    return len(re.findall(r"[A-Za-z0-9][A-Za-z0-9'’/-]*", s))


def count_phrases(text, phrases):
    low, hits = text.lower(), []
    for ph in phrases:
        hits += [ph] * len(re.findall(r"(?<![a-z])" + re.escape(ph) + r"(?![a-z])", low))
    return hits


def lint(raw, mode):
    text = strip_markup(raw)
    sents = sentences(text)
    words = sum(wc(s) for s in sents) or 1
    v, samples = {}, {}

    def put(name, hits, sample=None):
        n = hits if isinstance(hits, int) else len(hits)
        if n:
            v[name] = n
            if sample:
                samples[name] = sample[:4]

    # all modes: the tell catalog
    hard = [w for w in count_phrases(text, VOCAB) if w not in VOCAB_SOFT]
    soft = [w for w in count_phrases(text, VOCAB) if w in VOCAB_SOFT]
    put("vocab", hard, sorted(set(hard)))
    put("vocab_soft(judgment call)", soft, sorted(set(soft)))
    ph = count_phrases(text, PHRASES)
    put("slop_phrase", ph, sorted(set(ph)))
    for name, rx in [("vague_attribution", VAGUE_ATTRIBUTION),
                     ("unearned_significance", SIGNIFICANCE),
                     ("negative_parallelism", NEG_PARALLEL),
                     ("no_x_no_y_just_z", NO_X_NO_Y),
                     ("false_range", FALSE_RANGE),
                     ("tacked_on_analysis", TACKED_ANALYSIS),
                     ("summary_opener", SUMMARY_OPENER)]:
        m = rx.findall(text)
        put(name, len(m), [(" ".join(x) if isinstance(x, tuple) else x).strip()[:60] for x in m])
    dashes = raw.count("—") + raw.count("–")
    per_kw = dashes * 1000.0 / words
    put("em_dash(>2/1000w)", dashes if per_kw > 2 else 0, [f"{dashes} total, {per_kw:.1f}/1000w"])
    put("emoji_header", len(EMOJI_HEADER.findall(raw)))
    put("curly_quote", len(CURLY.findall(raw)))

    if mode in ("plain", "strict"):
        put("semicolon", text.count(";"))
        put("passive_voice", len(PASSIVE.findall(text)))
        put("nominalization", len(NOMINAL.findall(text)))
        put("phrasal_verb", count_phrases(text, PHRASAL))
        cap = 25 if mode == "plain" else 20
        longs = [s for s in sents if wc(s) > cap]
        put(f"long_sentence(>{cap}w)", len(longs), [s[:60] for s in longs])
        paras = [p for p in re.split(r"\n\s*\n", raw) if p.strip()]
        put("long_paragraph(>6s)", sum(1 for p in paras if len(sentences(strip_markup(p))) > 6))

    if mode == "strict":
        put("contraction", len(CONTRACTION.findall(text)))

    total = sum(n for k, n in v.items() if "judgment" not in k)
    return {"mode": mode, "words": words, "sentences": len(sents),
            "violations": v, "samples": samples, "total": total,
            "per100w": round(total * 100.0 / words, 2)}


def main():
    args = sys.argv[1:]
    mode = "plain"
    if args and args[0] == "--mode":
        mode = args[1] if len(args) > 1 else ""
        args = args[2:]
    if mode not in ("voice", "plain", "strict") or not args:
        sys.exit(__doc__)
    for path in args:
        with open(path, encoding="utf-8") as fh:
            r = lint(fh.read(), mode)
        print(f"{path}  mode={r['mode']}  words={r['words']}  "
              f"total={r['total']}  per100w={r['per100w']}")
        for k in sorted(r["violations"], key=lambda k: -r["violations"][k]):
            line = f"  {k:32s} {r['violations'][k]}"
            if k in r["samples"]:
                line += "   e.g. " + "; ".join(str(s) for s in r["samples"][k])
            print(line)


if __name__ == "__main__":
    main()
