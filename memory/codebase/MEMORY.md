# MEMORY.md — Index

The lean index Claude reads first. Each entry points to a code README or a decision — it does not
duplicate their content. See `rules/08-memory.md` for the contract.

## How to use this file
- At task start, scan for the area you're touching, then open the pointed-to README(s) and decisions.
- After a task, add/correct pointers here for any new or changed module.

## Decisions
- Canonical locked decisions live in **`../business/DECISIONS.md`** (business memory). Reference
  decision IDs (e.g. D-007) from entries below; don't copy decision text here.

## Modules / Features (pointers)

- **heediq-infra** — CDK TypeScript project; all stacks for all accounts.
  README: `../../heediq-infra/README.md` · Decisions: D-036, D-037, D-038, D-044, D-045, D-051–D-062
  - **TranscriptionStack** — EC2 GPU Spot (g4dn.xlarge, D-059); ASG min=0; two Ec2TaskDefs (free/paid, D-060); models baked in image (D-062). Branch `feature/transcription-gpu` (PR #12 pending).
  - **FoundationStack** — 5 tables (recordings, orgs, users, jobs w/ DDB Streams NEW_IMAGE, ws-connections w/ TTL + by-recording GSI); 13 SSM params. Deployed (4-table base) + WebSocket additions on feature/websocket-stack PR pending.
  - **WebSocketStack** — implemented on feature/websocket-stack (D-061). WebSocket API + Connection Lambda heediq-ws-connect + Status Pusher Lambda heediq-ws-status-pusher (DDB Streams trigger) + custom domain ws-{env}.heediq.com + 2 SSM params. PR pending.

<!--
- **<feature/area>** — <one-line summary>.
  README: `path/to/module/README.md` · Decisions: ../business/DECISIONS.md (D-NNN)
-->

## Cross-module gotchas
_(Facts that span multiple modules and don't belong in any single README.)_

## In-progress (not yet doc-worthy)
_(Short notes on things being worked out; promote to a README or decisions doc when settled.)_
