# Heediq Workspace — Claude Rules (root)

This is the **single contract** for how Claude works on Heediq. It is version-controlled in
`heediq-workspace` and pulled by every developer, so the team accumulates one shared memory and one
set of rules. Launch Claude from the workspace root so this file (and everything it imports) always
loads.

Heediq is a B2B SaaS meeting-recording & transcription platform: record → transcribe → extract
structured requirements / decisions / open questions → push to Jira/Confluence. AWS serverless
(Lambda, Fargate Spot, SQS, DynamoDB), React frontend, AWS CDK + GitHub Actions.

---

## How this repo is laid out

Repo: **github.com/admin-heediq/heediq-workspace**

```
heediq-workspace/
  CLAUDE.md                     ← you are here (root rules + imports)
  rules/
    01-development-workflow.md  ← the Step 0–6 sequence for every change
    02-git-and-commits.md       ← branching, commits, PRs (GitHub)
    03-ui-kit.md                ← UI component library — style once, reuse everywhere
    04-loading-and-feedback.md  ← every wait is visible; the system is always responsive
    05-testing.md               ← test layers & the pre-PR gate
    06-documentation.md         ← code-level READMEs next to the code (no Confluence)
    07-engineering-standards.md ← types, security/privacy, errors, cost, a11y, perf, naming
    08-memory.md                ← what Claude reads/writes across tasks
    09-decisions.md             ← auto-capture of locked decisions into business memory
  memory/
    business/                   ← BUSINESS memory: what we decided & why
      DECISIONS.md              ← canonical decisions log (source of truth)
      README.md
    codebase/                   ← CODEBASE memory: how the system works now
      MEMORY.md                 ← index + pointers to code READMEs & decisions
      feature_dependency_map.md ← upstream/downstream/shared-surface map
  plans/
    wip-*.md                    ← one open WIP file per in-flight branch
```

The detailed rules live in the imported modules below. Read the relevant module before acting.

@rules/01-development-workflow.md
@rules/02-git-and-commits.md
@rules/03-ui-kit.md
@rules/04-loading-and-feedback.md
@rules/05-testing.md
@rules/06-documentation.md
@rules/07-engineering-standards.md
@rules/08-memory.md
@rules/09-decisions.md

---

## Three things that are always true

1. **Decisions are locked before they are built, and captured the moment they're locked.** Andrii
   discusses and confirms, then we build. When any decision is locked in chat, record it
   **immediately and unprompted** in **`memory/business/DECISIONS.md`** (the canonical business
   memory), then confirm in one line. Locked decisions are constraints in every future chat — never
   silently contradict one. See `rules/09-decisions.md`.

2. **Documentation lives next to the code.** Each meaningful module/folder carries a `README.md`
   describing what it does, its key files, data flow, contracts, and gotchas. This *replaces*
   Confluence BD/TDD/TP/TRM pages. See `rules/06-documentation.md`.

3. **The UI is built once.** Every visual element (button, card, spinner, layout) is defined once in
   the UI kit and reused — never re-styled inline in a feature. Every wait the user experiences is
   visible. See `rules/03-ui-kit.md` and `rules/04-loading-and-feedback.md`.

---

## Workspace decisions — status

Locked (recorded in `memory/business/DECISIONS.md`):
- **Git host = GitHub** (`gh` for PRs; GitHub Actions CI). — D-013
- **No Jira / no issue tracker for now**, may adopt later; branches use `<type>/<short-desc>`. — D-014
- **Two-track memory + auto decision capture.** — D-015
- **Docs = code-level READMEs** (no Confluence). — D-016
- **`develop` integration-branch model.** — D-027
- **UI stack = Tailwind + Radix UI + shadcn-style local kit.** — D-028
- **Frontend build = Vite + React + TypeScript strict + React Router + TanStack Query.** — D-029
- **Test stack = Vitest/RTL + DynamoDB Local/LocalStack + Playwright + k6.** — D-030
- **DynamoDB multi-table at launch; SQL migration path open per service.** — D-031
- **Summarization/extraction = Claude API behind provider interface.** — D-032
- **API style = REST + `@heediq/shared` Zod schemas.** — D-033
- **API runtime = Hono on single Lambda.** — D-034
- **Polyrepo, 7 repos** (workspace, shared, web, api, worker-transcription, worker-summarization, infra). — D-035

Still open (not yet locked):
- **Exact pricing/packaging numbers** — principle locked D-011/D-019; numbers need revisiting against post-D-004 cost basis.
- **SAML/OIDC for enterprise IdPs** — deferred per D-020.
