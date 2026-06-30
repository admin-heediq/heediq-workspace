# WIP — App repos scaffold (MVP critical path)

**Status:** In progress — all CDK infra deployed to dev. heediq-shared published, heediq-api PR ready.

**MVP build order (D-010):** auth/onboarding → home/Listen → recordings library → recording detail/summary

---

## Repo build sequence

1. ~~**heediq-shared**~~ ✅ Published `@heediq/shared@0.1.0` to GitHub Packages. 49 tests.
2. ~~**heediq-api**~~ ✅ PR #1 open (feature/api-scaffold → develop). 16 tests. deploy.yml added. `^0.1.0` from registry. Ready to merge.
3. **heediq-worker-transcription** → faster-whisper Python container. ⬅ CURRENT
4. **heediq-worker-summarization** → Node Lambda, Claude API extraction.
5. **heediq-web** → Vite + React PWA.

---

## 3. heediq-worker-transcription ⬅ CURRENT

**Branch:** `feature/transcription-worker`

**Purpose:** faster-whisper Python container — process SQS job, write status stages, handle Spot interruption.

### What to build
- SQS long-poll loop (receive → process → delete)
- `status_writer.py` — writes job status stages to `heediq-jobs` DynamoDB
- Status progression: `starting` (before model load) → `transcribing` → `diarizing` (large-v3 only) → enqueue summarization SQS message → `done`
- SIGTERM handler: catch → write `status=retrying` → exit cleanly (SQS visibility timeout expires → auto-retry)
- Dockerfiles: two images (free=small, paid=large-v3+pyannote) with models baked in (D-062)
- deploy.yml: docker build → ECR push (sha-<7chars> tag) → ECS update-service (D-047)

---

## 4. heediq-worker-summarization

**Branch:** `feature/summarization-worker`

**Purpose:** Node Lambda — SQS `heediq-summarization`, Claude API extraction, write to DynamoDB.

### What to build
- SQS event source (already wired by SummarizationStack)
- Load transcript from S3 or inline text (per `sourceType` in message, D-065)
- Call Claude API → `requirements`, `decisions`, `openQuestions`, `actionItems`
- Write summary + `status=done` to DynamoDB
- Provider interface (D-032) so model/vendor is swappable
- deploy.yml: esbuild bundle → Lambda update (same pattern as heediq-api)

---

## 5. heediq-web

**Branch:** `feature/web-scaffold`

**Purpose:** Vite + React PWA — auth flow, home/Listen screen, recordings library, recording detail + summary view.

### Screens (MVP)
1. **Auth** — Cognito hosted UI + Google/Microsoft IdP, org creation on first login
2. **Home / Listen** — three-state Listen button (idle/recording/processing, D-026/D-008), upload audio/text, usage indicator
3. **Recordings library** — list, status badges, search/filter
4. **Recording detail** — transcript, summary tabs, real-time job status via WebSocket (D-061)
- deploy.yml: Vite build → S3 sync → CloudFront invalidation

---

## Deployment model (reference — all app repos)

- **heediq-shared**: semver publish on `main` merge. Bump `version` before merge. Renovate bumps consuming repos (D-048). Grant new consuming repos read access in GitHub Packages settings (one-time).
- **heediq-api / heediq-worker-summarization**: esbuild bundle → zip → `aws lambda update-function-code` on develop push. Same artifact promoted to staging → prod.
- **heediq-worker-transcription**: Docker build → ECR push (sha tag) → ECS update-service on develop push.
- **heediq-web**: Vite build → S3 sync + CloudFront invalidation on develop push.
- All repos: same branching — feature → PR → develop (auto-deploy dev) → main (staging → manual gate → prod).

## Standing notes (carry forward)
- `heediq-infra` ACM cert CNAME validation must be manually added to Route 53 for staging/prod when those accounts are bootstrapped (one-time per env, D-063).
- Staging/prod budgets (D-056) to be added once those accounts see traffic.
- Run `./scripts/setup.sh` for staging/prod accounts when their first app deploy workflows are wired.
