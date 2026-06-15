# Documentation — Code-Level READMEs (No Confluence)

Documentation lives **next to the code it describes**, as `README.md` files in folders beside the core
scripts. This replaces the Confluence BD/TDD/TP/TRM hierarchy entirely. The README is the durable,
human-readable design record; memory (`08-memory.md`) is the lean task-priming index that points to
these READMEs.

## Where READMEs go
- A `README.md` in every **meaningful module/folder**: each backend service/Lambda group, each
  feature folder, each shared library (UI kit, shared types, auth, transcription pipeline), and the
  infra/CDK folder.
- A README earns its place when the folder owns real logic, a contract, a data flow, or a gotcha —
  not for trivial leaf folders.

## When to write/update a README (ties into Step 5)
Update the nearest README whenever a change alters:
- **Business behavior** — new rules, changed/removed functionality.
- **A contract** — API route shape, DynamoDB key/model, SQS message shape, permission rule.
- **Data flow** — how a request/job moves through the system.
- **A gotcha/constraint** — anything non-obvious you had to learn.
Pure UI tweaks, copy, and behavior-neutral refactors usually don't need a README change. Always get
the user's approval before editing a README (Step 5).

## README structure
```
# <Module / Feature name>

## Purpose
What this does and why it exists (the "BD" content — business intent, in plain language).

## Key Files
- path/to/file.ts — what it does

## Data Flow / How It Works
Step-by-step: how a request or job moves through this module (the "TDD" content).

## Contracts
- API routes / events: method, path/event, request & response shape, errors
- Data model: DynamoDB keys & item shape / SQS message shape
- Permissions: who can do what; cross-org/tenant isolation rules

## Dependencies
- Upstream (this relies on): …
- Downstream (breaks if this changes): …
- Shared surfaces: files/models touched by multiple features

## Testing
How to run this module's tests; which suites cover it; seeds; known flakies (the "TP" content).

## Gotchas & Constraints
Edge cases, cost notes, things easy to get wrong (the "TRM"/ops content).
```

## UI components
Kit components keep a shorter README per `03-ui-kit.md`: purpose, props/variants, supported states,
usage example.

## Relationship to the decisions doc
- **`memory/business/DECISIONS.md`** = locked cross-cutting product/design/architecture/cost
  decisions (canonical business memory, append-only; see `rules/09-decisions.md`).
- **Code READMEs** = how a specific module works *now*.
- **`memory/codebase/`** = index + dependency map + pointers; the thing Claude reads first to know
  which READMEs/decisions to open.
Keep them non-duplicative: a decision is recorded once in `DECISIONS.md` and referenced, not copied
into every README.
