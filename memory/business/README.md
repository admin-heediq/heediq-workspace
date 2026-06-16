# Business Memory

The **business memory** track: the durable record of *what we decided and why* — product, design,
architecture, infra, cost, pricing, branding, scope, positioning. This is the "why" layer, kept
separate from the codebase memory ("how it works now", under `../codebase/`).

It exists because Heediq is a brand-new product where decisions are made constantly in conversation.
Every locked decision must be captured here so nothing is lost and every future chat starts with full
context.

## Files
- **`DECISIONS.md`** — the canonical, append-only decisions log. The single source of truth for
  locked decisions (the "what" + "why," kept lean). See `rules/09-decisions.md` for how entries
  are captured and formatted.
- **`branding.md`** — name, brand story, taglines, verbatim logo SVG, asset library, color
  tokens, typography, spacing/radius, Listen-button states, empty states.
- **`product.md`** — product vision, extraction concept, account/roles model, free-tier &
  billing, auth, data retention, PWA/platform spec, home screen UX, meeting bot, MVP build order.
- **`architecture.md`** — AWS stack, environments, multi-tenancy, transcription pipeline & cost
  figures, engineering process summary.
- (Grows further as needed — promote a new cluster of related decisions into its own file when
  one of the above gets large, keeping `DECISIONS.md` as the lean index.)

## Rules
- Read `DECISIONS.md` at the start of every conversation/task — locked decisions are **constraints**,
  not suggestions.
- Decisions are captured **automatically and immediately** when Andrii locks them — see
  `rules/09-decisions.md`.
- Never reconstruct decision detail from memory summaries; preserve locked text verbatim.
