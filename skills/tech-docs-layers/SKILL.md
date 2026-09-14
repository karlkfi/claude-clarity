---
name: tech-docs-layers
description: Apply the six-layer model of technical documentation when writing, editing, or restructuring docs in a git repository. Use this skill when the user asks to add a doc page, restructure the docs, draft a tutorial or how-to, write a README, or update an existing doc; and when they say a docs page "is a mess", "is a giant wall of text", "keeps getting stale", or "doesn't link to docs pages enough". The skill applies even when the request sounds small, since an edit framed as a quick text change still touches terminology, cross-references, versioning, metadata, navigation, and reusable blocks, all of which need to stay coherent. Scope is repo-resident user-facing documentation wherever it lives — docs/, doc/, website/, site/, content/, mkdocs/, sphinx/, and the *.md, *.mdx, and *.rst files under them. Do not trigger for code comments, ADRs unrelated to user-facing docs, or marketing copy outside a docs tree.
---

# Tech writing: the six layers under the prose

Adapted from a model popularized by Technical Writer HQ. The names of the six layers are theirs; the operational guidance below is repo-specific and developed for this skill.

A technical document's visible text rests on six invisible layers that the writer maintains. When any of those layers slips, the prose still looks fine — but search returns junk, links rot, the wrong instructions reach the wrong version of the product, and an edit framed as small silently breaks pages you never opened. This skill keeps the layers coherent.

## How to use this skill

Before editing or creating a doc, scan the repo to understand what already exists at each layer. While writing, apply the six checks below. After writing, sweep the layers for collateral damage. Most repo docs work fails at sweep-time, not draft-time — so do not skip step 3.

### Step 1 — Survey the docs system

Spend a few tool calls building a map before changing anything:

- Locate the docs root (`docs/`, `doc/`, `website/`, `site/`, `content/`, top-level `*.md`).
- Identify the doc framework if any: MkDocs (`mkdocs.yml`), Sphinx (`conf.py`), Docusaurus (`docusaurus.config.*`), Hugo (`config.*` + `content/`), Jekyll (`_config.yml`), Antora, Starlight, VitePress, plain Markdown, or RST.
- Find the glossary or terminology source if one exists (`glossary.md`, `terms.md`, a `_glossary/` directory, or a "Terminology" heading).
- Find any reusable include mechanism the framework supports (Sphinx `.. include::`, MkDocs `pymdownx.snippets`, Docusaurus MDX imports, Hugo `partials`, Antora partials, Jekyll includes).
- Note how navigation is declared (`mkdocs.yml` nav, Sphinx `toctree`, Docusaurus `sidebars.js`, `_category_.json`, Hugo front matter `weight`).
- Note how versioning is handled if at all (separate `versioned_docs/`, branch-per-version, ifdef-style directives, MyST `{only}`, MkDocs `mike`).
- Note the metadata convention: front matter keys actually in use across existing pages (title, description, tags, audience, product, sidebar_position, weight, etc.).

This survey is the work. Skipping it is why doc PRs ship with broken links and inconsistent vocabulary.

### Step 2 — Write with the six layers in mind

Apply each layer as you draft. Each layer has a *what to do* and a *why it matters* — the why is what tells you how to handle the edge cases.

#### Layer 1 — Terminology consistency

What to do: Use the same term for the same thing on every page. Before introducing a noun for a product concept, search the repo for existing usages (`rg -i "term"`) and the glossary. If a glossary exists, defer to it; if not, pick the term used most consistently in user-facing docs and stick with it. If you are renaming a term, do it across the doc set in one change, not just on the page you happen to be editing — a per-page sed without checking inflections and plurals will leave inconsistencies behind.

Why it matters: Mixed terms ("workspace" on one page, "project" on the next, "tenant" in the API ref) make readers think they are three different things. The glossary is the contract that prevents that, but only if every page honors it.

#### Layer 2 — Cross-reference architecture

What to do: When a procedure has prerequisites or downstream steps that live on other pages, link to them. Prefer the framework's first-class cross-reference syntax (`{doc}` in MyST, `:ref:` in Sphinx, relative `.md` links in MkDocs/Docusaurus, `ref` shortcodes in Hugo) over hand-written URLs, because the framework can then warn on broken refs. When you move or rename a page, search the repo for inbound links and update them — `rg "old-page-name"` and `rg "old/path"` both matter.

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

### Step 3 — Sweep for collateral damage

After the draft is in place, do a sweep. This is where most doc PRs fall short.

- **Terminology sweep:** `rg -i "any-new-or-renamed-term"` and confirm every hit is consistent with the chosen term and the glossary.
- **Link sweep:** for every page you renamed or moved, `rg "old-slug"` and `rg "old/path"` and fix inbound links. Then run the framework's link checker if available (`mkdocs build --strict`, `sphinx-build -n -W`, `docusaurus build`, `hugo --printPathWarnings`).
- **Version sweep:** if the change applies to multiple versions, confirm it landed in each. If versioned docs use snapshots, the snapshot for the current version often needs to be updated separately from the next-version source.
- **Metadata sweep:** open the page in the rendered site or use the framework's build output to confirm the description, tags, and sidebar position behave as intended.
- **Navigation sweep:** look at the rendered sidebar — is the page where you expected? Are heading levels producing a sensible in-page TOC?
- **Partial sweep:** if you updated a reusable block, list every page that includes it (`rg "include.*snippet-name"` or framework-specific) and skim the rendered output of at least one to confirm the substitution did what you wanted.

### Step 4 — Commit hygiene

Doc PRs are reviewed differently from code PRs. To make review possible:

- Keep terminology renames in their own commit, separate from prose edits, so the reviewer can see the rename in one diff.
- Keep navigation changes (`mkdocs.yml`, `sidebars.js`) in the same commit as the page move that requires them — never split them.
- In the commit message, name which layers the change touches if more than one. "Move install guide under Getting Started; updates sidebars.js and 4 inbound links." tells the reviewer where to look.
- If the framework's build is part of CI, run it locally before committing. A broken doc build is a wasted CI cycle and a slow review.

## Anti-patterns to avoid

These are the failure modes that the six-layer model exists to prevent. If you catch yourself doing any of them, stop and reread the relevant layer.

- Editing one page's terminology without searching the rest of the doc set, leaving the same concept named two different ways in neighboring pages (Layer 1).
- Renaming a page and only updating the nav, not inbound links from other pages (Layer 2).
- Writing instructions that read as universal when they only apply to one product version (Layer 3).
- Inventing a new tag or front matter key when the repo already has a convention (Layer 4).
- Dropping a new page into the navigation wherever there happens to be a gap, instead of where the reader would look (Layer 5).
- Pasting a "Prerequisites" block instead of referencing the shared partial (Layer 6).
- Treating a doc change as "just a text change" without doing the sweep in step 3.

## A note on scope

The six-layer model applies to repo-resident user-facing documentation: tutorials, how-tos, references, conceptual guides, READMEs that the public reads. It is less relevant to in-code comments, ADRs about internal architecture decisions, or marketing copy that lives outside the docs tree. When the user asks for those, follow the request without forcing the six-layer frame on it.

A doc page is the surface of a system. Edit the surface, but maintain the system.
