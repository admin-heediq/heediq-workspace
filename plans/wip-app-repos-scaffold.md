# WIP — App repos scaffold (MVP critical path)

**Status:** All backend repos scaffolded and PRs open. CI green on all repos. heediq-web is next.

**MVP build order (D-010):** auth/onboarding → home/Listen → recordings library → recording detail/summary

---

## Repo build sequence

1. ~~**heediq-shared**~~ ✅ `@heediq/shared@0.1.0` on GitHub Packages. 49 tests. Merged to develop.
2. ~~**heediq-api**~~ ✅ PR #1 open (feature/api-scaffold → develop). 17 tests. deploy.yml wired.
3. ~~**heediq-infra fix**~~ ✅ PR open (fix/transcription-task-runtime → develop). SSM-based image tag promotion + setup.sh section 3 (SSM seed).
4. ~~**heediq-worker-transcription**~~ ✅ PR open (feature/transcription-worker). 11 pytest + mypy. deploy.yml: ECR push + ssm/task-def/pipes promotion per env.
5. ~~**heediq-worker-summarization**~~ ✅ PR #1 open (feature/summarization-worker). 10 Vitest tests. deploy.yml: esbuild → lambda update-function-code per env.
6. **heediq-web** → Vite + React PWA. ⬅ NEXT

---

## 6. heediq-web (next)

**Branch:** `feature/web-scaffold`

**Purpose:** Vite + React PWA — auth, home/Listen, recordings library, recording detail + summary.

### Screens (MVP)
1. **Auth** — Cognito hosted UI + Google/Microsoft IdP, org creation on first login
2. **Home / Listen** — three-state Listen button (idle/recording/processing, D-026/D-008), upload audio/text
3. **Recordings library** — list with real-time status badges, search/filter
4. **Recording detail** — transcript + summary tabs, live job status via WebSocket (D-061)

### Deploy
- Vite build → `aws s3 sync` → `aws cloudfront create-invalidation`
- Reads `/heediq/web/cloudfront-distribution-id` and `/heediq/web/url` from SSM

---

## Key implementation notes (carry into heediq-web)

- **Auth**: Cognito User Pool + Google + Microsoft IdPs (D-020). Cognito hosted UI or Amplify Auth. JWT from Cognito is passed as `Authorization: Bearer <token>` to all API calls.
- **API base**: `https://api-dev.heediq.com/api/v1/` (dev) — from SSM `/heediq/api/endpoint-url`. All routes under `/api/v1/` require JWT auth.
- **WebSocket**: `wss://ws-dev.heediq.com` (dev) — from SSM `/heediq/api/ws-endpoint-url`. Status events: `{ type: 'job_status', jobId, recordingId, status, updatedAt }` (WsStatusMessage in @heediq/shared).
- **Recording flow**: `POST /recordings` → `POST /upload/presign` → S3 PUT → `POST /recordings/:id/jobs` → real-time status via WebSocket.
- **No transcript in DynamoDB on recordings table for the frontend** — the `transcript` field is written by the transcription worker, readable via `GET /recordings/:id`. The summary fields (requirements/decisions/openQuestions/actionItems) are written by the summarization worker, readable via `GET /recordings/:id/summary`.
- **Status stages**: queued → starting → transcribing → diarizing (paid only) → summarizing → done / failed
- **Design tokens**: charcoal + amber, Inter/Geist UI, JetBrains Mono for transcript text. Linear/Vercel/Raycast aesthetic. UI kit must be built before feature screens (D-012, D-007).
- **Deploy wires to**: WebStack SSM params `/heediq/web/cloudfront-distribution-id` (for cache invalidation) and `/heediq/web/url` (set as CORS origin in API).

---

## Deployment model (reference — all app repos)

- **heediq-shared**: semver publish on `main` merge. Renovate bumps consuming repos (D-048).
- **heediq-api / heediq-worker-summarization**: esbuild bundle → `aws lambda update-function-code` per env (GitHubActionsDeployRole). pnpm 11.
- **heediq-worker-transcription**: two Docker builds (free/paid) → ECR push (GitHubActionsECRRole in shared-services) → `ssm put-parameter` + `ecs register-task-definition` + `aws pipes update-pipe` per env (GitHubActionsDeployRole).
- **heediq-web**: Vite build → `aws s3 sync` + CloudFront invalidation per env (GitHubActionsDeployRole).
- All repos: feature → PR → develop (auto-deploy dev) → main (staging → manual gate → prod).

## Standing notes (carry forward)
- `heediq-infra` ACM cert CNAME validation must be manually added to Route 53 for staging/prod on first deploy (D-063).
- `scripts/setup.sh` sections 1–3 must run for staging/prod before first CDK deploy.
- `HF_TOKEN` GitHub secret must be set in `heediq-worker-transcription` before paid-tier image builds.
- `@heediq/shared` package access must be granted to any new consuming repo in GitHub org package settings.
