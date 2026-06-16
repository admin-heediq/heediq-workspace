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

## Verify before every write (prevent noise and contradiction)
Before writing or updating any memory file, do the following — every time, no exceptions:

1. **Check for existing coverage.** Read the target file and any related memory entries. Ask: does
   this information already exist, even partially or under a different label?
2. **Deduplicate.** If the information exists: update the existing entry rather than adding a new one.
   If it's now stale, correct or remove it. Never add a second entry for the same fact.
3. **Check for contradiction.** If the new information conflicts with something already recorded, do
   not write either silently. Flag the conflict to Andrii: *"This contradicts [existing entry] — which
   is correct?"* and wait for a resolution before writing.
4. **Ask if unclear.** If the right category, scope, or wording is uncertain, ask one short question
   before writing. A wrong memory entry is harder to fix than a one-second pause.
5. **Write only durable facts.** Don't record implementation details that belong in code, task context
   that only matters this session, or anything that will obviously be stale after the next change.

The goal is a small, consistent, trustworthy memory — not a complete log. When in doubt, less is more.

## `memory/codebase/MEMORY.md` (the index)
Short index. Each entry: area/feature -> one-line summary -> pointer to its code README and any relevant
decision IDs. New module with a README -> add a pointer line.

## `memory/codebase/feature_dependency_map.md`
Per feature: **Upstream** (depends on), **Downstream** (breaks if this changes), **Shared surfaces**.
Update on every change that adds/changes/removes a feature or dependency. Drives "what to retest"
(Step 2) and PR blast-radius notes.

## Memory optimization (when memory grows noisy)
When memory accumulates enough that it starts to feel repetitive, scattered, or hard to navigate,
do a consolidation pass. This is triggered by Andrii's request, not done silently on every task.

**How to optimize:**
1. **Read the full target file(s)** before changing anything.
2. **Identify noise**: duplicate facts, stale entries that no longer reflect reality, overly verbose
   explanations of things now obvious from the code, session-specific context that has no future value.
3. **Propose the consolidation** — show Andrii what would be merged, reworded, or removed and why.
   Do not rewrite memory without approval.
4. **On approval, consolidate**: merge related entries, tighten wording, remove genuinely stale items.
   For decisions, never delete — supersede instead (`rules/09-decisions.md`). For codebase memory,
   deletion is fine when the fact is no longer true.
5. **Verify completeness after**: confirm nothing load-bearing was lost. The optimized memory must
   still cover every constraint, contract, and gotcha that a future session would need.

The goal is a memory that is **short enough to scan quickly and comprehensive enough to be trusted** —
not a historical archive, not a one-liner that hides important nuance.

## Committing & pushing memory (always)
Every memory write must be followed by a commit in `heediq-workspace`. Don't batch memory commits
to the end of a session — commit each logical change as it happens so the repo is never silently
out of sync.

**After each memory write:**
```
cd heediq-workspace
git add memory/business/<file> memory/codebase/<file>   # stage only the changed memory files
git commit -m "docs(memory): <one-line summary of what was added/changed>"
```

Use `docs:` prefix for rule changes, `docs(memory):` for memory file changes.
No `Co-Authored-By` trailer — commit authorship stays with the human committer (per `02-git-and-commits.md`).

**At the end of every session**, push all commits that haven't been pushed yet:
```
git push
```

Ask Andrii before pushing if it's unclear whether the session is done — don't push mid-session
without a prompt to do so.

## End-of-task pass (Step 6)
Confirm: every README/memory file touched reflects reality; new README paths are pointed to from
`MEMORY.md`; `feature_dependency_map.md` is current; every decision locked this task is in
`DECISIONS.md` (with superseded entries marked) per `rules/09-decisions.md`. All memory changes
are committed to `heediq-workspace`; push if the session is ending.
