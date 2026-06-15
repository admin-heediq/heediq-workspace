# Decision Capture & Business Memory

Heediq is a brand-new product: decisions about scope, design, architecture, cost, pricing, and brand
are made constantly in conversation. This module defines how those decisions are **captured
automatically**, kept as **business memory**, and applied as **constraints** in every future chat.

## Two memory tracks (keep them separate, both live in `memory/`)
- **Business memory** (`memory/business/`) — *what we decided and why*. Product, design, architecture,
  infra, cost, pricing, branding, scope, positioning. Canonical file: `memory/business/DECISIONS.md`.
- **Codebase memory** (`memory/codebase/` + code READMEs) — *how the system works now*. Index, the
  feature dependency map, and per-module READMEs.

A decision is recorded **once** in business memory; code READMEs reference it rather than copying it.

## What counts as a decision (capture these)
Anything that constrains future work or that we'd later want the "why" for:
- Product scope / which features are in or out, and build order
- UX & design choices (layouts, flows, component behavior, design tokens)
- Architecture & infrastructure (services, data model at the product level, vendors/tools)
- Cost & performance tradeoffs (model tiers, optimizations accepted/rejected)
- Pricing & packaging
- Branding, naming, positioning, copy direction
- Policy (privacy, retention, security posture)

Not decisions: routine implementation details that belong in a code README, and anything still being
brainstormed.

## Automatic capture — the core behavior
**When Andrii locks a decision, record it immediately and unprompted**, then give a one-line
confirmation. Do not wait for the end of the task, and do not ask "should I save this?" once it's
clearly locked.

1. **Detect the lock.** Lock signals include explicit phrasing ("this is locked", "decided", "let's
   go with X", "yes, do that") or a clear confirmation of a proposed option. Andrii's style is to lock
   explicitly and sequentially.
2. **If it's genuinely ambiguous** whether something is a firm decision or still open discussion, ask
   one short question: *"Lock this as a decision?"* — don't record open brainstorming as locked.
3. **Write it to `memory/business/DECISIONS.md`** in the entry format below.
4. **Confirm in one line**, e.g. *"Locked → recorded as D-014 in DECISIONS.md."*
5. **Claude never self-locks.** Claude proposes and records; only Andrii locks. If Claude recommends
   something, it stays a proposal until Andrii confirms.

## Apply decisions as constraints (every chat)
- Read `DECISIONS.md` at task start (Step 0c). Treat locked decisions as binding context.
- **Never silently contradict a locked decision.** If a new request conflicts with one, flag it:
  *"This conflicts with D-009 (DynamoDB-only at launch). Supersede it, or keep D-009?"* — and only
  change it if Andrii locks the new direction.

## Superseding, not duplicating
Decisions evolve. When a new decision changes an old one:
- Set the old entry's **Status: Superseded by D-NNN** (keep it — history matters for the "why").
- Add the new entry with **Supersedes: D-MMM**.
Never delete a decision or silently edit its meaning; supersede it.

## Status lifecycle
`Proposed` (optional, while under discussion) → `Locked` → `Superseded` / `Reversed`.

## Entry format (in `DECISIONS.md`)
```
### D-014 · <short title> (YYYY-MM-DD) — Locked
**Area:** Product | Design | Architecture | Infra | Cost | Pricing | Brand | Policy
**Decision:** One or two sentences stating exactly what was decided.
**Why:** The rationale / what it was chosen over.
**Supersedes:** D-MMM (or —)         **Superseded by:** D-NNN (or —)
**Related code:** path/to/module/README.md (once implemented, or —)
```

Keep entries lean: the decision + its rationale, not an essay. Detail about *how it's built* belongs in
the code README the entry points to.

## End-of-task pass (ties into Step 6)
Confirm every decision locked during the task is in `DECISIONS.md`, any superseded entries are marked,
and `memory/codebase/MEMORY.md` carries a pointer only for new *in-progress* items (never full
decision text).
