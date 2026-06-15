# Memory Contract

Memory is the **lean task-priming layer**: what Claude reads first to know which decisions and code
READMEs apply. It does **not** duplicate full decision text (that's `memory/business/DECISIONS.md`)
or full design docs (those are code READMEs). Keep it small and pointer-heavy.

## Where memory lives
All memory lives in **`heediq-workspace/memory/`** — normal, version-controlled repo files, shared by
the team. This overrides any default per-user memory path. After writing memory, commit & push it so
teammates get it; pull regularly.

## Two tracks (don't duplicate across them)
1. **Business memory** — `memory/business/` — *what we decided and why*. Canonical file
   `DECISIONS.md`. Captured automatically when decisions are locked; see `rules/09-decisions.md`.
2. **Codebase memory** — `memory/codebase/` + the code READMEs next to the code — *how the system
   works now*. The index (`MEMORY.md`), the dependency map, and per-module READMEs
   (`rules/06-documentation.md`).

A fact is recorded once in its home and referenced elsewhere, never copied.

## Read at task start (Step 0c)
- `memory/business/DECISIONS.md` — locked decisions are constraints.
- `memory/codebase/MEMORY.md` (index) and `memory/codebase/feature_dependency_map.md`.
- Then the **code README(s)** next to the files you'll touch, and any codebase memory file flagged
  relevant.

## Write throughout (continuous updates)
Write as you learn — what a file does, a non-obvious dependency/side-effect, a contract, a DB shape, a
permission rule, a gotcha. Put durable per-module knowledge in the **code README**; use
`memory/codebase/` for the index pointer, cross-module facts, and the dependency map; put decisions in
`memory/business/DECISIONS.md`. Stale memory is worse than none — correct or delete wrong notes
immediately.

## `memory/codebase/MEMORY.md` (the index)
Short index. Each entry: area/feature -> one-line summary -> pointer to its code README and any relevant
decision IDs. New module with a README -> add a pointer line.

## `memory/codebase/feature_dependency_map.md`
Per feature: **Upstream** (depends on), **Downstream** (breaks if this changes), **Shared surfaces**.
Update on every change that adds/changes/removes a feature or dependency. Drives "what to retest"
(Step 2) and PR blast-radius notes.

## End-of-task pass (Step 6)
Confirm: every README/memory file touched reflects reality; new README paths are pointed to from
`MEMORY.md`; `feature_dependency_map.md` is current; every decision locked this task is in
`DECISIONS.md` (with superseded entries marked) per `rules/09-decisions.md`.
