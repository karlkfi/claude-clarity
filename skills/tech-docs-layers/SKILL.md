---
name: tech-docs-layers
description: Apply the six-layer model of technical documentation when writing, editing, or restructuring docs in a git repository. Use this skill when the user asks to add a doc page, restructure the docs, draft a tutorial or how-to, write a README, or update an existing doc; and when they say a docs page "is a mess", "is a giant wall of text", "keeps getting stale", or "doesn't link to docs pages enough". The skill applies even when the request sounds small, since an edit framed as a quick text change still touches terminology, cross-references, versioning, metadata, navigation, and reusable blocks, all of which need to stay coherent. Scope is repo-resident user-facing documentation wherever it lives — docs/, doc/, website/, site/, content/, mkdocs/, sphinx/, and the *.md, *.mdx, and *.rst files under them. Do not trigger for code comments, ADRs unrelated to user-facing docs, or marketing copy outside a docs tree.
---

# Tech writing: the six layers under the prose

Adapted from a model popularized by Technical Writer HQ. The names of the six layers are theirs; the operational guidance below is repo-specific and developed for this skill.

A technical document's visible text rests on six invisible layers that the writer maintains. When any of those layers slips, the prose still looks fine — but search returns junk, links rot, the wrong instructions reach the wrong version of the product, and an edit framed as small silently breaks pages you never opened. This skill keeps the layers coherent.

## How to use this skill

Every docs edit starts at the same question: **does this repo already have docs conventions of its own?** If it does, defer to them and sweep. If it does not, make the edit, sweep, and then write the repo its conventions (Step 5). Both modes run Steps 2 to 4.

### Step 1 — Find the repo's own conventions

Look where a session would actually be sent, not only where a page might sit:

- The loaded `CLAUDE.md`, `AGENTS.md`, or `CONTRIBUTING.md`: does it route docs work anywhere — "update docs after a change", "when editing docs, read X"?
- A standards or style page under the docs tree: `documentation-standards.md`, `style-guide.md`, `writing-docs.md`, a `docs/development/` or `docs/contributing/` directory.
- A change-to-docs mapping: a table or list saying which pages a given kind of code change has to update.
- Docs gates: a link checker, TOC check, or strict docs build in the `Makefile`, `package.json` scripts, or CI workflows.

A routing line in a loaded file, a standards page, or a mapping counts as conventions. Gates alone do not: they enforce a rule without saying what the rule is for, so a session still has the choices to make.

**With conventions, read them in full before editing.** They were written for this repo by someone who knew it, so follow them where they speak, including where they disagree with a layer below; where they are silent, apply the layer. Run every docs gate they name before committing. A rule you think the local page has wrong is a finding to raise with the user, not one to override in the diff.

**With none, do the edit the user asked for first**, through Steps 2 to 4. The conventions come after, in Step 5, so a small request is never held hostage to a large one. Without them, every docs edit re-derives the same choices, and the next session derives them differently.

### Step 2 — Survey the docs system

Spend a few tool calls building a map before changing anything. Where Step 1 found conventions, they may already answer most of this; survey what they leave out.

- Locate the docs root (`docs/`, `doc/`, `website/`, `site/`, `content/`, top-level `*.md`).
- Identify the doc framework if any: MkDocs (`mkdocs.yml`), Sphinx (`conf.py`), Docusaurus (`docusaurus.config.*`), Hugo (`config.*` + `content/`), Jekyll (`_config.yml`), Antora, Starlight, VitePress, plain Markdown, or RST.
- Find the glossary or terminology source if one exists (`glossary.md`, `terms.md`, a `_glossary/` directory, or a "Terminology" heading).
- Find any reusable include mechanism the framework supports (Sphinx `.. include::`, MkDocs `pymdownx.snippets`, Docusaurus MDX imports, Hugo `partials`, Antora partials, Jekyll includes).
- Note how navigation is declared (`mkdocs.yml` nav, Sphinx `toctree`, Docusaurus `sidebars.js`, `_category_.json`, Hugo front matter `weight`).
- Note how versioning is handled if at all (separate `versioned_docs/`, branch-per-version, ifdef-style directives, MyST `{only}`, MkDocs `mike`).
- Note the metadata convention: front matter keys actually in use across existing pages (title, description, tags, audience, product, sidebar_position, weight, etc.).

This survey is the work. Skipping it is why doc PRs ship with broken links and inconsistent vocabulary.

### Step 3 — Write with the six layers in mind

Apply each layer as you draft. Each layer has a *what to do* and a *why it matters* — the why is what tells you how to handle the edge cases. A layer whose mechanism the survey did not find (no framework, no versions, no partials) has nothing to maintain; skip it rather than introducing the mechanism unasked.

#### Layer 1 — Terminology consistency

What to do: Use the same term for the same thing on every page. Before introducing a noun for a product concept, search the repo for existing usages (`rg -i "term"`) and the glossary. If a glossary exists, defer to it; if not, pick the term used most consistently in user-facing docs and stick with it. If you are renaming a term, do it across the doc set in one change, not just on the page you happen to be editing — a per-page sed without checking inflections and plurals will leave inconsistencies behind.

A search for the old term finds only the sentences that name it. Read the pages it hits for two more kinds: a sentence that describes the concept without naming it ("the step that blocks a second merge"), which should usually gain the name, and a bare back-reference ("the check", "this mode") whose antecedent the rename moved. Neither contains the term, so no grep reaches them.

Why it matters: Mixed terms ("workspace" on one page, "project" on the next, "tenant" in the API ref) make readers think they are three different things. The glossary is the contract that prevents that, but only if every page honors it.

#### Layer 2 — Cross-reference architecture

What to do: When a procedure has prerequisites or downstream steps that live on other pages, link to them. Prefer the framework's first-class cross-reference syntax (`{doc}` in MyST, `:ref:` in Sphinx, relative `.md` links in MkDocs/Docusaurus, `ref` shortcodes in Hugo) over hand-written URLs, because the framework can then warn on broken refs. When you move or rename a page, search the repo for inbound links and update them — `rg "old-page-name"` and `rg "old/path"` both matter. A moved page's own relative links break too, so rewrite its outbound links as well.

Why it matters: A doc set is a graph, not a list of pages. Broken cross-references are usually invisible in the prose — the page still renders — but the reader's path breaks. Most doc CI is too permissive about this; assume the link checker is not catching everything and verify manually for any page you move.

#### Layer 3 — Version and conditional logic

What to do: Determine which product version(s) a page applies to before writing. If the repo uses versioned docs (e.g., `versioned_docs/version-3.1/`), edit the right version — usually current/next, and sometimes a backport. If the repo uses inline conditionals (MyST `{only}`, RST `.. only::`, Docusaurus `<Tabs>` per version, MDX components, Liquid `{% if %}`), use the existing pattern rather than inventing a new one. Do not silently change behavior described as available "since vX" without checking whether that claim is still accurate.

Why it matters: A reader on v3.1 who follows v4.0 instructions has a worse experience than no docs at all — they will blame the product for breaking their workflow. The doc must know which reality it is describing.

#### Layer 4 — Metadata and taxonomy

What to do: Match the front matter shape used by neighboring pages exactly. If sibling pages have `title`, `description`, `tags`, `audience`, `product`, and `sidebar_position`, the new page has all six. Pick tag values from the existing tag vocabulary in the repo, not freshly invented ones — `rg "^tags:" -A 5` across the docs tree reveals the actual taxonomy. Write the `description` as a real one-line summary, because that is what surfaces in search results and social previews.

Why it matters: Metadata determines whether the page is findable. A page with no description ranks badly in site search; a page with a freshly invented tag fragments the tag taxonomy and makes filters less useful for everyone.

#### Layer 5 — Navigation and information hierarchy

What to do: Place the page where a reader trying to solve the problem would expect to find it, not where it was easiest to drop in. Update the navigation manifest (`mkdocs.yml` `nav:`, `sidebars.js`, `_category_.json`, Sphinx `toctree`, Hugo `weight`) when adding or moving a page. Match heading depth to the surrounding section — if every sibling page uses `#` for the page title and `##` for major sections, do the same. Use sentence case or title case consistently with the rest of the doc set, not your personal preference.

Why it matters: The table of contents is a decision tree the reader uses to navigate without reading. If the new page is in the wrong branch, readers reach it by search-luck only, and search-luck is a bad UX. Heading levels feed the auto-generated TOC inside the page; mismatched levels produce a TOC that misrepresents the structure.

#### Layer 6 — Reusable content blocks

What to do: Before writing a warning, a prerequisite list, an install snippet, or a parameter table that probably appears on other pages, search for an existing reusable block (`includes/`, `_partials/`, `_snippets/`, `shared/`, MDX components in `src/components/`, Sphinx `.. include::` targets). If one exists, reuse it. If a block is duplicated across three or more pages, factor it out into a partial during this change (and only if the framework supports partials cleanly). Update the partial in one place; the pages pick it up.

Why it matters: Copy-paste warnings and install snippets drift apart over time. Within six months, three versions of "Prerequisites" disagree about whether Node 18 is required. The reusable block is the source of truth that prevents drift, but only if writers actually reach for it instead of pasting.

### Step 4 — Sweep for collateral damage, and commit

After the draft is in place, sweep. Where the repo has docs gates, run them; the bullets cover what a gate cannot reach.

- **Terminology:** `rg -i "any-new-or-renamed-term"` and confirm every hit matches the chosen term and the glossary, then do Layer 1's read for unnamed descriptions and back-references.
- **Links:** for every page you renamed or moved, `rg "old-slug"` and `rg "old/path"`, fix inbound links, and check the moved page's outbound ones. Then run the framework's link checker if available (`mkdocs build --strict`, `sphinx-build -n -W`, `docusaurus build`, `hugo --printPathWarnings`).
- **Versions:** if the change applies to multiple versions, confirm it landed in each. A versioned snapshot often needs updating separately from the next-version source.
- **Metadata and navigation:** check the rendered site or build output — description, tags, sidebar position, and an in-page TOC that matches the heading levels.
- **Partials:** if you updated a reusable block, list every page that includes it (`rg "include.*snippet-name"`) and check the rendered output of at least one.

Commit so a reviewer can follow the layers. Keep a terminology rename in its own commit, separate from prose edits. Keep a navigation change in the same commit as the page move that requires it. Name the layers in the message when more than one is touched: "Move install guide under Getting Started; updates sidebars.js and 4 inbound links."

### Step 5 — Write the repo its conventions (only where Step 1 found none)

Once the requested edit is committed, write what the next docs edit should have found. This step is usually larger than the edit that triggered it, so ask the user before starting when the request was small. Write three things, each from what the survey and the edit just showed you rather than from general advice:

- **A change-to-docs mapping.** A table from kinds of change in this repo (a new flag, a new config key, a renamed command, a new failure mode) to the pages each one has to update. Derive the rows from the docs tree and from the edit you just made, because a row naming a page that does not exist is the first thing a reader stops trusting.
- **A standards page.** Record the choices pages already make: the term chosen for each product concept, the link style, heading case, front matter keys, where new pages go. A page recording what the docs already do is checkable against them; a page of aspirations nobody follows gets ignored, and then everything on it does.
- **Gate proposals.** List the sweep checks that must hold on every change — inbound links resolve, a retired term stays retired — with the command that would enforce each, and propose them in the PR body or a backlog item rather than wiring them into CI unasked. A rule that must hold every time cannot hold in prose, and adding CI is a decision for the maintainer.

Put the pages where the repo keeps contributor docs, conventionally `docs/development/`, and **add a line to the repo's `CLAUDE.md` (or `AGENTS.md`) naming them at the moment they apply** — "before editing anything under `docs/`, read `docs/development/documentation-standards.md`". A page nothing loads is never read, however good it is. Once the line lands, the next docs edit meets Step 1's first mode.

## A note on scope

The six-layer model applies to repo-resident user-facing documentation: tutorials, how-tos, references, conceptual guides, READMEs that the public reads. It is less relevant to in-code comments, ADRs about internal architecture decisions, or marketing copy that lives outside the docs tree. When the user asks for those, follow the request without forcing the six-layer frame on it.

A doc page is the surface of a system. Edit the surface, but maintain the system.

## Sources

Why the skill branches on local conventions, and what measured the layer 1 guidance, is in this repo's `docs/decisions.md`, under the `tech-docs-layers` entry.
