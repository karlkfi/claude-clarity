---
name: rendered-page-review
description: >-
  Review a page the way a reader meets it — rendered, at real viewport widths,
  and skimmed rather than read. Use when asked to "review this page", "review
  the landing page", "check the docs site", or "how does this render", and when
  told "this tile is too tall", "these tiles look confusingly similar", "how do
  we stop that wrapping mid-phrase", "the page feels dense", "why is there
  horizontal scroll", or "it breaks on mobile". Also use when editing any page
  a site actually publishes — in a repo carrying mkdocs.yml, Docusaurus, or
  Hugo, every docs/ change is a live page — or a landing page, README, or
  dashboard a reader scans. Two rules do most of the work: probe every instance
  of a defect's class before fixing the reported one, and measure the render
  instead of the source. Requires a browser that can render the page — say so
  if it cannot be served, rather than reviewing the Markdown and calling it a
  page review. Not a prose skill — readability owns structure, deslop owns
  register, code-restraint the CSS diff.
---

# Rendered-page review: the defect is in the render

A page that is skimmed rather than read fails in ways its source cannot show. Nielsen Norman Group's reading research puts the average visitor at 20–28% of a page's words, so the layout is doing most of the communicating — and the layout does not exist until the page is rendered at a width.

Morkes and Nielsen measured what that's worth: concise text improved usability by 58%, scannable layout by 47%, objective language by 27%, and all three together by 124%. Conciseness is the largest single lever, which is why cutting is where a review of a dense page spends most of its rounds.

Two rules do most of the work here. Both are about method, and both are cheap to skip.

## Rule 1 — Sweep the class, not the reported instance

**A reported defect is a sample, not the population.** Before fixing it, enumerate every instance of that component on every page that uses it, and probe all of them in the same pass.

The measured cost of skipping this: one report of a single stat tile being too tall, fixed in isolation. Sweeping the class in that first pass would have surfaced, together:

- a stat band on a second page whose first and third tiles were byte-identical to the landing page's, number and lead text alike
- six consecutive callouts running 94 lines, where the one that mattered — an honest list of where the product loses — was styled exactly like the four routing notes above it
- 24px of horizontal scroll at 768px from a decorative pseudo-element with `inset: -1.5rem -2rem 0`
- `display: flex` on a prose paragraph, which promotes every inline `strong` and `a` to a non-wrapping flex item

They arrived instead as four more rounds of feedback, in whatever order a human happened to scroll past them. That review ran 24 rounds; every one was correct and most were the same defect wearing different clothes. Sweeping collapses it to roughly four.

The sweep has two axes, and both matter: **every instance within the page**, and **every page using the component**. Grep the class name for the page list — that grep is the one thing source reading is good for here.

## Rule 2 — Measure the render, don't read the source

Every defect above was invisible in the Markdown and in the CSS, and obvious in one measurement. The flex bug is the sharpest case: the CSS is four plausible lines, and at 375px it forced the layout viewport to 485px and rendered the words "Not your setup?" as a 52px column three lines tall. No amount of source review finds that.

Neither does CI. Most repos never build the site in their gate — check before assuming a green pipeline says anything about the page.

**If the page cannot be rendered, stop and say so.** Name what you'd need — a dev server command, a built output directory, a URL. A review of the Markdown reported as a page review is worse than no review: it clears the item without looking at the thing.

## Step 1 — Render it at real widths

Serve the page (`preview_start`, or the project's own dev-server target) and drive it with the browser tools. Then walk widths deliberately:

| Width | Why |
|---|---|
| 1440px | Where a laptop reader actually is, and where grid components are widest |
| Each breakpoint, either side | Layout swaps are where components meet copy they were never sized for |
| 320px | WCAG 1.4.10 Reflow: content must work at 320 CSS px — equivalently 1280px at 400% zoom — with no two-dimensional scrolling |

Two traps, both of which produce a confident wrong answer:

- **Resize the viewport for `vw`, the container for `@container`.** An element sized in `vw` ignores its parent, so only a real viewport change moves it — use `resize_window`, and reload after switching so load-time device gates re-run. A component under a container query is the mirror image: its container's width is the input, and a viewport sweep can miss its breakpoint entirely. One card dropped into a three-column grid, a sidebar, and a full-width hero is three different renders at a single viewport width, which is why the sweep in Rule 1 has to cover every context and not only every page.
- **Measure text with a `Range` over the real node.** Building a probe span from `getComputedStyle(el).font` under-reported one string by 40% — 256px against the real render's 416px, which is the whole distance between "fits on one line" and "wraps".

For a README, the render that counts is GitHub's, not a local Markdown preview: a fixed content column, its own alert and table styling, and no project CSS at all.

## Step 2 — Run the probe set

Six probes, through `javascript_tool`. Most return `[]` or `0` on a clean page, so a sweep across ten instances is a list of numbers rather than ten judgement calls. Replace the selectors with the component under review.

**Wrap every run, and wait for the fonts.** `getBoundingClientRect` and `Range` both report the fallback face while a webfont is still loading — the same class of confident wrong number as the `getComputedStyle` trap above. Two mechanical points come with that: the console scope persists between calls, so a bare top-level `const` throws on the second run, which is what a sweep is; and top-level `await` is a syntax error there. Both are solved by the same wrapper:

```js
(async () => {
  await document.fonts.ready;
  return document.documentElement.scrollWidth
       - document.documentElement.clientWidth;   // probe 1
})()
```

Some engines resolve `document.fonts.ready` early, so re-run any surprising measurement rather than trusting a single read. Each probe below is a body for that wrapper — put `return` in front of its final expression, and its `const` declarations become function-scoped, which is what makes the second run work.

```js
// 1. horizontal overflow at this width
document.documentElement.scrollWidth - document.documentElement.clientWidth;

// 2. which element owns it — hide each child, watch the number drop.
//    Re-run with the culprit as root to drill into it.
const root = document.querySelector('main, article') || document.body;
[...root.children].map(el => {
  const before = document.documentElement.scrollWidth;
  const saved = el.style.display;
  el.style.display = 'none';
  const drop = before - document.documentElement.scrollWidth;
  el.style.display = saved;
  return drop > 0 ? [el.className || el.tagName, drop] : null;
}).filter(Boolean);

// 3. items that wrap in a grid built for scanning
[...document.querySelectorAll('.card li')].filter(el =>
  el.getBoundingClientRect().height /
  parseFloat(getComputedStyle(el).lineHeight) > 1.5
).map(el => el.innerText.trim());

// 4. dead space per tile in a height-equalised row
const tiles = [...document.querySelectorAll('.stat')];
const tallest = Math.max(...tiles.map(t => t.getBoundingClientRect().height));
tiles.map(t => [
  t.innerText.split('\n')[0],
  Math.round(tallest - (t.lastElementChild.getBoundingClientRect().bottom
                        - t.getBoundingClientRect().top)),
]);

// 5. a phrase that must hold one line — every entry must be 1
[...document.querySelectorAll('.nowrap-phrase')].map(el => {
  const r = document.createRange();
  r.selectNodeContents(el);
  return r.getClientRects().length;
});

// 6. does the layout survive the reader's own text spacing (WCAG 1.4.12)?
const spacing = document.createElement('style');
spacing.textContent = `*, *::before, *::after {
  line-height: 1.5 !important;
  letter-spacing: 0.12em !important;
  word-spacing: 0.16em !important; }
  p { margin-bottom: 2em !important; }`;
document.head.append(spacing);
// re-run probes 1 and 3, then: spacing.remove();
```

Probe 4 is the exception, because it reports a constant floor: each tile's own bottom padding and border. Read the **spread** across the row rather than the absolute. A balanced row returns the same number for every tile; a row with one oversized label returns 81px beside its neighbour's 9px.

Probe 2 is the scripted form of the standard DevTools move — delete nodes until the scrollbar disappears, then undo. Scripting it names the element in one pass, at every width, without hand-deleting anything, which is what makes it sweepable. Prefer it to `* { outline: 1px solid red }`: the outline trick draws you a picture and still leaves you hunting for the element.

## Step 3 — Judge what the probes cannot

Six rules. A probe can measure the damage in the first one; none of them decides any of the six.

**In an equalised row, the longest sibling sets the height and the short ones pay in whitespace.** This is the failure its author never sees: their own tile looks fine and the damage lands on the neighbours. Measured on one four-across grid at 1440px, tiles about 306px wide:

| | Longest label | Row height | Worst dead space |
|---|---|---|---|
| Healthy | 120 chars | 189px | 45px |
| Broken | 302 chars | 298px | ~200px |

Keep siblings in a row within about 35 characters of each other. **Derive the character budget for the site under review — do not import those numbers**, which describe one column width in one type face. Probe 4 measures the imbalance on the actual grid, and probe 3 finds the width where the copy starts wrapping; a budget is what those two produce together.

Leave slack in it rather than calibrating to the edge. WCAG 1.4.12 entitles a reader to impose their own line height and letter, word, and paragraph spacing with nothing clipped or overlapped, so a row that exactly fits at its budget is a row that breaks for everyone who exercises that right. Measured on a fixture built to sit just inside its column: applying those four values wrapped two bullets that had been single-line, grew the row from 98px to 122px, and opened a 24px spread in dead space where there had been none. Every other probe passed that page. Probe 6 is the check.

A label that wants more than the budget is making an argument, and an argument belongs in prose or a table rather than in something whose whole job is to be glanced at.

**An emphasis device works only while it is scarce.** Six identical callouts in a row are zero callouts: the important one stops looking different, which is the entire function it was there for. Most style guides say this about bold and stop; it is true of every device — callouts, tinted panels, oversized numbers, icons. Budget roughly one per screen and promote the rest to headings of their own.

Google's developer documentation style guide sets the same rule as policy, and goes further than a budget: minimise notices, because several on one page cost them their distinctiveness, and avoid grouping two or more together at all. It also supplies the better test — **write the thing as ordinary text first, then decide whether it needs to be a notice**. Applied while drafting, that answers the question before a wall can form, and most of the time the plain sentence turns out to have been the answer.

**A shared component must not say the same thing on two pages.** Two tiles matching verbatim across a landing page and a comparison page made the second read as a repeat of the first. Fix it by deletion rather than rewording when the neighbouring blocks already carry the argument — rewording keeps the redundancy and adds new words to maintain.

**Ask whether the block belongs on this page at all.** Three questions: does *this* page's reader need it, does it belong on another page, and what audience wants it and where would they look for it. Applied once, this deleted a 424-word section that was 22% of a page's height and whose four comparison points were already rows in the table directly above it — and lost nothing, because two other pages already served the reader who wanted it.

**Never restate in prose what a diagram or table already carries.** Prose beside a visual is the visual admitting it did not work. One section opened with 139 words naming three capabilities and four outcomes, directly above a flow diagram whose nodes said exactly that; a nine-word lead-in replaced both paragraphs.

**State the invariant, not an instance.** "Listener footprint for 10 runner sets" invites the question the number cannot answer, because nothing justifies ten. The claim underneath was a ratio — one always-on pod per set against one shared pod whatever the count — which is shorter and stronger. A number earns its place when it is a measurement or a declared scenario parameter; it is noise when it is an illustration.

## What to mechanize, and what not to

Three checks survive being turned into a gate, and the cheapest is the one that gets skipped: **no horizontal overflow at 320px**. Load the page at that width in a browser-driving test and assert `scrollWidth <= clientWidth` — about three lines of Playwright, and it is WCAG 1.4.10 conformance rather than a house preference, so it earns its place even where nobody has an opinion about tile heights.

The other two are countable in the source: **callout run length** and **a component carrying identical content on two pages**. Both fail loudly, and neither needs to know what the page is for.

Calibrate the run-length threshold against the tree instead of guessing. In the repo this came from, the wall was six deep; with it removed, the longest surviving run anywhere was 2, so the gate went in at 3 — headroom over everything that exists, still red on the run that prompted it.

The rest need a reader. Whether a block belongs on this page, whether prose duplicates the diagram under it, whether a number is a measurement or an illustration, and whether a row's labels are balanced are all judgements about what the page is for, and a gate that guesses at them gets switched off.

## Where this sits

Prose skills own the words; this one owns what the browser does with them. `readability` owns reading order and whether a non-author can follow the argument, `deslop` owns register and vocabulary, a personal voice skill owns voice, `tech-docs-layers` owns which doc a thing lives in, and `code-restraint` owns the CSS and template diff you write at the end. Rules here that touch copy — the density budgets, the invariant rule — are layout constraints on copy, not style advice, and they yield to those skills anywhere the two collide.

Two adjacent tools that do not replace this:

- **Visual regression testing** (Playwright's `toHaveScreenshot`, Percy, BackstopJS) answers "did this change?" against a baseline. It says nothing about a first render, which has no baseline, and a diff never names the element that owns an overflow. Worth having; not a substitute for a probe.
- **Accessibility linters** (axe-core and friends) catch contrast, labels, and roles, and should be run — but not for this. axe-core carries no reflow or overflow rule at all, and its single Text Spacing rule, `avoid-inline-spacing`, checks whether inline `style` attributes block a reader's override rather than whether the layout survives one. The two criteria closest to this skill are precisely the two it cannot see, which is why probes 1 and 6 exist.
- **Core Web Vitals**, layout shift especially (good is 0.1 or less at the 75th percentile), covers a rendered-page defect this skill does not: content moving after paint. It is measured in the field across real sessions with its own tooling, so treat it as a neighbour rather than a probe. A page can score perfectly on it and still be the wall of six callouts.

## Sources

The method and every measurement in it come from a 2026-08 review of the marketing pages in `actions-gateway/github-actions-gateway`, where 24 rounds of feedback collapsed into four causes; the repo-local half of it lives in that repo's `documentation-standards.md`, `website.md`, and `scripts/docs/check-page-density.sh`.

The probes were run against three fixtures: one carrying every defect above, one clean, and one calibrated to sit just inside its column. Each names the defect on the first and returns `[]` or `0` on the second, except probe 4, whose clean run is a flat column rather than a zero, and probe 6, which reports by making the others fire — on the third fixture only, which is the case it exists for. The spacing injection was checked against a positive control before being trusted on a negative one: it moves `letter-spacing` from `normal` to `1.92px` and widens the same string by 31%.

Public practice supplied the rest, including three things the original review got wrong or lacked:

- [WCAG 2.2 SC 1.4.10 Reflow](https://www.w3.org/WAI/WCAG22/Understanding/reflow.html) — the 320px target (equivalently 1280px at 400% zoom), in place of a guessed phone width.
- [WCAG 2.2 SC 1.4.12 Text Spacing](https://www.w3.org/WAI/WCAG22/Understanding/text-spacing.html) — probe 6's four values, and the argument for slack in a density budget.
- [Google's developer documentation style guide on notices](https://developers.google.com/style/notices) — the emphasis rule as published policy, plus the write-it-plain-first test, which beats a per-screen budget.
- [Morkes and Nielsen 1997](https://www.nngroup.com/articles/concise-scannable-and-objective-how-to-write-for-the-web/) and NN/g's [F-shaped-pattern research](https://www.nngroup.com/articles/f-shaped-pattern-reading-web-content/) — the scanning premise, the 20–28% figure, and the measured payoff of cutting.
- [CSS-Tricks on unintended body overflow](https://css-tricks.com/findingfixing-unintended-body-overflow/) — the delete-until-the-scrollbar-goes technique that probe 2 automates.
- [axe-core's rule list](https://github.com/dequelabs/axe-core/blob/develop/doc/rule-descriptions.md) — checked directly rather than assumed, to establish that it has no reflow rule and only a partial Text Spacing one.

Container queries and `document.fonts.ready` corrected two rules that shipped wrong: a viewport sweep alone misses a container-queried component's breakpoints, and any text measurement taken before the webfont lands measures the fallback face.
