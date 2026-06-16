# Heediq — Architecture & Infrastructure

`DECISIONS.md` (D-001 through D-007, D-021–D-023) points here rather than duplicating this
detail.

## Stack
Full AWS serverless: Lambda, API Gateway, Fargate Spot (ECS), DynamoDB, S3, SQS, EventBridge,
Cognito, CloudFront, Route 53, Secrets Manager, CloudWatch.
- IaC: AWS CDK
- CI/CD: GitHub Actions
- Frontend: React (PWA)

## Environments
Five AWS accounts under one AWS Organization (D-036):
- **Management** — org root, IAM Identity Center (SSO), consolidated billing. No workloads.
- **Shared services** — ECR (all container images) and future cross-environment shared infrastructure.
- **Dev / Staging / Prod** — fully isolated workload accounts (DynamoDB, Lambda, S3, SQS, Cognito, etc.).

Human access via IAM Identity Center (SSO) — one login URL, permission sets defined centrally, users assume roles per account. No IAM users or long-lived access keys.

Machine access (GitHub Actions) via OIDC — a `GitHubActionsDeployRole` per account with branch-scoped trust; no stored AWS credentials in GitHub Secrets. Container images push to ECR in the shared-services account and are promoted by image tag across dev → staging → prod. Manual approval gate before production deploys.

Resource naming: `heediq-{entity}` with no environment prefix — the account boundary is the environment boundary (D-037). SSM paths: `/heediq/{service}/{param}` (D-038).

## Multi-tenancy
Single shared database, row-level tenant isolation via `org_id` on every tenant-scoped row (e.g.
recordings carry `org_id` + `owner_user_id`). Query pattern:
`WHERE org_id = :tenant AND (owner_user_id = :user OR :role = 'admin')`.

## Database
DynamoDB-only at launch (D-007). Design: **multi-table** — one table per service/entity domain, e.g. `heediq-recordings`, `heediq-orgs` (D-031). Aurora Serverless v2 (Postgres) deferred — open migration path per service if relational queries become necessary. At small scale, Aurora's ~$45/mo fixed floor dominates the bill disproportionately (see Cost baselines below).

## Upload & transcription processing flow
Client uploads audio directly to S3 via a presigned URL (avoids Lambda payload limits, standard
serverless pattern). An S3 event feeds the transcription queue (SQS). EventBridge Pipes triggers
an ECS Fargate Spot `RunTask` running faster-whisper — zero idle cost, nothing provisioned while
the queue is empty. Job status is written to a DynamoDB status table; the client polls for
completion (WebSocket/AppSync was considered but skipped in favor of "maximum serverless"
simplicity).

*(This flow superseded an earlier version that used AWS Transcribe with simpler S3-event →
Lambda → Transcribe-job orchestration — see Transcription engine below for why that was dropped.)*

## Transcription engine
Self-hosted **faster-whisper** on AWS Fargate Spot, queued via SQS. AWS Transcribe was dropped
entirely.
- **Free tier:** whisper `small` model, CPU, Fargate Spot (~3–4× realtime) — ≈ $0.02 / 60-min
  meeting, capped at 30–45 min per recording.
- **Paid tier:** whisper `large-v3` + pyannote diarization, chunked/parallel Fargate tasks for
  latency — ≈ $0.12 / 60-min meeting.

Why the pivot: at ~10 meetings/day, Fargate Spot + faster-whisper costs roughly $6/month vs.
roughly $432/month on AWS Transcribe at the same volume — about 70–75× cheaper. AWS Transcribe's
per-minute pricing (~$0.024/min, ~$1.08 for a 45-min session) made flat per-seat pricing without
usage caps or overage billing infeasible; the self-hosted pivot is what makes a usage-inclusive
pricing model viable at all.

## Cost optimizations
- **Silence trimming:** accepted — safe, typically 10–30% duration reduction, no meaningful
  accuracy cost.
- **2× audio speed-up:** rejected — degrades word-error-rate and diarization accuracy too much
  to be worth the savings.

## Cost baselines
Single environment (modeled before the dev/staging overhead below):

**1,000 users (900 free / 100 paid, 90/10 mix):**
- AWS-only, with Aurora Serverless v2: ≈ $120–195/mo
- AWS-only, DynamoDB-only: ≈ $75–145/mo
- Aurora's ~$45/mo floor is the single biggest lever to defer.
- Excludes third-party meeting-bot costs: ≈ $50–150/mo at this scale.

**100 users (90 free / 10 paid, 90/10 mix):**
- AWS-only, with Aurora Serverless v2: ≈ $70–95/mo
- AWS-only, DynamoDB-only: ≈ $25–40/mo
- At this scale Aurora's fixed floor dominates even harder (2–3× cost difference vs.
  DynamoDB-only) — a stronger case to defer it.
- Excludes third-party meeting-bot costs: ≈ $10–30/mo for 10 paid orgs.

Adding the dev + staging accounts (3 environments total, DynamoDB-only) adds modest fixed
overhead on top of the single-environment numbers above — roughly **$30–55/mo total** at the
100-user scale, and **$85–165/mo total** at the 1,000-user scale (dev/staging carry minimal real
traffic, so most of their added cost is fixed-service overhead, not usage).

Cost components covered: transcription compute, S3 + Glacier, DynamoDB, Lambda/API Gateway,
SQS/EventBridge, Fargate Spot, Cognito (free at this scale), CloudFront/Route 53, backups/PITR,
CloudWatch, Secrets Manager.

## Engineering process
- Git host: GitHub. PRs via `gh` CLI. CI: GitHub Actions — per-repo workflows, OIDC role assumption per account (D-043).
- No issue tracker (Jira) for now — may adopt later. Branch/commit naming: `<type>/<short-kebab-desc>`. `develop` is the integration branch (D-027).
- Two-track memory model (this repo): business memory (`memory/business/`) + codebase memory (`memory/codebase/`).
- Documentation lives in code-level `README.md` files next to the code — replaces Confluence.
- **Repos:** 7 polyrepos — workspace, shared, web, api, worker-transcription, worker-summarization, infra (D-035).
- **API:** REST + Hono on Lambda + `/api/v1/` prefix + `@heediq/shared` Zod schemas (D-033, D-034, D-042).
- **Frontend:** Vite + React + TypeScript strict + Tailwind + Radix UI + TanStack Query (D-028, D-029).
- **Test stack:** Vitest/RTL + DynamoDB Local/LocalStack + Playwright + k6 (D-030).
- **Dev tooling:** pnpm + Node 22 LTS across all Node repos (D-039).
