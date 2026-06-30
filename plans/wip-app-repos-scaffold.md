# WIP — App repos scaffold (MVP critical path)

**Status:** In progress — all CDK infra deployed to dev (see done-heediq-infra-scaffold.md). Starting app-layer repos.

**MVP build order (D-010):** auth/onboarding → home/Listen → recordings library → recording detail/summary

---

## Repo build sequence

Repos must be built in this order — each depends on the previous:

1. **heediq-shared** → Zod schemas + TypeScript types (`@heediq/shared`). Everything else imports from here.
2. **heediq-api** → Hono Lambda: auth middleware (D-041), all REST endpoints, D-060 job enqueue access control.
3. **heediq-worker-transcription** → faster-whisper container: SIGTERM handler, status stage writes.
4. **heedpm-worker-summarization** → Claude API extraction Lambda: SQS trigger, structured output.
5. **heediq-web** → Vite + React PWA: auth flow, home/Listen, recordings library, detail/summary view.

---

## 1. heediq-shared ⬅ CURRENT

**Branch:** `feature/shared-types-scaffold`

**Purpose:** Publish `@heediq/shared` to GitHub Packages — the single Zod + TypeScript contract consumed by `heediq-api`, `heediq-web`, and `heediq-worker-summarization`.

### What to build

**Package setup:**
- `package.json`: name `@heediq/shared`, version `0.1.0`, private (GitHub Packages), `main`/`types` pointing to `dist/`
- `tsconfig.json`: strict, `declaration: true`, `outDir: dist`
- `pnpm` workspace (D-039)
- Build: `tsc` → `dist/`; `prepublishOnly` runs build
- GitHub Actions: `publish.yml` — on push to `main` (version bump PR), `pnpm publish`

**Schemas to define (Zod → inferred TS types):**

*Shared enums/primitives:*
- `TierSchema` — `'free' | 'paid'`
- `WhisperModelSchema` — `'small' | 'large-v3'`
- `JobStatusSchema` — `'queued' | 'starting' | 'transcribing' | 'diarizing' | 'summarizing' | 'done' | 'failed' | 'retrying'`
- `RecordingStatusSchema` — `'uploading' | 'processing' | 'ready' | 'failed'`
- `OrgRoleSchema` — `'admin' | 'member'`

*API request/response envelopes:*
- `ApiSuccessSchema<T>` — `{ ok: true, data: T }`
- `ApiErrorSchema` — `{ ok: false, error: { code: string, message: string, details?: unknown } }`

*Domain schemas:*
- `OrgSchema` — `{ orgId, name, plan: Tier, seatCount, usageLifetimeCount, createdAt }`
- `UserSchema` — `{ userId, orgId, email, role: OrgRole, createdAt }`
- `RecordingSchema` — `{ recordingId, orgId, userId, title, status: RecordingStatus, durationSecs?, createdAt, updatedAt }`
- `JobSchema` — `{ jobId, recordingId, orgId, status: JobStatus, model: WhisperModel, tier: Tier, startedAt?, completedAt?, errorMessage? }`
- `SummarySchema` — `{ recordingId, orgId, transcript?, requirements: string[], decisions: string[], openQuestions: string[], actionItems: string[], createdAt }`

*API request schemas (used by API + web for validation):*
- `CreateRecordingRequestSchema` — `{ title: string, durationSecs?: number }`
- `EnqueueJobRequestSchema` — `{ recordingId: string, model: WhisperModel }` (model validated at API layer per D-060)
- `UpdateRecordingRequestSchema` — `{ title?: string }`

*SQS message schemas (used by API + workers):*
- `TranscriptionJobMessageSchema` — `{ jobId, recordingId, orgId, audioS3Key, model: WhisperModel, tier: Tier }`
- `SummarizationJobMessageSchema` — `{ jobId, recordingId, orgId, sourceType: 'audio' | 'text', contentRef: string }` (D-065)

*WebSocket message schemas (used by web + status pusher):*
- `WsStatusMessageSchema` — `{ type: 'job_status', jobId, recordingId, status: JobStatus, updatedAt }`

**Exports:**
- `src/index.ts` re-exports everything; `dist/index.js` + `dist/index.d.ts`

**Tests:** Vitest unit tests for each schema — valid + invalid inputs, inferred type shape.

**Rollback:** N/A — new package, not wired in yet.

---

## 2. heediq-api

**Branch:** `feature/api-scaffold`

**Purpose:** Hono Lambda with all REST endpoints (D-034), JWT auth middleware (D-041), `/api/v1/` prefix (D-042), D-060 access control at job enqueue. Consumes `@heediq/shared`.

### Endpoints (MVP scope)

```
POST   /api/v1/auth/refresh            ← Cognito token refresh (proxy)
GET    /api/v1/me                      ← current user + org
GET    /api/v1/recordings              ← list org recordings (paginated)
POST   /api/v1/recordings              ← create recording + presigned S3 URL
GET    /api/v1/recordings/:id          ← get recording + job status
PATCH  /api/v1/recordings/:id          ← update title
DELETE /api/v1/recordings/:id          ← soft-delete
POST   /api/v1/recordings/:id/jobs     ← enqueue transcription job (D-060 access control)
GET    /api/v1/recordings/:id/summary  ← get summary
POST   /api/v1/upload/presign          ← get S3 presigned PUT URL
```

### Auth middleware (D-041)
- JWKS-based Cognito JWT validation (jose library)
- Extracts `userId`, `orgId`, `role` into Hono context
- Org isolation enforced on every handler

### D-060 access control at enqueue
- Free users: only `model: 'small'` accepted; API rejects `large-v3`
- Paid users: both models allowed
- Enforced via org plan check before SQS enqueue

---

## 3. heediq-worker-transcription

**Branch:** `feature/transcription-worker`

**Purpose:** faster-whisper Python container — process SQS job, write status stages, handle Spot interruption.

### What to build
- SQS long-poll loop (receive → process → delete)
- `status_writer.py` — writes job status stages to `heediq-jobs` DynamoDB
- Status progression: `starting` (before model load) → `transcribing` → `diarizing` (large-v3 only) → enqueue summarization SQS message → `done`
- SIGTERM handler: catch → write `status=retrying` → exit cleanly (SQS visibility timeout expires → auto-retry)
- Dockerfiles: two images (free=small, paid=large-v3+pyannote) with models baked in (D-062)

---

## 4. heediq-worker-summarization

**Branch:** `feature/summarization-worker`

**Purpose:** Node Lambda — poll SQS `heediq-summarization`, call Claude API, write structured extraction to DynamoDB.

### What to build
- SQS event source (already wired by SummarizationStack)
- Load transcript from S3 or inline text (per `sourceType` in message, D-065)
- Call Claude API with structured extraction prompt → `requirements`, `decisions`, `openQuestions`, `actionItems`
- Write summary to `heediq-recordings` DynamoDB (or separate `heediq-summaries` table)
- Write `status=done` to `heediq-jobs`
- Provider interface (D-032) so model/vendor is swappable

---

## 5. heediq-web

**Branch:** `feature/web-scaffold`

**Purpose:** Vite + React PWA — auth flow, home/Listen screen, recordings library, recording detail + summary view. Consumes `@heediq/shared`.

### Screens (MVP)
1. **Auth** — sign in (Cognito hosted UI + Google/Microsoft IdP), sign up, org creation on first login
2. **Home / Listen** — three-state Listen button (idle/recording/processing, D-026/D-008), upload audio, upload text, usage indicator
3. **Recordings library** — list, status badges, search/filter (separate nav page per D-026)
4. **Recording detail** — transcript, summary tabs (requirements/decisions/open questions/action items), real-time job status via WebSocket (D-061)

---

## Standing notes (carry forward)
- `heediq-infra/scripts/setup.sh` needs narrow `GitHubActionsDeployRole` for each app repo — add as each repo gets its first CI workflow.
- `heediq-infra` ACM cert CNAME validation must be manually added to Route 53 for staging/prod when those environments are bootstrapped (one-time per env, D-063).
- Staging/prod budgets (D-056) to be added once those accounts see traffic.
