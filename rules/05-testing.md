# Testing & Quality Gates

The shared *contract* (what must be true). Exact commands and gotchas live in each package's
`README.md` / `package.json`. **Proposed stack** (confirm or change): Vitest + React Testing Library
(frontend), Vitest against DynamoDB Local / LocalStack (backend integration), Playwright (E2E), k6
(load) — see the root decisions.

## The four test layers
| Layer | Lives in | Runtime | When |
|-------|----------|---------|------|
| **Unit** | colocated `__tests__/` + `*.test.ts(x)` | Vitest, no external services | every change; the pre-PR gate |
| **Integration** | `tests/integration/<area>/` | Vitest + **real DynamoDB Local / LocalStack** (SQS, S3), msw for external HTTP | API/DB/permission/queue changes; related suites in the pre-PR gate |
| **E2E** | `tests/e2e/` | Playwright (real browser) | critical journeys: record → transcribe → view → push to Jira/Confluence; not in the local gate |
| **Performance** | `tests/performance/`, `tests/stress/` (k6) | k6 / Vitest, separate env | load-sensitive surfaces (transcription throughput, library/search); run deliberately |

## What every change must do
- **New feature** → meaningful **unit** tests for its logic/components, **and** integration tests for
  any new/changed API route, DynamoDB access, SQS/queue path, or permission/cross-org isolation rule.
- **Bug fix** → a **regression test that fails before the fix and passes after**, at the layer that
  reproduces the bug.
- **Refactor** → existing tests stay green; add tests for behavior they didn't cover.
- **Run the related integration suites**, not only the new ones — use `feature_dependency_map.md` to
  find downstream consumers and shared surfaces, and re-run their suites.

## What "meaningful" means
- **Test behavior and contracts, not implementation** — assert on API responses / rendered UI /
  observable output, not internal call counts or private state.
- **One behavior per test**, Arrange–Act–Assert, descriptive `it('…')` naming the expected behavior.
- **Cover the edges** — auth/permission denials, empty/invalid input, boundaries, **cross-org/tenant
  isolation**, concurrency where relevant.
- **Deterministic** — seed faker per suite; no wall-clock/network/order reliance. Mock only true
  externals (AI/Whisper API, S3, Recall.ai) via msw; integration tests hit the real DB/queue on
  purpose — don't mock the thing you're verifying.
- **No coverage-padding / snapshot-only tests** — a passing test must be able to fail for a real
  reason. Coverage is a floor, not the goal.

## UI-specific testing
- Test kit components for **all declared states** (default/hover/focus/disabled/**loading**/**error**)
  and keyboard/a11y behavior.
- Test that data screens render the three branches correctly: **loading skeleton · content · error
  state** (see `04-loading-and-feedback.md`).

## The pre-PR gate (Step 4.6)
`npm run test:pre-pr` (typecheck + unit) green, **and** the related integration suites pass. Never
open a PR on red. Fix at the source — never `--no-verify`, never delete the failing assertion. The PR
lists tests added and suites run.
