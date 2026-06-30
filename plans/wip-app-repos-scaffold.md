# WIP — App repos scaffold (MVP critical path)

**Status:** In progress — all CDK infra deployed to dev. heediq-shared published. heediq-api PR #1 open (+ SQS tier attribute fix committed on feature/api-scaffold). heediq-worker-transcription scaffolded (feature/transcription-worker, PR not yet opened). heediq-infra fix/transcription-task-runtime (D-062/D-066 + SSM image tag promotion) not yet PR'd.

**MVP build order (D-010):** auth/onboarding → home/Listen → recordings library → recording detail/summary

---

## Repo build sequence

1. ~~**heediq-shared**~~ ✅ Published `@heediq/shared@0.1.0` to GitHub Packages. 49 tests.
2. ~~**heediq-api**~~ ✅ PR #1 open (feature/api-scaffold → develop). 17 tests. deploy.yml added. `^0.1.0` from registry. SQS `tier` message attribute fix included (d65b217). Ready to merge.
3. ~~**heediq-worker-transcription**~~ ✅ Scaffolded on `feature/transcription-worker`. PR not yet opened. ⬅ JUST COMPLETED
4. **heediq-worker-summarization** → Node Lambda, Claude API extraction. ⬅ NEXT
5. **heediq-web** → Vite + React PWA.

---

## 3. ~~heediq-worker-transcription~~ ✅ DONE

**Branch:** `feature/transcription-worker` (commits: 1324a2f feat + e9d356e docs)

**Key implementation notes (carry into heediq-worker-summarization):**
- **No SQS poll loop** — EventBridge Pipes is the consumer; job payload arrives via `SQS_MESSAGE_BODY` container override. One RunTask = one job (D-066).
- **Transcript → DynamoDB, not S3** — task role has no S3 write grant (read-only). Written to `heediq-recordings[recordingId].transcript`. Summarization worker must read from DynamoDB by `recordingId`.
- **Re-enqueue on SIGTERM** — Pipes deletes the SQS message on RunTask launch; worker must explicitly re-enqueue with `tier` attribute on Spot interruption.
- **Image promotion** — `deploy.yml` uses `GitHubActionsECRRole` in shared-services for push; `GitHubActionsDeployRole` per workload account for `ssm put-parameter + register-task-definition + pipes update-pipe`. No `update-service`.
- **SSM params** — `/heediq/transcription/{free,paid}-image-tag` must be seeded once per workload account before first `cdk deploy`. After that, CI owns the value.

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
- **heediq-worker-transcription**: Two Docker builds (free/paid) → ECR push (sha-tagged) via `GitHubActionsECRRole` in shared-services → per-env: `ssm put-parameter` + `ecs register-task-definition` + `aws pipes update-pipe` via `GitHubActionsDeployRole` in workload account. No `update-service` (RunTask architecture, D-066).
- **heediq-web**: Vite build → S3 sync + CloudFront invalidation on develop push.
- All repos: same branching — feature → PR → develop (auto-deploy dev) → main (staging → manual gate → prod).

## Standing notes (carry forward)
- `heediq-infra` ACM cert CNAME validation must be manually added to Route 53 for staging/prod when those accounts are bootstrapped (one-time per env, D-063).
- Staging/prod budgets (D-056) to be added once those accounts see traffic.
- Run `./scripts/setup.sh` for staging/prod accounts when their first app deploy workflows are wired.
