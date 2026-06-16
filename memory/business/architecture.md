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
Three separate AWS accounts (prod / staging / dev) under one AWS Organization. A single shared
ECR registry — build the container image once, promote the same image across dev → staging →
prod. CI/CD is branch-based with a manual approval gate before production deploys.

## Multi-tenancy
Single shared database, row-level tenant isolation via `org_id` on every tenant-scoped row (e.g.
recordings carry `org_id` + `owner_user_id`). Query pattern:
`WHERE org_id = :tenant AND (owner_user_id = :user OR :role = 'admin')`.

## Database
DynamoDB-only at launch. Aurora Serverless v2 (Postgres) deferred — revisit if/when relational
queries are genuinely needed beyond DynamoDB's strengths. At small scale, Aurora's ~$45/mo fixed
floor dominates the bill disproportionately (see Cost baselines below), making the deferral even
more clearly correct early on.

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
- Git host: GitHub. PRs via `gh` CLI. CI: GitHub Actions.
- No issue tracker (Jira) for now — may adopt later. Branch/commit naming:
  `<type>/<short-kebab-desc>`, no issue key required.
- Two-track memory model (this repo): business memory (`memory/business/`) + codebase memory
  (`memory/codebase/`).
- Documentation lives in code-level `README.md` files next to the code — replaces Confluence.
- Still open / proposed (not locked): `develop` integration-branch model vs. `main` + feature
  branches; UI base (Tailwind + Radix + shadcn/ui-style local kit); test stack (Vitest/RTL +
  DynamoDB Local/LocalStack + Playwright + k6).
