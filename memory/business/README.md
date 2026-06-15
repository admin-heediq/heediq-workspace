# Business Memory

The **business memory** track: the durable record of *what we decided and why* — product, design,
architecture, infra, cost, pricing, branding, scope, positioning. This is the "why" layer, kept
separate from the codebase memory ("how it works now", under `../codebase/`).

It exists because Heediq is a brand-new product where decisions are made constantly in conversation.
Every locked decision must be captured here so nothing is lost and every future chat starts with full
context.

## Files
- **`DECISIONS.md`** — the canonical, append-only decisions log. The single source of truth for
  locked decisions. See `rules/09-decisions.md` for how entries are captured and formatted.
- (Grows as needed: e.g. `product.md`, `pricing.md`, `branding.md` — promote a cluster of related
  decisions into its own file when `DECISIONS.md` gets large, keeping `DECISIONS.md` as the index.)

## Rules
- Read `DECISIONS.md` at the start of every conversation/task — locked decisions are **constraints**,
  not suggestions.
- Decisions are captured **automatically and immediately** when Andrii locks them — see
  `rules/09-decisions.md`.
- Never reconstruct decision detail from memory summaries; preserve locked text verbatim.
