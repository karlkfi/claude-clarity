# Provider status pages

The lookup table behind one rule in `verify-claims` §1: when a remote read fails, returns empty, or
comes back red, the provider's own status page says whether the instrument was sick at read time.
GitHub is the example in the skill because it is the one most of this work runs through, but
the rule is about any hosted dependency — a registry, a CDN, a CI service, an API you call.

Everything below was read on 2026-08-17.

## Read components, not the blended indicator

The one-line summary a status page leads with is a blend across the whole platform, and the blend is
the reading that cannot settle the question the rule asks. Measured at 16:36 UTC on 2026-08-17,
GitHub's summary said `"indicator":"major"`, `"Partial System Outage"` — one verdict for everything.
Its component list at the same moment:

| Status | Components |
|---|---|
| `major_outage` | API Requests, Issues, Pull Requests, Actions, Copilot |
| `degraded_performance` | Git Operations, Webhooks, Pages |
| `operational` | Packages, Codespaces |

"Partial System Outage" cannot tell you that `git push` should work while `gh pr create` may not, and
that split is the entire content of the rule. A component read wrong in either direction costs you:
treat a healthy component as degraded and you dismiss a real local fault, treat a degraded one as
healthy and you chase a finding the platform invented.

Statuspage-hosted pages expose the split as JSON on the page's own hostname, no auth:

| Path | Answers |
|---|---|
| `/api/v2/status.json` | the blended indicator — `none`, `minor`, `major`, `critical` |
| `/api/v2/components.json` | per component — `operational`, `degraded_performance`, `partial_outage`, `major_outage` |
| `/api/v2/summary.json` | both of those plus unresolved incidents and scheduled maintenance |

`components.json` is the one to reach for. `status.json` is the cheaper read and answers a question
you did not ask.

## Verified pages

| Provider | Page | Software | Machine read |
|---|---|---|---|
| GitHub | `https://www.githubstatus.com` | Statuspage | `/api/v2/components.json` |
| npm | `https://status.npmjs.org` | Statuspage | `/api/v2/components.json` |
| PyPI | `https://status.python.org` (page name "Python Infrastructure") | Statuspage | `/api/v2/components.json` |
| Cloudflare | `https://www.cloudflarestatus.com` | Statuspage | `/api/v2/components.json` |
| Claude / Anthropic | `https://status.claude.com` | Statuspage | `/api/v2/components.json` |
| GitLab | `https://status.gitlab.com` | Status.io | none — `/api/v2/*` 404s; RSS only |
| Docker | `https://www.dockerstatus.com` | Status.io | none — RSS only |

## Finding one that is not listed

1. **Try both naming conventions.** Providers split about evenly between `status.<domain>` (npm,
   PyPI, GitLab) and `<product>status.com` (GitHub, Cloudflare, Docker). Neither is standard, so
   failing to find one under the first is not evidence there is no page.
2. **Append `/api/v2/status.json`.** It answers on any Statuspage-hosted page, which is five of the
   seven above. A 404 there means the page is not Statuspage-hosted — not that you have the wrong
   page. GitLab and Docker both run Status.io, publish a real status page, and 404 on that path.
3. **Follow the redirect, and check what it kept.** Status hostnames move, so a URL written down
   months ago rots quietly: `status.anthropic.com` 301s to `status.claude.com`. Worse,
   `status.docker.com/api/v2/status.json` 301s to `dockerstatus.com/` — the redirect drops the path,
   so the response is a 200 carrying HTML and anything expecting JSON gets a web page instead of an
   error.
4. **Prefer the provider's page to a crowd-sourced aggregator.** Downdetector and its kin measure
   user reports, which is a different instrument answering a different question: it lags on a
   component outage narrow enough that few people hit it, and it spikes on things that are not
   outages. Reach for one only when the provider's own page is what you cannot reach.

## An all-green page is weaker evidence than a red one

A posted incident is the provider stating a fact about itself. All-green is the absence of a
statement, and it goes weak in two unrelated ways.

**Posting lags detection.** That is precisely the excuse that produced the over-attribution the
skill records: the page had API Requests and Actions at roughly a 20% error rate and Git
Operations `operational`, and that contradiction was explained away as reporting lag while the
real cause sat locally. What settles it is not re-reading the page. It is spending the cheap local
check that the two explanations disagree about: `ssh-add -l` costs a second and separates "my key
is not loaded" from "the page is behind". Reach for lag only once that check comes back clean, and
treat a page that contradicts your theory as a finding until it does.

That git message — `Please make sure you have the correct access rights and the repository
exists` — has one very common local cause, and it is not one to work around: the key is not
loaded in the agent, which is the usual way an SSH credential "expires" after a reboot. Loading it
needs a passphrase only the user can type, so say what failed and ask them to run `ssh-add`,
rather than reaching for HTTPS, a deploy key, or a token. Every one of those either fails the same
way or puts you in contact with a credential you should not be handling.

**A component returns to `operational` while the failures are still arriving.** The table above is
that same incident at its peak. Later on 2026-08-17, with the incident winding down,
`components.json` reported every component except Copilot `operational` — and the GraphQL API was
returning HTTP 503 with write paths still failing. Two sessions read it that way independently
inside one hour, so this is not one session misreading a field. Re-reading is not the fix here, and
neither is the local check above, because this time the fault genuinely was remote: what separated
the states was a different endpoint on the same data, the REST pulls endpoint answering where
GraphQL 503'd.

The two modes combine into an ordering. The page belongs at the *start* of an investigation,
where red on your component can stop one before you spend it. It cannot go at the end, because green
would have to close the question, and green is what the tail of an incident looks like.
