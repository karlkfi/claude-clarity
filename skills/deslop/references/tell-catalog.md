# deslop word and phrase lists

The vocabulary and stock phrases that marked machine text in earlier model
generations. Current Claude models rarely produce them, so they no longer sit in
the skill body. `scripts/deslop-lint.py` still flags every entry, and
`scripts/test-catalog-sync.sh` checks it does, so read this file when linting a
draft from an unknown or older source.

Vocabulary (replace on sight, all modes): delve, tapestry, landscape (metaphorical), realm, beacon, journey (metaphorical), symphony, intricate, pivotal, crucial, vital, seamless, robust, leverage, foster, empower, unlock, unleash, elevate, streamline, supercharge, game-changing, cutting-edge, state-of-the-art, best-in-class, battle-tested, enterprise-grade, transformative, revolutionary, comprehensive, multifaceted, myriad, plethora, ever-evolving, fast-paced, synergy, paradigm shift, demystify, holistic, groundbreaking.

Phrases (delete or rewrite): "it's important to note", "it should be noted", "it's worth noting", "in today's digital age", "in the ever-evolving world of", "let's dive in", "at its core", "at the end of the day", "in conclusion", "in summary", "in essence", "ultimately" as a paragraph opener, "no discussion would be complete without", "but here's the kicker", "that's only half the story", "here's the truth", "I hope this helps", "let me know if", "great question".

Em dashes: one or two per page is punctuation; several per paragraph is a
signature. Replace with commas, periods, colons, or parentheses.
