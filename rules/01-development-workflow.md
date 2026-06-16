# Development Workflow

For every fix or feature, follow this sequence. Skip steps only when the user explicitly says to go
faster, **or the change is low-risk** (defined below).

**Low-risk change** — all of these must be true:
- Style/CSS-only, copy text, or a config value (no logic, no data model, no API contract touched)
- Single isolated area, no shared surfaces or downstream consumers
- Reversible by a one-line revert

For low-risk changes: skip Steps 1–2, implement directly, then still do Steps 5–6 if a code README or
memory is affected (usually not for pure style fixes).

---

## Step 0 — Resume check + git sync + memory lookup (first thing, before anything else)

**0a — Open WIP file?** Look in `plans/` for any `wip-*.md`. If one exists, read it and say:
*"Found open branch `<branch>` — continuing: `<summary>`. Still what we're doing?"* If yes, resume
from the WIP state (skip Steps 1–2). If no, ask what to do.

**0b — Sync git (before reading code or planning):**
- On `develop`: `git pull` first.
- On a feature branch: ask *"You're on `<branch>`, not `develop` — intentional?"* — if not, switch to
  `develop` and pull; if resuming, `git fetch origin develop && git merge origin/develop`.

**0c — Memory + docs lookup (always):**
1. Read `memory/business/DECISIONS.md` — locked decisions are constraints for this task. Read
   `memory/codebase/MEMORY.md` index for entries touching the area.
2. Read any relevant codebase memory files **and the code README(s) next to the files you'll touch**
   in full — they hold key files, data flow, contracts, and gotchas that save a codebase crawl.
3. Check `memory/codebase/feature_dependency_map.md` for the feature(s) involved — note upstream
   dependencies and downstream consumers; carry them into Step 2.
4. Use what you find to skip redundant questions and write a sharper plan.
5. **Coherence check — blocking.** Run the full scan from `08-memory.md` (Coherence check).
   Fix every mismatch found and commit before any other work. This step is **never skipped** —
   not for quick questions, not mid-session, not ever. Inconsistent decisions are a build risk.

If no memory/README exists for the area, note it — it gets created as you learn (see Step 6).

## Step 1 — Questions before planning
Ask every clarifying question needed for 100% clear context **before** writing a plan. Don't assume
intent. Skip only when the task is fully self-evident (rename, one-line fix, config value, typo).

## Step 2 — Plan with explained decisions
Write a plan that explains the *why* behind each change. It must include:
- **What changes and why** — each change + reasoning.
- **Test scenarios (manual QA)** — per step: *Role / Preconditions / Steps / Expected result*.
- **Automated tests to add/update** — name the unit tests, and (when a step touches an API route, DB
  access, or a permission path) the integration tests; list existing suites to re-run. If a step
  needs no test, say so and why. See `05-testing.md`.
- **UI conformance** (any UI step) — confirm it uses existing UI-kit components and the loading/
  feedback rules; flag any *new* kit component or variant that must be added (see `03-ui-kit.md`,
  `04-loading-and-feedback.md`).
- **Rollback note per step** — one line: "To undo: …".
- **Risk & Regression** — *Change safety* (Low/Med/High + what could go wrong: data integrity,
  permission edges, races, cost, perf, cross-org isolation) and *Features to retest* (from the
  dependency map, one line each).

No code until the user approves or adjusts the plan.

## Step 3 — Incremental implementation
Small, independently testable steps. A step is too large if it touches >3 files or changes >1
behavior — split it. Each step is locally testable, confirmed working before the next, and **ships
with its tests** (a fix includes a regression test that fails before and passes after). If a step
introduces a regression, **roll back to the last working state before debugging** — don't stack fixes
on a broken base.

## Step 4 — Confirm before continuing
Wait for the user to confirm a step works locally before the next. If unconfirmed after 2 exchanges,
flag it: *"I haven't had confirmation that step N works — please verify before I continue."*

## Step 4.5 — Type/build check before any commit or push
Run the service's typecheck/build (command lives in the relevant package's README/`package.json`).
Fix all errors before committing. Skip only if the user explicitly says so.

## Step 4.6 — Test gate before opening a PR
`pnpm run test:pre-pr` (typecheck + unit) green, **and** the related integration suites pass (derive
them from the dependency map). Fix failures at the source — never `--no-verify`, never delete the
failing assertion. The PR description lists tests added and suites run. See `05-testing.md`.

## Step 5 — Documentation sync (end of feature) — code READMEs, not Confluence
After the feature works and is confirmed:
1. Identify the code README(s) next to the files you changed (and any module-level README whose
   contract/behavior/data-flow shifted).
2. For each, show the proposed change and get approval: *"Here's what I'll update in
   `path/README.md`: <summary>. Proceed?"*
3. On approval, update the README following the structure in `06-documentation.md` (purpose, key
   files, data flow, contracts, gotchas, test notes). New module with no README → create one.

A change to **business behavior, an API/DB contract, or a permission rule** must be reflected in the
nearest README. Pure UI tweaks, copy, and refactors that don't change behavior usually don't need it.

**Do Step 5 before Step 6** so memory can capture any new README paths.

## Step 6 — Memory actualization (end of every task)
Final memory pass after Step 5. Confirm: every README/memory file touched reflects reality; new code
README paths are pointed to from `MEMORY.md`; `feature_dependency_map.md` is current. Run the
**coherence check** from `08-memory.md` to confirm no staleness was introduced by decisions locked or
changed this session. All memory changes committed; push if the session is ending. See `08-memory.md`.

---

## Continuous memory updates (throughout, not just at the end)
Write to memory / the nearest README **as you learn** — when you learn what a file does or who calls
it, discover a non-obvious dependency or side-effect, confirm/disprove an uncertain note, or learn an
API contract, DB shape, or permission rule. Stale memory is worse than none. If you read more than 2
files in an area (or learn about a shared utility / permission layer / contract), that area earns a
README/memory entry if it lacks one.
